/// Keeps the server's record of this device — push token and township —
/// current when nothing moves.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/notify_request_lane.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';

/// Reports the device once when its push token changes, and once a day when
/// nothing else has.
///
/// The backend learns a push token **only** from `/v2/location` — there is no
/// other registration call — and every path that sends one is triggered by
/// movement: the foreground position stream, and the native background
/// reporters behind a 150 m (iOS) or geofence (Android) gate. A device that
/// sits still therefore never tells the server about a new token, and keeps
/// receiving nothing: the alert goes to the token it had before. iOS made it
/// worse, because re-arming the background reporter with a new token takes a
/// fix that the distance gate then discards as "no move".
///
/// So this is the one place that asks "does the server have this token, and
/// recently?" — on launch, on every return to the foreground and whenever the
/// stored token changes — and sends one report when the answer is no. It
/// reports through [DeviceLocationReporter.reportNow], so it shares the
/// reporter's one-request-a-minute throttle and never lands beside a move
/// report; the backend answers two requests inside its window with a 429.
///
/// A location report the server never answered is the same question with a
/// known answer, so it goes first: the reporter's pending fix is sent before
/// anything is checked, and its 2xx counts like any other. A report that fails
/// stays pending in the reporter, which retries it until the server answers —
/// this class keeps no retry of its own, so nothing is sent twice.
///
/// Each check holds the notify lane's deferred requests
/// ([NotifyRequestLane.holdDeferred]) for as long as it runs: it can spend
/// seconds on a fix before it has a request to queue, and the Live Activity
/// report — which the backend refuses until this registration has landed —
/// must not take the lane meanwhile.
///
/// What it remembers lives in settings: a **hash** of the last token a 2xx
/// answered for (the token itself is already stored once, and need not be
/// twice), and when that was. Every successful report from the foreground
/// counts — [recordSuccess] is the reporter's success hook — and so does the
/// native background path's, read from its diagnostics, so a device that is
/// reporting on its own is not asked to report again.
class DeviceRegistration {
  DeviceRegistration({
    required this._settings,
    required this._token,
    required this._fix,
    required this._report,
    required this._resend,
    required this._lane,
    this._nativeLastSuccess,
    DateTime Function()? now,
    this.maxAge = const Duration(hours: 24),
  }) : _now = now ?? (() => AppTime.utc);

  final SettingsStore _settings;
  final String? Function() _token;

  /// A position good enough to name the township, or null.
  final Future<GpsFix?> Function() _fix;
  final Future<ReportOutcome> Function(GpsFix fix) _report;

  /// Sends the reporter's pending fix, if there is one; null when there is
  /// none.
  final Future<ReportOutcome?> Function() _resend;

  final NotifyRequestLane _lane;

  /// When the native background reporter last had a 2xx, in device time.
  final Future<DateTime?> Function()? _nativeLastSuccess;
  final DateTime Function() _now;

  /// How long a report may stand before the device is reported again anyway.
  final Duration maxAge;

  Future<void>? _running;

  /// Records a 2xx for the token stored now. Called for every successful
  /// report, from any path in this isolate.
  Future<void> recordSuccess() async {
    final token = _token();
    if (token == null) return;
    await _settings.setString(SettingKeys.registeredTokenHash, _hash(token));
    await _settings.setInt(
      SettingKeys.deviceReportedAtMs,
      _now().toUtc().millisecondsSinceEpoch,
    );
  }

  /// Whether a 2xx has answered for the push token stored now — whether the
  /// backend knows this device. False without a token.
  bool get registered {
    final token = _token();
    return token != null &&
        _settings.getString(SettingKeys.registeredTokenHash) == _hash(token);
  }

  /// Reports once if the server's record may be out of date. [reason] is for
  /// the log. Concurrent calls share one check; never throws.
  ///
  /// Deferred requests in the notify lane wait from this call until the check
  /// is done — taken synchronously, so a Live Activity report triggered right
  /// after it queues behind whatever it sends.
  Future<void> ensure(String reason) =>
      _running ??= _lane.holdDeferred(() => _ensure(reason)).whenComplete(() {
        _running = null;
      });

  Future<void> _ensure(String reason) async {
    try {
      final token = _token();
      if (token == null) return;
      switch (await _resend()) {
        case null ||
            ReportOutcome.sent ||
            ReportOutcome.superseded ||
            ReportOutcome.rejected:
          // Nothing pending any more: a 2xx has recorded itself, and the check
          // below decides the rest.
          break;
        case ReportOutcome.throttled ||
            ReportOutcome.failed ||
            ReportOutcome.noToken:
          // Its 2xx, whenever it comes, registers this token as well; a
          // second report now would only be refused inside the same window.
          Log.info(
            'device registration ($reason): a location report is still '
            'pending — the reporter retries it',
          );
          return;
      }
      final due = await _due(token);
      if (due == null) return;
      final fix = await _fix();
      if (fix == null) {
        Log.info('device registration: $due ($reason) — no position, skipped');
        return;
      }
      final outcome = await _report(fix);
      switch (outcome) {
        case ReportOutcome.sent || ReportOutcome.superseded:
          Log.info('device registration: $due ($reason) — reported');
        case ReportOutcome.noToken:
          return;
        case ReportOutcome.rejected:
          // Final for this token: the same request would be refused again.
          // A new token, or the next launch, is the next attempt.
          Log.warning('device registration: $due ($reason) — rejected');
        case ReportOutcome.throttled || ReportOutcome.failed:
          Log.info(
            'device registration: $due ($reason) — ${outcome.name}, '
            'kept pending for the reporter to retry',
          );
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'device registration');
    }
  }

  /// Why a report is due, or null when the server's record is current.
  Future<String?> _due(String token) async {
    final stored = _settings.getString(SettingKeys.registeredTokenHash);
    if (stored == null) return 'push token not yet registered';
    if (stored != _hash(token)) return 'push token changed';

    final now = _now().toUtc();
    var last = _stamp(_settings.getInt(SettingKeys.deviceReportedAtMs));
    if (last == null || _stale(last, now)) {
      // Only asked when this isolate's own record is stale: it is a platform
      // round trip, and on most launches the answer is already known.
      final native = await _nativeSuccess();
      if (native != null && (last == null || native.isAfter(last))) {
        last = native;
      }
    }
    if (last == null) return 'never reported';
    if (!_stale(last, now)) return null;
    final age = now.difference(last);
    // A stamp from the future is a clock that moved, not a recent report.
    // Reporting is the side to err on: one request, after which the stamp is
    // sane again.
    return age.isNegative
        ? 'last report stamped in the future'
        : 'last report ${age.inHours} h ago';
  }

  bool _stale(DateTime last, DateTime now) {
    final age = now.difference(last);
    return age.isNegative || age > maxAge;
  }

  Future<DateTime?> _nativeSuccess() async {
    final read = _nativeLastSuccess;
    if (read == null) return null;
    try {
      final at = await read();
      // The native side stamps with the device clock.
      return at == null ? null : AppTime.fromDevice(at);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'device registration: native last success');
      return null;
    }
  }

  static DateTime? _stamp(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  static String _hash(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}
