import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// Reports the device location to the backend when it **moves a threshold
/// distance** — not when the user switches the Home region.
///
/// Driven by a distance-filtered position stream (in production
/// `Geolocator.getPositionStream(distanceFilter: …)`); each emission is a
/// meaningful move, so it just forwards to [onMoved] (the
/// `LocationApi.updateDeviceLocation` POST). Consecutive identical fixes are
/// skipped, and a report failure is logged, never thrown.
///
/// Uploads are throttled to one per [minUploadInterval] (60 s by default),
/// keyed by [SettingKeys.deviceLocationUpdatedAtMs]. Inside the window the fix
/// is still published on [fixes] and the API is skipped silently; outside it,
/// every move is reported. The stamp is written only when an upload was
/// attempted (or threw), so a missing push token (`onMoved` → `false`) does not
/// burn the window.
///
/// The positions come from a **factory** (`Stream<GpsFix> Function()`), not a
/// single stream instance, because geolocator's position stream *errors and
/// finishes* when location services are turned off mid-session and does not
/// resume when they return. On a stream error/done the subscription is dropped
/// so [restart] (driven by `LocationMonitor` when services come back) can create
/// a fresh one — otherwise foreground reporting would stay dead until relaunch.
///
/// Foreground only; the app-closed case is the native background-location task.
///
/// [reportNow] sends one fix through the same gates for a caller with no move
/// to report — `DeviceRegistration`, re-registering a push token. Requests go
/// out one at a time, each re-checking the throttle after the one before it,
/// so a registration and a move that arrive together cost one request rather
/// than a request and a 429.
class DeviceLocationReporter {
  DeviceLocationReporter({
    required this._positions,
    required this._onMoved,
    required this._settings,
    this._onReported,
    this.minUploadInterval = const Duration(seconds: 60),
    DateTime Function()? now,
    // wall-clock: the throttle stamp is written and compared by this class
    // alone, so it only has to agree with itself; a stamp a clock change left
    // in the future is handled in [_handle].
  }) : _now = now ?? DateTime.now;

  final Stream<GpsFix> Function() _positions;
  final Future<bool> Function(GpsFix fix) _onMoved;
  final SettingsStore _settings;
  final DateTime Function() _now;

  /// Called after every report the server answered with a 2xx.
  final Future<void> Function()? _onReported;

  /// The request before this one; the next waits for it.
  Future<void> _queue = Future<void>.value();

  /// Minimum gap between `/v2/location` POSTs.
  final Duration minUploadInterval;

  StreamSubscription<GpsFix>? _sub;
  GpsFix? _last;
  bool _running = false;

  final StreamController<GpsFix> _fixes = StreamController<GpsFix>.broadcast();

  /// Every fix this pipeline accepts, for the other foreground consumer of the
  /// device's position: keeping the current township ([LocationMonitor]) in step
  /// with where the user actually is.
  ///
  /// Shared rather than opened twice because each `getPositionStream` call starts
  /// its own native location session — two subscriptions would mean two GPS
  /// consumers draining the battery to compute the same fix.
  Stream<GpsFix> get fixes => _fixes.stream;

  /// Begins reporting on each distance-triggered position (idempotent).
  void start() {
    _running = true;
    _subscribe();
  }

  void _subscribe() {
    if (_sub != null) return;
    _sub = _positions().listen(
      _handle,
      // A services-off toggle errors the stream; keeping the error here means it
      // never rides up as an uncaught async error, and dropping the subscription
      // lets [restart] re-create it when services return.
      onError: (Object error, StackTrace stackTrace) {
        Log.handle(error, stackTrace, 'location stream');
        _sub = null;
      },
      onDone: () => _sub = null,
      cancelOnError: true,
    );
  }

  /// Re-subscribes with a fresh stream if running (e.g. after location services
  /// were toggled off then on). A no-op when stopped.
  void restart() {
    if (!_running) return;
    _sub?.cancel();
    _sub = null;
    _subscribe();
  }

  Future<void> _handle(GpsFix fix) async {
    if (fix == _last) return; // records compare by value
    _last = fix;
    // Publish before the upload: the current township must track the move even
    // when the server report fails or is skipped for a missing push token /
    // throttle window.
    if (!_fixes.isClosed) _fixes.add(fix);
    await _send(fix);
  }

  /// Reports [fix] now, subject to the same throttle as a move. Never throws.
  Future<ReportOutcome> reportNow(GpsFix fix) => _send(fix);

  Future<ReportOutcome> _send(GpsFix fix) {
    final attempt = _queue.then((_) => _attempt(fix));
    _queue = attempt.then((_) {});
    return attempt;
  }

  Future<ReportOutcome> _attempt(GpsFix fix) async {
    final nowMs = _now().toUtc().millisecondsSinceEpoch;
    final lastMs = _settings.getInt(SettingKeys.deviceLocationUpdatedAtMs);
    // `nowMs - lastMs >= 0` is not redundant: the stored stamp survives a
    // clock change, so a device set back (or a first SNTP sync that pulls the
    // clock back) leaves a stamp in the future. The throttle would then hold
    // for the whole offset — hours of a moving user reporting nothing — and
    // it would never expire on its own, because the comparison only gets more
    // negative as real time passes. A future stamp means the window is not
    // measurable, so it does not apply.
    final since = lastMs == null ? null : nowMs - lastMs;
    if (since != null &&
        since >= 0 &&
        since < minUploadInterval.inMilliseconds) {
      return ReportOutcome.throttled; // silent — no API, no log
    }

    try {
      final attempted = await _onMoved(fix);
      if (!attempted) return ReportOutcome.noToken;
      await _settings.setInt(SettingKeys.deviceLocationUpdatedAtMs, nowMs);
    } catch (error, stackTrace) {
      // Cool down after hard failures (incl. HTTP 429) so we don't retry-storm.
      await _settings.setInt(SettingKeys.deviceLocationUpdatedAtMs, nowMs);
      Log.handle(error, stackTrace, 'updateDeviceLocation');
      return _isFinal(error) ? ReportOutcome.rejected : ReportOutcome.failed;
    }
    try {
      await _onReported?.call();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'updateDeviceLocation: onReported');
    }
    return ReportOutcome.sent;
  }

  /// A client error the same request would meet again. 408 and 429 are the
  /// two that mean "not now" instead.
  static bool _isFinal(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    return status != null &&
        status >= 400 &&
        status < 500 &&
        status != 408 &&
        status != 429;
  }

  /// Stops reporting; safe to [start] again.
  void stop() {
    _running = false;
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _fixes.close();
  }
}

/// What happened to one report.
enum ReportOutcome {
  /// The server answered with a 2xx.
  sent,

  /// Inside the one-a-minute window — not attempted.
  throttled,

  /// No push token yet — not attempted.
  noToken,

  /// Refused for good: a 4xx other than 408 or 429.
  rejected,

  /// No answer, a 5xx, a 408 or a 429 — worth trying again later.
  failed,
}
