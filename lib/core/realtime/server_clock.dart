import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_time_source.dart';

/// A [Clock] returning **calibrated UTC** — the server's notion of "now" —
/// anchored to a monotonic clock so it can't be corrupted by the device clock.
///
/// On each [sync] it records the server time together with a monotonic [Elapsed]
/// reading; [now] then advances the anchored server time by the monotonic delta
/// since. Because the delta comes from a `Stopwatch` (uptime-style, never wall
/// time), a device-clock change, timezone shift, or manual clock edit cannot
/// move calibrated time — only a resync moves the anchor. This is what the app's
/// realtime staleness and any timestamped UI are measured against.
///
/// [sync] is best-effort: on failure it keeps the last anchor (device time until
/// the first success) and stays usable, so flaky NTP can never block the app.
class ServerClock implements Clock {
  ServerClock(this._device, this._elapsed, this._source);

  final Clock _device;
  final Elapsed _elapsed;
  final ServerTimeSource _source;

  /// Server time (ms epoch, UTC) captured at the last successful sync.
  int? _anchorServerMs;

  /// Monotonic reading captured at that same sync.
  Duration? _anchorMono;

  bool _isSynced = false;

  /// Whether at least one sync has succeeded; false means [now] is device time.
  bool get isSynced => _isSynced;

  @override
  DateTime now() {
    final anchorMs = _anchorServerMs;
    final anchorMono = _anchorMono;
    if (anchorMs == null || anchorMono == null) {
      return _device.now().toUtc(); // best-effort until the first sync
    }
    final elapsedSinceAnchor = _elapsed.elapsed - anchorMono;
    return DateTime.fromMillisecondsSinceEpoch(
      anchorMs + elapsedSinceAnchor.inMilliseconds,
      isUtc: true,
    );
  }

  /// The current device→server correction (calibrated now minus device now),
  /// for diagnostics; zero before the first sync.
  Duration get offset =>
      _isSynced ? now().difference(_device.now().toUtc()) : Duration.zero;

  /// Re-anchors calibrated time from the server, bounded by [timeout] (long
  /// enough to cover the primary→backup NTP fallback). Keeps the last anchor
  /// (and logs) on failure.
  Future<void> sync({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final result = await _source.serverTimeMs().timeout(timeout);
      final serverMs = result.valueOrNull;
      if (serverMs == null) {
        Log.warning(
          'ServerClock sync failed: ${result.failureOrNull?.message}',
        );
        return;
      }
      _anchorServerMs = serverMs;
      _anchorMono = _elapsed.elapsed;
      _isSynced = true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ServerClock sync');
    }
  }
}
