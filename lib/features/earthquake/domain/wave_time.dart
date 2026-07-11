/// Estimated P- and S-wave arrival times (seconds) for a hypocentral setup.
class WaveTime {
  const WaveTime({required this.p, required this.s});

  /// Estimated P-wave arrival time (seconds).
  final double p;

  /// Estimated S-wave arrival time (seconds).
  final double s;
}
