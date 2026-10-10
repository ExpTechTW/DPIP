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

  /// The tabulated depth nearest [depth].
  ///
  /// The bundled table has 106 keys. A linear reduce walked all of them on
  /// every radius and every arrival. Keys that never decrease — the loaded
  /// table, and any fixture written in order — are found by binary search.
  /// A tie keeps the earlier key, which is what the reduce did (`<`, not
  /// `<=`). An unsorted map keeps the walk, because the winner of a tie is
  /// then the first key in iteration order, not the smaller depth.
  int _closestDepth(double depth) {
    final index = _depthIndexOf(this);
    if (!index.sorted) {
      return index.keys.reduce(
        (a, b) => (b - depth).abs() < (a - depth).abs() ? b : a,
      );
    }
    return _closestSortedDepth(index.keys, depth);
  }

  /// P/S wave-front radii (km) and the S arrival time (s) for an event at
  /// [depth] (km) whose origin was [elapsed] ago.
  ///
  /// Each front is the first row whose travel time exceeds [elapsed],
  /// interpolated against the row before it — the same row a linear walk
  /// stops on. A column that only increases (every depth of the bundled
  /// table does) is found by binary search; one that does not is walked.
  /// A front that interpolates to exactly 0 keeps walking, because the
  /// original loop treated 0 as "not found yet".
  ({double p, double s, double sT}) waveRadius(double depth, Duration elapsed) {
    final t = elapsed.inMilliseconds / 1000.0;
    final rows = rowsByDepth[_closestDepth(depth)]!;
    final order = _orderOf(rows);
    final pDist = _frontRadius(rows, t, _p, order.p);
    final sFront = _sFront(rows, t, order.s);
    return (
      p: pDist < 0 ? 0 : pDist,
      s: sFront.dist < 0 ? 0 : sFront.dist,
      sT: sFront.sT,
    );
  }

  /// S-wave travel time (ms) to reach epicentral [distance] (km) at [depth].
  double sWaveTime(double depth, double distance) =>
      _timeByDistance(depth, distance, _s);

  /// P-wave travel time (ms) to reach epicentral [distance] (km) at [depth].
  double pWaveTime(double depth, double distance) =>
      _timeByDistance(depth, distance, _p);

  double _timeByDistance(double depth, double distance, int component) {
    final rows = rowsByDepth[_closestDepth(depth)]!;
    final sorted = _orderOf(rows).r;
    var time = 0.0;
    for (
      var i = sorted ? _lowerBoundRadius(rows, distance) : 0;
      i < rows.length;
      i++
    ) {
      final row = rows[i];
      if (time == 0 && row.r >= distance) {
        if (i == 0) {
          time = _component(row, component);
        } else {
          final prev = rows[i - 1];
          time =
              _component(prev, component) +
              ((distance - prev.r) / (row.r - prev.r)) *
                  (_component(row, component) - _component(prev, component));
        }
      }
      if (time != 0) break;
    }
    return time * 1000;
  }
}

const int _p = 0;
const int _s = 1;

double _component(TravelTimeRow row, int component) => switch (component) {
  _p => row.p,
  _ => row.s,
};

/// Depth keys in map iteration order, and whether that order never decreases.
///
/// Cached per table: the lists are the loaded asset or a const fixture, not
/// something a caller mutates. Same assumption as [_orders].
final Expando<_DepthIndex> _depthIndexes = Expando<_DepthIndex>();

_DepthIndex _depthIndexOf(SeismicTravelTimeTable table) =>
    _depthIndexes[table] ??= _DepthIndex(table.rowsByDepth.keys);

final class _DepthIndex {
  _DepthIndex(Iterable<int> depths)
    : keys = List<int>.of(depths, growable: false),
      sorted = _neverDecreases(depths);

  final List<int> keys;
  final bool sorted;

  static bool _neverDecreases(Iterable<int> depths) {
    int? previous;
    for (final depth in depths) {
      if (previous != null && depth < previous) return false;
      previous = depth;
    }
    return true;
  }
}

/// Closest key in a non-decreasing list. A tie keeps the earlier key.
int _closestSortedDepth(List<int> keys, double depth) {
  var lo = 0;
  var hi = keys.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (keys[mid] < depth) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (lo <= 0) return keys.first;
  if (lo >= keys.length) return keys.last;
  final before = keys[lo - 1];
  final after = keys[lo];
  return (after - depth).abs() < (before - depth).abs() ? after : before;
}

/// Whether P, S and R never decrease. Cached per row list: the check is a
/// full pass, and the lists are the loaded table (or a const test fixture),
/// not something a caller mutates.
final Expando<_RowOrder> _orders = Expando<_RowOrder>();

_RowOrder _orderOf(List<TravelTimeRow> rows) =>
    _orders[rows] ??= _RowOrder(rows);

final class _RowOrder {
  _RowOrder(List<TravelTimeRow> rows)
    : p = _nonDecreasing(rows, _p),
      s = _nonDecreasing(rows, _s),
      r = _radiusNonDecreasing(rows);

  final bool p;
  final bool s;
  final bool r;

  static bool _nonDecreasing(List<TravelTimeRow> rows, int component) {
    for (var i = 1; i < rows.length; i++) {
      if (_component(rows[i], component) < _component(rows[i - 1], component)) {
        return false;
      }
    }
    return true;
  }

  static bool _radiusNonDecreasing(List<TravelTimeRow> rows) {
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].r < rows[i - 1].r) return false;
    }
    return true;
  }
}

/// First index whose [component] exceeds [t], or `rows.length`.
int _upperBound(List<TravelTimeRow> rows, double t, int component) {
  var lo = 0;
  var hi = rows.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (_component(rows[mid], component) > t) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

/// First index whose radius is at least [distance], or `rows.length`.
int _lowerBoundRadius(List<TravelTimeRow> rows, double distance) {
  var lo = 0;
  var hi = rows.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (rows[mid].r >= distance) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}

double _frontRadius(
  List<TravelTimeRow> rows,
  double t,
  int component,
  bool sorted,
) {
  var dist = 0.0;
  for (
    var i = sorted ? _upperBound(rows, t, component) : 0;
    i < rows.length;
    i++
  ) {
    final row = rows[i];
    if (dist == 0 && _component(row, component) > t) {
      if (i == 0) {
        dist = row.r;
      } else {
        final prev = rows[i - 1];
        final t0 = _component(prev, component);
        final t1 = _component(row, component);
        dist = prev.r + ((t - t0) / (t1 - t0)) * (row.r - prev.r);
      }
    }
    if (dist != 0) return dist;
  }
  return dist;
}

({double dist, double sT}) _sFront(
  List<TravelTimeRow> rows,
  double t,
  bool sorted,
) {
  var dist = 0.0;
  var sT = 0.0;
  for (var i = sorted ? _upperBound(rows, t, _s) : 0; i < rows.length; i++) {
    final row = rows[i];
    if (dist == 0 && row.s > t) {
      if (i == 0) {
        dist = row.r;
        sT = row.s;
      } else {
        final prev = rows[i - 1];
        dist = prev.r + ((t - prev.s) / (row.s - prev.s)) * (row.r - prev.r);
      }
    }
    if (dist != 0) break;
  }
  return (dist: dist, sT: sT);
}
