/// Seismic P/S travel-time table as a depth × epicentral-distance grid.
///
/// Mirrors the reference CWA model (`travel_time.py`): `depth` and `dist` are
/// the ascending grid axes, `p` holds P-wave times (s) and `sp` the S–P lead
/// times (s); the S time at a cell is `p + sp`. Pure domain data — loaded by
/// the data layer and injected here.
///
/// A [TravelTimeSource] pre-interpolates the grid down to two 1-D curves for a
/// single event depth, so every later query (a per-tick wavefront, or per-town
/// arrival times) is one `bisect` + linear interpolation — the same design the
/// reference implementation uses for thousands of targets per event.
library;

/// A query source for one earthquake: [depth] is interpolated once into the
/// P/S travel-time curves, then [arrival] (distance → time) and [waveRadius]
/// (time → radius) are cheap 1-D lookups.
class TravelTimeSource {
  TravelTimeSource(this._table, double depth)
    : _p = _interpDepth(_table, depth, _table.p),
      _s = _interpDepth(_table, depth, _table.s);

  final SeismicTravelTimeTable _table;

  /// P-wave travel time (s) at each tabulated epicentral distance.
  final List<double> _p;

  /// S-wave travel time (s) at each tabulated epicentral distance.
  final List<double> _s;

  /// P/S arrival times (s) at epicentral [distance] km.
  ({double p, double s}) arrival(double distance) {
    final p = _forward(_p, distance);
    return (p: p, s: _forward(_s, distance));
  }

  /// P/S wave-front radii (km) [elapsed] after the origin — 0 until the wave
  /// reaches the surface.
  ({double p, double s}) waveRadius(Duration elapsed) {
    final t = elapsed.inMilliseconds / 1000.0;
    return (p: _invert(_p, t), s: _invert(_s, t));
  }

  /// P-wave travel time in ms (the legacy callers' unit).
  double pWaveTimeMs(double distance) => _forward(_p, distance) * 1000;

  /// S-wave travel time in ms (the legacy callers' unit).
  double sWaveTimeMs(double distance) => _forward(_s, distance) * 1000;

  /// Distance → time, clamping to the table edges (reference behaviour).
  double _forward(List<double> time, double distance) {
    if (distance <= 0) return time.first;
    final i = _bisect(_table.dist, distance);
    final j = i == 0 ? 0 : i - 1;
    if (j >= _table.dist.length - 1) return time.last;
    final f =
        (distance - _table.dist[j]) / (_table.dist[j + 1] - _table.dist[j]);
    return time[j] * (1 - f) + time[j + 1] * f;
  }

  /// Time → radius, clamping to the table edges (reference behaviour).
  double _invert(List<double> time, double t) {
    if (t <= 0) return 0;
    final i = _bisect(time, t);
    final j = i == 0 ? 0 : i - 1;
    if (j >= time.length - 1) return _table.dist.last;
    final f = (t - time[j]) / (time[j + 1] - time[j]);
    return _table.dist[j] * (1 - f) + _table.dist[j + 1] * f;
  }

  static int _bisect(List<double> list, double value) {
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (list[mid] < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Linear interpolation between the depth rows bracketing [depth], clamped
  /// to the first/last row.
  static List<double> _interpDepth(
    SeismicTravelTimeTable table,
    double depth,
    List<List<double>> grid,
  ) {
    final i = _bisect(table.depth, depth);
    final j = i == 0 ? 0 : i - 1;
    if (j >= table.depth.length - 1) return grid.last;
    final f = (depth - table.depth[j]) / (table.depth[j + 1] - table.depth[j]);
    final a = grid[j];
    final b = grid[j + 1];
    return [for (var k = 0; k < a.length; k++) a[k] * (1 - f) + b[k] * f];
  }
}

/// The bundled CWA travel-time grid: P-wave times plus S–P lead times over
/// focal [depth] × epicentral [dist] (km).
class SeismicTravelTimeTable {
  SeismicTravelTimeTable({
    required this.depth,
    required this.dist,
    required this.p,
    required this.sp,
  });

  /// Ascending focal depths (km).
  final List<double> depth;

  /// Ascending epicentral distances (km).
  final List<double> dist;

  /// `p[depthRow][distCol]` — P-wave travel time (s).
  final List<List<double>> p;

  /// `sp[depthRow][distCol]` — S–P lead time (s); S = p + sp.
  final List<List<double>> sp;

  /// S-wave travel times (s), derived once from [p] + [sp].
  late final List<List<double>> s = [
    for (var i = 0; i < p.length; i++)
      [for (var j = 0; j < p[i].length; j++) p[i][j] + sp[i][j]],
  ];

  /// A query source for an event at [depth] km.
  TravelTimeSource source(double depth) => TravelTimeSource(this, depth);
}
