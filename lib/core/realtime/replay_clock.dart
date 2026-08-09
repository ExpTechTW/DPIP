import 'package:dpip/core/realtime/elapsed.dart';

/// A synthetic wall clock that ticks 1:1 with real elapsed time from a fixed
/// historical instant — the timing primitive a replay [RealtimeSource] polls
/// against instead of [ServerClock]/`DateTime.now()`.
///
/// Built on the same [Elapsed] seam [RealtimeChannel] uses for staleness, so
/// it stays monotonic (immune to device-clock/timezone changes) and is
/// unit-testable with a fake elapsed source.
class ReplayClock {
  ReplayClock(this.startAt, {Elapsed? elapsed})
    : _elapsed = elapsed ?? SystemElapsed() {
    _startMark = _elapsed.elapsed;
  }

  /// The historical instant playback began at.
  final DateTime startAt;

  final Elapsed _elapsed;
  late final Duration _startMark;

  /// [startAt] plus real time elapsed since this clock was created.
  DateTime now() => startAt.add(_elapsed.elapsed - _startMark);
}
