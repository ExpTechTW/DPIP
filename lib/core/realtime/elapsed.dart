/// A monotonic elapsed-time source, behind a seam so freshness is testable.
///
/// Unlike a wall clock ([Clock]), this never moves backward and is immune to
/// device-clock changes and server-offset resyncs — so it is what the realtime
/// spine measures "time since last successful fetch" against. Using wall time
/// there would let a clock correction reclassify a dead feed as live.
///
/// Production uses [SystemElapsed] (a running `Stopwatch`); tests inject a fake
/// whose value they advance by hand.
abstract interface class Elapsed {
  /// Monotonically non-decreasing time since this source was created.
  Duration get elapsed;
}

/// An [Elapsed] backed by a monotonic `Stopwatch`.
class SystemElapsed implements Elapsed {
  SystemElapsed() : _stopwatch = Stopwatch() {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
