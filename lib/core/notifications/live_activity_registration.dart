/// Reports the Live Activity push-to-start token to the notify backend.
///
/// The backend keeps it, with the system's Live Activities switch, for this
/// device's township; nothing starts a Live Activity from it yet. What it needs
/// is the current pairing of this device's push token, its push-to-start token
/// and that switch, so this sends the triple whenever any part of it changes,
/// and again after [LiveActivityRegistration.maxAge] so the backend can tell a
/// device that still reports from one that is gone.
///
/// Triggers: every state the platform reports after
/// [LiveActivityRegistration.start], plus whatever the services host passes to
/// [LiveActivityRegistration.ensure] (launch, resume, a changed push token, a
/// device-location report the backend accepted). An unchanged triple inside
/// `maxAge` costs nothing — no request is made.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/live_activity_tokens.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// Sends one report; throws a [DioException] on a non-2xx answer.
typedef LiveActivityReport = Future<void> Function(
  String token,
  String pushToStartToken,
  bool enabled,
);

/// Keeps the backend's copy of the triple current.
///
/// **Pending** is the persisted state, not a flag: the triple differs from the
/// last one a 2xx answered for ([SettingKeys.liveActivityReportedHash]), or
/// that answer is older than [maxAge] ([SettingKeys.liveActivityReportedAtMs]).
/// Only a 2xx writes them, so only a 2xx clears it, and a failure leaves it
/// pending for the next trigger — and for a retry after [failedRetry],
/// doubling with each failure in a row up to [maxRetry]. A 4xx other than
/// 401, 408 and 429 is written as answered too: the backend asks for the same
/// triple not to be sent again, and a change of any part sends it anyway.
///
/// **Not before the device is registered.** The backend answers 401 for a push
/// token no location report has registered, so nothing is sent until
/// [registered] says one has — and the report that registers it triggers
/// [ensure] again.
///
/// **Behind the location report.** The request is
/// `NotifyRequestPriority.deferred` in the notify lane: it goes after any
/// location report or registration waiting there, and after any registration
/// check still preparing one. The backend limits both per address together,
/// and the location report is the one that decides where alerts go.
///
/// **One pass at a time.** Every trigger, the retry timer included, goes
/// through [ensure], which runs a single pass and folds whatever arrives during
/// it into one more — so a request is never sent twice for the same state.
class LiveActivityRegistration {
  LiveActivityRegistration({
    required this._settings,
    required this._token,
    required this._registered,
    required this._states,
    required this._report,
    DateTime Function()? now,
    this.maxAge = const Duration(hours: 6),
    this.failedRetry = const Duration(minutes: 5),
    this.maxRetry = const Duration(hours: 1),
  }) : _now = now ?? (() => AppTime.utc);

  final SettingsStore _settings;

  /// This device's push token — the one device-location reports carry.
  final String? Function() _token;

  /// Whether a location report has registered that push token.
  final bool Function() _registered;
  final Stream<LiveActivityState> _states;
  final LiveActivityReport _report;
  final DateTime Function() _now;

  /// How long an unchanged report stays good. Matches the backend, which
  /// refreshes an unchanged row at most this often.
  final Duration maxAge;

  /// The wait before retrying after a failure worth retrying (no answer, 5xx,
  /// 408, 429) — the backend's own advice for a 429.
  final Duration failedRetry;

  /// The longest the doubling may stretch [failedRetry] to.
  final Duration maxRetry;

  StreamSubscription<LiveActivityState>? _subscription;
  LiveActivityState? _state;
  Future<void>? _running;
  String? _again;
  Timer? _retry;
  int _failures = 0;

  /// Starts listening to the platform. Reports are made only after this — the
  /// services host calls it once onboarding is complete.
  void start() {
    _subscription ??= _states.listen((state) {
      _state = state;
      unawaited(ensure('live activity state'));
    });
  }

  /// Reports now if the current triple is pending.
  ///
  /// Calls that arrive while one is running are folded into one more pass
  /// after it, so a state that changes mid-request is never left unreported
  /// and never reported twice.
  Future<void> ensure(String reason) {
    final running = _running;
    if (running != null) {
      _again = reason;
      return running;
    }
    return _running = _drain(reason).whenComplete(() => _running = null);
  }

  Future<void> _drain(String reason) async {
    String? next = reason;
    while (next != null) {
      _again = null;
      await _ensure(next);
      next = _again;
    }
  }

  Future<void> _ensure(String reason) async {
    try {
      if (_subscription == null) return;
      // This pass decides afresh; a retry scheduled before it is superseded.
      _retry?.cancel();
      _retry = null;
      final state = _state;
      final pushToStart = state?.token;
      final token = _token();
      if (state == null || pushToStart == null || token == null) return;

      final fingerprint = _hash('$token\n$pushToStart\n${state.enabled}');
      final now = _now().toUtc();
      if (_fresh(fingerprint, now)) return;
      if (!_registered()) {
        Log.info('live activity: waiting for the device to register ($reason)');
        return;
      }

      try {
        await _report(token, pushToStart, state.enabled);
        await _remember(fingerprint, now);
        _failures = 0;
        Log.info('live activity: reported ($reason)');
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401) {
          // Registered here, unknown there: the next report the backend
          // accepts triggers another pass.
          _failures = 0;
          Log.info('live activity: backend has no record of the device yet');
          return;
        }
        if (status != null &&
            status >= 400 &&
            status < 500 &&
            status != 408 &&
            status != 429) {
          // The same request would be refused again; remembered so it is not
          // re-sent on every resume. A change of any part sends it again.
          _failures = 0;
          await _remember(fingerprint, now);
          Log.warning('live activity: rejected with $status ($reason)');
          return;
        }
        _failures++;
        final wait = _backoff();
        Log.info(
          'live activity: failed ($reason), still pending — retrying in '
          '${wait.inSeconds}s',
        );
        _retry = Timer(wait, () {
          _retry = null;
          unawaited(ensure('retry'));
        });
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'live activity registration');
    }
  }

  Duration _backoff() {
    final wait = failedRetry * math.pow(2, math.min(_failures - 1, 16)).toInt();
    return wait > maxRetry ? maxRetry : wait;
  }

  bool _fresh(String fingerprint, DateTime now) {
    if (_settings.getString(SettingKeys.liveActivityReportedHash) !=
        fingerprint) {
      return false;
    }
    final at = _settings.getInt(SettingKeys.liveActivityReportedAtMs);
    if (at == null) return false;
    final age = now.difference(
      DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
    );
    // A stamp from the future is a clock that moved, not a recent report.
    return !age.isNegative && age < maxAge;
  }

  Future<void> _remember(String fingerprint, DateTime now) async {
    await _settings.setString(
      SettingKeys.liveActivityReportedHash,
      fingerprint,
    );
    await _settings.setInt(
      SettingKeys.liveActivityReportedAtMs,
      now.millisecondsSinceEpoch,
    );
  }

  /// Neither token is stored, only a hash of the reported triple.
  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  void dispose() {
    _retry?.cancel();
    _retry = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
