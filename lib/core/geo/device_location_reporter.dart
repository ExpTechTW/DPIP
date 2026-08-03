import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';

/// Reports the device location to the backend when it **moves a threshold
/// distance** — not when the user switches the Home region.
///
/// Driven by a distance-filtered position stream (in production
/// `Geolocator.getPositionStream(distanceFilter: …)`); each emission is a
/// meaningful move, so it just forwards to [onMoved] (the
/// `LocationApi.updateDeviceLocation` POST). Consecutive identical fixes are
/// skipped, and a report failure is logged, never thrown.
///
/// Uploads are **client-throttled to once per [minUploadInterval]** (default
/// 60s), keyed by [PreferenceKeys.deviceLocationUpdatedAtMs]. A move inside the
/// window still updates the local township via [fixes], but skips the API
/// silently (no log) — avoids hammering `/v2/location` into HTTP 429.
///
/// [onMoved] returns `true` when an upload was attempted (token present); the
/// throttle stamp is written only then (or when the attempt throws), so a
/// missing push token does not burn the 60s window.
///
/// The positions come from a **factory** (`Stream<GpsFix> Function()`), not a
/// single stream instance, because geolocator's position stream *errors and
/// finishes* when location services are turned off mid-session and does not
/// resume when they return. On a stream error/done the subscription is dropped
/// so [restart] (driven by `LocationMonitor` when services come back) can create
/// a fresh one — otherwise foreground reporting would stay dead until relaunch.
///
/// Foreground only; the app-closed case is the native background-location task.
class DeviceLocationReporter {
  DeviceLocationReporter({
    required this._positions,
    required this._onMoved,
    required this._prefs,
    this.minUploadInterval = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Stream<GpsFix> Function() _positions;
  final Future<bool> Function(GpsFix fix) _onMoved;
  final Prefs _prefs;
  final DateTime Function() _now;

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

    final nowMs = _now().toUtc().millisecondsSinceEpoch;
    final lastMs = _prefs.getInt(PreferenceKeys.deviceLocationUpdatedAtMs);
    if (lastMs != null && nowMs - lastMs < minUploadInterval.inMilliseconds) {
      return; // silent — no API, no log
    }

    try {
      final attempted = await _onMoved(fix);
      if (attempted) {
        await _prefs.setInt(PreferenceKeys.deviceLocationUpdatedAtMs, nowMs);
      }
    } catch (error, stackTrace) {
      // Cool down after hard failures (incl. HTTP 429) so we don't retry-storm.
      await _prefs.setInt(PreferenceKeys.deviceLocationUpdatedAtMs, nowMs);
      Log.handle(error, stackTrace, 'updateDeviceLocation');
    }
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
