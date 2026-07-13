import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:flutter_ntp/flutter_ntp.dart';

/// [ServerTimeSource] backed by real **SNTP** (`flutter_ntp`), querying
/// [primaryHost] first and falling back to [backupHost].
///
/// Each query is one UDP round trip whose RFC 5905 offset formula already
/// corrects for network delay, so this applies the just-measured offset to the
/// device clock and returns the corrected instant in ms-since-epoch (UTC). Time
/// sync is app infrastructure feeding [ServerClock] (which then anchors this to a
/// monotonic clock), so it lives in core alongside the realtime spine.
///
/// The [query] seam lets tests drive the primary→backup fallback without a
/// socket; production uses `FlutterNTP.sync`.
class NtpTimeSource implements ServerTimeSource {
  NtpTimeSource({
    this._hosts = const [primaryHost, backupHost],
    this._timeout = const Duration(seconds: 3),
    this._clock = const SystemClock(),
    Future<Duration> Function(String host, Duration timeout)? query,
  }) : _query = query ?? _sntpQuery;

  /// ExpTech's time server — primary.
  static const String primaryHost = 'time.exptech.com.tw';

  /// Apple's public NTP — backup.
  static const String backupHost = 'time.apple.com';

  final List<String> _hosts;
  final Duration _timeout;
  final Clock _clock;
  final Future<Duration> Function(String host, Duration timeout) _query;

  /// One SNTP round trip returning the server→device offset.
  static Future<Duration> _sntpQuery(String host, Duration timeout) =>
      FlutterNTP.sync(lookUpAddress: host, timeout: timeout);

  @override
  Future<Result<int>> serverTimeMs() async {
    Object? lastError;
    for (final host in _hosts) {
      try {
        final offset = await _query(host, _timeout);
        // Apply the freshly measured offset to the device clock, now.
        return Ok(_clock.now().toUtc().add(offset).millisecondsSinceEpoch);
      } catch (error) {
        lastError = error;
        Log.warning('NTP sync via $host failed: $error');
      }
    }
    return Err(NetworkFailure('NTP sync failed on all hosts: $lastError'));
  }
}
