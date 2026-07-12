import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';

/// A [Clock] that returns device time corrected by a server offset, so realtime
/// staleness is measured against the server's notion of "now", not a possibly
/// skewed device clock.
///
/// [sync] is best-effort: on failure it keeps the last offset (device time until
/// the first success) and stays usable, so a flaky single-host `/ntp` can never
/// block the app. Because a channel compares two instants from this same clock,
/// the offset cancels for fetch-freshness staleness — the offset only matters
/// for feeds whose payloads carry their own server timestamps.
class ServerClock implements Clock {
  ServerClock(this._device, this._source);

  final Clock _device;
  final ServerTimeSource _source;

  Duration _offset = Duration.zero;
  bool _isSynced = false;

  /// Whether at least one sync has succeeded; false means [now] is device time.
  bool get isSynced => _isSynced;

  /// The current device→server correction.
  Duration get offset => _offset;

  @override
  DateTime now() => _device.now().add(_offset);

  /// Re-measures the device→server offset, bounded by [timeout]. Keeps the last
  /// offset (and logs) on failure.
  Future<void> sync({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final result = await _source.serverTimeMs().timeout(timeout);
      final serverMs = result.valueOrNull;
      if (serverMs == null) {
        Log.warning(
          'ServerClock sync failed: ${result.failureOrNull?.message}',
        );
        return;
      }
      final deviceMs = _device.now().millisecondsSinceEpoch;
      _offset = Duration(milliseconds: serverMs - deviceMs);
      _isSynced = true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ServerClock sync');
    }
  }
}
