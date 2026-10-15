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
///
/// **The anchor is a trimmed mean, not the last sample.** Each sync measures
/// where the monotonic clock's zero falls in server time; the clock keeps the
/// last [sampleWindow] of those measurements and anchors on their mean with
/// the highest and lowest dropped. A single sample is only as good as its
/// round trip — SNTP is within milliseconds, but the HTTP fallback is ±RTT/2,
/// easily a few hundred on a congested mobile link — and re-anchoring on each
/// one made calibrated time jump back and forth by that much every minute,
/// which every countdown and wavefront measured against it showed. One wild
/// sample among five is simply dropped.
///
/// A real change is not noise, though: when a sample disagrees with **every**
/// sample in the window by more than [stepThreshold] the window restarts from
/// it, so the clock follows at once. The monotonic clock not running while the
/// device sleeps is the everyday case — the server time at its zero really has
/// moved, by however long the device slept.
class ServerClock implements Clock {
  ServerClock(this._device, this._elapsed, this._source);

  final Clock _device;
  final Elapsed _elapsed;
  final ServerTimeSource _source;

  /// How many recent syncs the anchor is averaged over.
  static const int sampleWindow = 5;

  /// A sample this far from every sample in the window is a step, not noise.
  static const Duration stepThreshold = Duration(seconds: 2);

  /// Recent measurements, oldest first: server time (ms epoch, UTC) at the
  /// monotonic clock's zero, i.e. server time minus the monotonic reading taken
  /// at the same sync.
  final List<int> _samples = [];

  /// The trimmed mean of [_samples] — what [now] adds monotonic time to.
  int? _originMs;

  bool _isSynced = false;

  /// Whether at least one sync has succeeded; false means [now] is device time.
  bool get isSynced => _isSynced;

  @override
  DateTime now() {
    final originMs = _originMs;
    if (originMs == null) {
      return _device.now().toUtc(); // best-effort until the first sync
    }
    return DateTime.fromMillisecondsSinceEpoch(
      originMs + _elapsed.elapsed.inMilliseconds,
      isUtc: true,
    );
  }

  /// Adds one measurement and re-derives the anchor from the window.
  void _addSample(int sampleMs) {
    final step = stepThreshold.inMilliseconds;
    if (_samples.isNotEmpty &&
        _samples.every((s) => (sampleMs - s).abs() > step)) {
      Log.info(
        'ServerClock: step of ${sampleMs - _originMs!} ms — '
        'restarting the sample window',
      );
      _samples.clear();
    }
    _samples.add(sampleMs);
    if (_samples.length > sampleWindow) _samples.removeAt(0);
    _originMs = trimmedMean(_samples);
  }

  /// The mean of [samples] without its single highest and lowest value (once
  /// there are at least three to drop them from), rounded to the millisecond.
  static int trimmedMean(List<int> samples) {
    final sorted = [...samples]..sort();
    final kept = sorted.length >= 3
        ? sorted.sublist(1, sorted.length - 1)
        : sorted;
    var sum = 0;
    for (final value in kept) {
      sum += value;
    }
    return (sum / kept.length).round();
  }

  /// The current device→server correction (calibrated now minus device now),
  /// for diagnostics; zero before the first sync.
  Duration get offset =>
      _isSynced ? now().difference(_device.now().toUtc()) : Duration.zero;

  /// Measures the server's time, bounded by [timeout], and folds it into the
  /// anchor (see the class doc). Keeps the last anchor (and logs) on failure.
  ///
  /// The default has to cover the whole chain, not one request: SNTP's
  /// primary→backup fallback is 2 hosts × 3s, and the HTTP `/ntp` stage behind
  /// it adds 2s more. Ten seconds leaves headroom over that 8s worst case, and
  /// is only ever spent when UDP/123 is blocked outright — the case the HTTP
  /// stage exists for. A first-host success still returns in under 3s.
  Future<void> sync({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final result = await _source.serverTimeMs().timeout(timeout);
      final serverMs = result.valueOrNull;
      if (serverMs == null) {
        Log.warning(
          'ServerClock sync failed: ${result.failureOrNull?.message}',
        );
        return;
      }
      _addSample(serverMs - _elapsed.elapsed.inMilliseconds);
      _isSynced = true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ServerClock sync');
    }
  }
}
