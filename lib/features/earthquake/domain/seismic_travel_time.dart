/// A row of the seismic travel-time table: epicentral radius [r] (km) and the
/// corresponding P/S travel times (seconds).
typedef TravelTimeRow = ({double p, double r, double s});

/// Seismic P/S travel-time table keyed by focal depth (km).
///
/// Converts between elapsed time and wave-front radius. Pure domain data — the
/// table itself is loaded by the data layer and injected here, replacing the
/// former reliance on a global.
class SeismicTravelTimeTable {
  const SeismicTravelTimeTable(this.rowsByDepth);

  /// Travel-time rows for each tabulated focal depth (km).
  final Map<int, List<TravelTimeRow>> rowsByDepth;

  int _closestDepth(double depth) => rowsByDepth.keys.reduce(
    (a, b) => (b - depth).abs() < (a - depth).abs() ? b : a,
  );

  /// P/S wave-front radii (km) and the S arrival time (s) for an event at
  /// [depth] (km) whose origin was [elapsed] ago.
  ({double p, double s, double sT}) waveRadius(double depth, Duration elapsed) {
    final t = elapsed.inMilliseconds / 1000.0;
    final rows = rowsByDepth[_closestDepth(depth)]!;

    double pDist = 0;
    double sDist = 0;
    double sT = 0;
    TravelTimeRow? prev;

    for (final row in rows) {
      if (pDist == 0 && row.p > t) {
        pDist = prev == null
            ? row.r
            : prev.r + ((t - prev.p) / (row.p - prev.p)) * (row.r - prev.r);
      }
      if (sDist == 0 && row.s > t) {
        if (prev == null) {
          sDist = row.r;
          sT = row.s;
        } else {
          sDist = prev.r + ((t - prev.s) / (row.s - prev.s)) * (row.r - prev.r);
        }
      }
      if (pDist != 0 && sDist != 0) break;
      prev = row;
    }

    return (p: pDist < 0 ? 0 : pDist, s: sDist < 0 ? 0 : sDist, sT: sT);
  }

  /// S-wave travel time (ms) to reach epicentral [distance] (km) at [depth].
  double sWaveTime(double depth, double distance) =>
      _timeByDistance(depth, distance, (r) => r.s);

  /// P-wave travel time (ms) to reach epicentral [distance] (km) at [depth].
  double pWaveTime(double depth, double distance) =>
      _timeByDistance(depth, distance, (r) => r.p);

  double _timeByDistance(
    double depth,
    double distance,
    double Function(TravelTimeRow) pick,
  ) {
    final rows = rowsByDepth[_closestDepth(depth)]!;
    double time = 0;
    TravelTimeRow? prev;
    for (final row in rows) {
      if (time == 0 && row.r >= distance) {
        time = prev == null
            ? pick(row)
            : pick(prev) +
                  ((distance - prev.r) / (row.r - prev.r)) *
                      (pick(row) - pick(prev));
      }
      if (time != 0) break;
      prev = row;
    }
    return time * 1000;
  }
}
