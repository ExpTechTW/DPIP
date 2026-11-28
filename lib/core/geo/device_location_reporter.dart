import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/location_service.dart'
    show GpsFix, isLocationRefusal;
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// Reports the device location to the backend when it **moves a threshold
/// distance** — not when the user switches the Home region — and keeps each
/// fix it means to report until the server has answered it with a 2xx.
///
/// Driven by a distance-filtered position stream (in production
/// `Geolocator.getPositionStream(distanceFilter: …)`); each emission is a
/// meaningful move, so it is reported through [onMoved] (the
/// `LocationApi.updateDeviceLocation` request). Consecutive identical fixes are
/// skipped, and a report failure is logged, never thrown.
///
/// **A fix to report is pending until a 2xx.** It is written to
/// [SettingKeys.pendingLocationReport] the moment it is chosen and survives a
/// restart. The stream is distance-filtered, so a fix that is let go is not
/// offered again until the device has moved another 250 m — and until then the
/// server keeps targeting alerts at the township the device has left. So:
///
/// - **A 2xx clears it**, and only then does [onReported] run, with the fix
///   that was sent — the hook that updates what `DeviceRegistration` and the
///   native report heartbeat keep about the last report.
/// - **A newer fix replaces it.** The server needs where the device is, not
///   where it was.
/// - **Uploads keep one a minute** ([minUploadInterval]), stamped in
///   [SettingKeys.deviceLocationUpdatedAtMs] by every attempt, answered or not,
///   so a 429 also starts a minute's cool-down. A fix that arrives inside the
///   window waits for its end instead of being skipped.
/// - **A 429, a 5xx, a timeout or no network keeps it**, and it is tried again
///   [throttledRetry] after a 429 — just past the cool-down — or [failedRetry]
///   after anything else, doubling with each failure in a row up to
///   [maxRetry]. A launch ([start]) or a return to the foreground
///   ([retryPending], through `DeviceRegistration`) tries it sooner.
/// - **Any other 4xx drops it.** That is the server refusing the request
///   itself, and it would refuse it again however often it was sent; the next
///   move or registration sends a new one, as before pending reports existed.
/// - **Without a push token it waits**: nothing can be sent until one arrives,
///   and a new token triggers [retryPending].
/// - **A background report after it was taken drops it.** The native reporter
///   has given the server a newer position since, and sending this one would
///   move the alerts back to where the device was.
/// - **While a township is pinned by hand it is the township's point**
///   ([pinned]), whatever fix it was chosen from — a GPS fix left pending from
///   before the pin, or one a restart finds, included. A pinned device is
///   reported there and nowhere else.
///
/// [reportWhenAllowed] is the same pending report for a change of placement —
/// a township pinned by hand, or back to the GPS — which has to reach the
/// server even when a report went out a moment ago.
///
/// Requests go out one at a time, each re-checking the window after the one
/// before it, so a registration and a move that arrive together cost one
/// request rather than a request and a 429.
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
    required this._settings,
    this._onReported,
    this._nativeLastSuccess,
    this._pinned,
    this.minUploadInterval = const Duration(seconds: 60),
    this.throttledRetry = const Duration(seconds: 61),
    this.failedRetry = const Duration(minutes: 5),
    this.maxRetry = const Duration(minutes: 30),
    DateTime Function()? calibratedNow,
    DateTime Function()? now,
  }) : _calibratedNow = calibratedNow ?? (() => AppTime.utc),
       // wall-clock: the throttle stamp is written and compared by this class
       // alone, so it only has to agree with itself; a stamp a clock change
       // left in the future is handled in [_attempt].
       _now = now ?? DateTime.now;

  final Stream<GpsFix> Function() _positions;

  /// Sends one report: false when there is no push token to send it with,
  /// throws when the request fails.
  final Future<bool> Function(GpsFix fix) _onMoved;
  final SettingsStore _settings;
  final DateTime Function() _now;

  /// Stamps a pending fix, so it can be weighed against the native reporter's
  /// last success.
  final DateTime Function() _calibratedNow;

  /// Called after every report the server answered with a 2xx, with the fix
  /// it sent.
  final Future<void> Function(GpsFix fix)? _onReported;

  /// When the native background reporter last had a 2xx of its own, in device
  /// time. Only its own: a foreground or heartbeat report recorded natively
  /// did not put a newer position on the server than the fix pending here.
  final Future<DateTime?> Function()? _nativeLastSuccess;

  /// The pinned township's point while the location is set by hand, else
  /// null.
  final Future<GpsFix?> Function()? _pinned;

  /// Minimum gap between `/v2/location` requests.
  final Duration minUploadInterval;

  /// The wait after a 429 before the pending fix is tried again.
  final Duration throttledRetry;

  /// The wait after any other failure worth retrying.
  final Duration failedRetry;

  /// The longest the doubling may stretch either wait to.
  final Duration maxRetry;

  /// The attempt before this one; the next waits for it.
  Future<void> _queue = Future<void>.value();

  /// The next attempt at the pending fix, when one is scheduled.
  Timer? _retry;

  /// Failures in a row, for the doubling.
  int _failures = 0;

  /// What happened to the last fix that stopped being pending — the answer for
  /// a caller whose fix an earlier attempt already settled.
  ReportOutcome _settled = ReportOutcome.sent;

  /// The last fix the server answered with a 2xx.
  GpsFix? _lastSent;

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

  /// Begins reporting on each distance-triggered position (idempotent), and
  /// sends a fix a previous run left pending.
  void start() {
    _running = true;
    _subscribe();
    if (_readPending() != null) unawaited(_enqueue('launch'));
  }

  void _subscribe() {
    if (_sub != null) return;
    _sub = _positions().listen(
      _handle,
      // A services-off toggle, or a permission revoked while the stream is
      // open, errors it. That is the user changing a setting. Keeping the
      // error here means it never rides up as an uncaught async error, and
      // dropping the subscription lets [restart] re-create it when services
      // return. A refusal is not a fault, so it stays out of crash reports.
      onError: (Object error, StackTrace stackTrace) {
        if (isLocationRefusal(error)) {
          Log.warning('location stream stopped: location is off or denied');
        } else {
          Log.handle(error, stackTrace, 'location stream');
        }
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
    // when the server report fails or waits for a push token / the window.
    if (!_fixes.isClosed) _fixes.add(fix);
    await _report(fix, 'moved');
  }

  /// Makes [fix] the pending report and tries it now, subject to the same
  /// window as a move — for a caller with no move to report,
  /// `DeviceRegistration`, re-registering a push token. Never throws.
  Future<ReportOutcome> reportNow(GpsFix fix) => _report(fix, 'registration');

  /// Makes [fix] the pending report for a change of where the device is
  /// placed that is not a move — the user pinning a township by hand, or
  /// returning to GPS. Never throws.
  ///
  /// It has to reach the server even when a report went out a moment ago (or
  /// the server keeps alerting for the old place), and it must not be a second
  /// request inside the window either: like any pending fix it waits for the
  /// window's end, and a later placement or move replaces it while it waits.
  ///
  /// A fix the server already has from this reporter — the position stream
  /// reports a newly pinned township itself when the window is open — is not
  /// sent again.
  Future<ReportOutcome> reportWhenAllowed(GpsFix fix) async {
    if (fix == _lastSent && _readPending() == null) return ReportOutcome.sent;
    return _report(fix, 'placement');
  }

  /// Tries the pending fix now, if there is one; null when there is none.
  /// Never throws.
  Future<ReportOutcome?> retryPending() async {
    if (_readPending() == null) return null;
    return _enqueue('retry');
  }

  Future<ReportOutcome> _report(GpsFix fix, String reason) async {
    await _writePending(await _pinnedFix() ?? fix);
    return _enqueue(reason);
  }

  Future<_Pending> _writePending(GpsFix fix) async {
    final takenAtMs = _calibratedNow().toUtc().millisecondsSinceEpoch;
    await _settings.setString(
      SettingKeys.pendingLocationReport,
      jsonEncode({'lat': fix.lat, 'lng': fix.lng, 'takenAt': takenAtMs}),
    );
    return (fix: fix, takenAtMs: takenAtMs);
  }

  /// The pinned township's point, or null when the location comes from the
  /// device.
  Future<GpsFix?> _pinnedFix() async {
    try {
      return await _pinned?.call();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location report: pinned township');
      return null;
    }
  }

  /// Queues one attempt at whatever is pending when its turn comes. Attempts
  /// never overlap, so the pending fix is never sent twice at once.
  Future<ReportOutcome> _enqueue(String reason) {
    final attempt = _queue.then((_) => _attempt(reason));
    _queue = attempt.then((_) {});
    return attempt;
  }

  Future<ReportOutcome> _attempt(String reason) async {
    _retry?.cancel();
    _retry = null;
    var pending = _readPending();
    if (pending == null) return _settled;

    // Chosen before the township was pinned, or left by a run before it: a
    // pinned device is reported at the township and nowhere else.
    final pinned = await _pinnedFix();
    if (pinned != null && pinned != pending.fix) {
      pending = await _writePending(pinned);
      Log.info(
        'location report: the location is set by hand — the pending fix is '
        'now the township\'s point ($reason)',
      );
    }

    if (await _overtaken(pending)) {
      await _clear(pending);
      Log.info(
        'location report: the background reporter has sent a newer position '
        'since the pending one was taken — dropped it ($reason)',
      );
      return _settled = ReportOutcome.superseded;
    }

    final nowMs = _now().toUtc().millisecondsSinceEpoch;
    final lastMs = _settings.getInt(SettingKeys.deviceLocationUpdatedAtMs);
    // `since >= 0` is not redundant: the stored stamp survives a clock change,
    // so a device set back (or a first SNTP sync that pulls the clock back)
    // leaves a stamp in the future. The window would then hold for the whole
    // offset — hours of a moving user reporting nothing — and never expire on
    // its own, because the comparison only gets more negative as real time
    // passes. A future stamp means the window is not measurable, so it does
    // not apply.
    final since = lastMs == null ? null : nowMs - lastMs;
    final window = minUploadInterval.inMilliseconds;
    if (since != null && since >= 0 && since < window) {
      _schedule(Duration(milliseconds: window - since));
      return ReportOutcome.throttled; // silent: the timer sends it
    }

    try {
      if (!await _onMoved(pending.fix)) return ReportOutcome.noToken;
    } catch (error, stackTrace) {
      // Cool down after every failure, a 429 included, so a retry never lands
      // inside the window the server is still counting.
      await _settings.setInt(SettingKeys.deviceLocationUpdatedAtMs, nowMs);
      Log.handle(error, stackTrace, 'updateDeviceLocation');
      if (_isFinal(error)) {
        _failures = 0;
        await _clear(pending);
        Log.warning(
          'location report: refused with HTTP ${_status(error)} — dropped, '
          'the next move or registration sends a new one ($reason)',
        );
        return _settled = ReportOutcome.rejected;
      }
      _failures++;
      final wait = _backoff(error);
      Log.info(
        'location report: failed ($reason) — kept pending, retrying in '
        '${wait.inSeconds}s',
      );
      _schedule(wait);
      return ReportOutcome.failed;
    }
    await _settings.setInt(SettingKeys.deviceLocationUpdatedAtMs, nowMs);
    _failures = 0;
    _lastSent = pending.fix;
    await _clear(pending, sent: true);
    if (reason == 'launch' || reason == 'retry') {
      Log.info('location report: sent the pending fix ($reason)');
    }
    try {
      await _onReported?.call(pending.fix);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'updateDeviceLocation: onReported');
    }
    return _settled = ReportOutcome.sent;
  }

  /// [throttledRetry] or [failedRetry], doubled for each failure in a row
  /// before this one, never past [maxRetry].
  Duration _backoff(Object error) {
    final base = _status(error) == 429 ? throttledRetry : failedRetry;
    final wait = base * math.pow(2, math.min(_failures - 1, 16)).toInt();
    return wait > maxRetry ? maxRetry : wait;
  }

  void _schedule(Duration wait) {
    _retry?.cancel();
    _retry = Timer(wait, () {
      _retry = null;
      unawaited(_enqueue('retry'));
    });
  }

  /// Whether the native reporter has had a 2xx since [pending] was taken.
  ///
  /// Not asked for a fix taken inside the last [minUploadInterval]: it is a
  /// platform round trip, and a move a minute old is fresher than anything the
  /// background path can have sent since.
  Future<bool> _overtaken(_Pending pending) async {
    final read = _nativeLastSuccess;
    if (read == null) return false;
    final age =
        _calibratedNow().toUtc().millisecondsSinceEpoch - pending.takenAtMs;
    if (age >= 0 && age < minUploadInterval.inMilliseconds) return false;
    try {
      final at = await read();
      // The native side stamps with the device clock.
      return at != null &&
          AppTime.fromDevice(at).millisecondsSinceEpoch > pending.takenAtMs;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location report: native last success');
      return false;
    }
  }

  _Pending? _readPending() {
    final raw = _settings.getString(SettingKeys.pendingLocationReport);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        fix: (
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lng'] as num).toDouble(),
        ),
        takenAtMs: (json['takenAt'] as num).toInt(),
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location report: unreadable pending fix');
      unawaited(_settings.remove(SettingKeys.pendingLocationReport));
      return null;
    }
  }

  /// Removes [settled] — unless a newer fix has replaced it meanwhile, which
  /// stays pending for the attempt already queued behind this one.
  ///
  /// After a 2xx ([sent]) a newer one of the very same fix goes too: it was
  /// written while the request was out — a placement or a registration naming
  /// the place a move had just sent — and the server has that place now.
  Future<void> _clear(_Pending settled, {bool sent = false}) async {
    final current = _readPending();
    if (current == null) return;
    if (current != settled && !(sent && current.fix == settled.fix)) return;
    await _settings.remove(SettingKeys.pendingLocationReport);
  }

  static int? _status(Object error) =>
      error is DioException ? error.response?.statusCode : null;

  /// A client error the same request would meet again. 408 and 429 are the
  /// two that mean "not now" instead.
  static bool _isFinal(Object error) {
    final status = _status(error);
    return status != null &&
        status >= 400 &&
        status < 500 &&
        status != 408 &&
        status != 429;
  }

  /// Stops reporting, a scheduled retry included; safe to [start] again.
  void stop() {
    _running = false;
    _sub?.cancel();
    _sub = null;
    _retry?.cancel();
    _retry = null;
  }

  void dispose() {
    stop();
    _fixes.close();
  }
}

typedef _Pending = ({GpsFix fix, int takenAtMs});

/// What happened to one report.
enum ReportOutcome {
  /// The server answered with a 2xx — this attempt, or an earlier one that
  /// sent the same fix.
  sent,

  /// Inside the one-a-minute window: kept pending and sent when it ends.
  throttled,

  /// No push token yet: kept pending, not attempted.
  noToken,

  /// Refused for good — a 4xx other than 408 or 429 — and dropped.
  rejected,

  /// No answer, a 5xx, a 408 or a 429: kept pending and retried later.
  failed,

  /// Dropped unsent: the native background reporter has reported a newer
  /// position since this one was taken.
  superseded,
}
