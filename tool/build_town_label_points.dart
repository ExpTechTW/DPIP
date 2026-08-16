/// Computes where each township's map label belongs — the point inside it
/// furthest from any edge — and bakes the answer into
/// `lib/shared/map/town_label_points.g.dart`.
///
/// **Why not the directory point.** `TownDirectory`'s `lat`/`lng` is the
/// township's administrative seat (the district office), not its middle, so a
/// label drawn there sits wherever the office happens to be. For the mountain
/// townships that is the inhabited valley at one corner of a shape that runs
/// tens of kilometres into the range: 臺中市和平區's label lands 42 km from the
/// middle of 和平區. Measured across all 367, the median label is 2.1 km from
/// where it belongs and 194 of them are more than 2 km out.
///
/// **Why not just move the directory point.** It is also the anchor for
/// `TownDirectory.nearest`, the GPS→township fallback used at sea, in a
/// boundary gap, and before the polygons finish loading — and that answer
/// decides which township a disaster alert is addressed to. The nearest
/// *settlement* is the right answer there and the geometric middle is not, so
/// the label gets its own table and the directory is left alone.
///
/// **The point itself** is the pole of inaccessibility: of every point inside
/// the polygon, the one whose distance to the nearest edge is greatest. That is
/// the standard place to label an area, and unlike a centroid it is always
/// inside the shape — a centroid falls outside anything sufficiently concave,
/// which describes most of Taiwan's coastal and mountain townships.
///
/// Computed with Mapbox's polylabel: cover the bounding box in cells, then
/// repeatedly subdivide whichever cell could still contain a better answer than
/// the best one found so far, until no cell can beat it by more than
/// [_precision]. A township made of several polygons (an outlying island, a
/// reef) is resolved per polygon and the one with the most room wins, so
/// 高雄市旗津區 labels on 旗津 rather than out at 南沙群島.
///
/// Distances are computed in a locally isotropic space — longitude scaled by
/// cos(latitude) — because a degree of longitude is ~92% of a degree of
/// latitude here, and without it the "middle" is skewed east-west.
///
/// Run after changing the boundary source:
/// `dart run tool/build_town_label_points.dart`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _src = 'assets/map/town_boundaries.json.gz';
const _directory = 'assets/location.json.gz';
const _out = 'lib/shared/map/town_label_points.g.dart';

/// Stop subdividing once no cell can beat the best by more than this, in the
/// scaled degree space. ~1e-5 deg ≈ 1 m, far finer than a label needs.
const double _precision = 1e-5;

void main() {
  final json = jsonDecode(
    utf8.decode(gzip.decode(File(_src).readAsBytesSync())),
  ) as Map<String, dynamic>;

  // The administrative seat, used to pick which polygon is the township's main
  // body. Several townships carry a second polygon that is a crude marine
  // administrative area — 雲林縣口湖鄉's is a 9-vertex box covering ~270 km² of
  // the Taiwan Strait, far roomier than its actual land — so "the polygon with
  // the most room" put the label out at sea. The seat is on the main body by
  // definition, which makes "the polygon containing it" the principled choice.
  final seats = (jsonDecode(
            utf8.decode(gzip.decode(File(_directory).readAsBytesSync())),
          )
          as Map<String, dynamic>)
      .map(
        (code, value) => MapEntry(code, (
          lat: ((value as Map<String, dynamic>)['lat'] as num).toDouble(),
          lng: (value['lng'] as num).toDouble(),
        )),
      );

  final points = <String, ({double lat, double lng})>{};
  var worst = 0.0;
  String? worstCode;

  json.forEach((code, value) {
    final polygons = (value as Map<String, dynamic>)['p'] as List;
    final seat = seats[code];
    ({double lat, double lng, double clearance})? best;
    var bestHoldsSeat = false;
    for (final polygon in polygons) {
      final rings = [
        for (final ring in polygon as List)
          [
            for (var i = 0; i + 1 < (ring as List).length; i += 2)
              _P((ring[i] as num).toDouble(), (ring[i + 1] as num).toDouble()),
          ],
      ]..removeWhere((r) => r.length < 3);
      if (rings.isEmpty) continue;
      final holdsSeat =
          seat != null && _signedDistance(seat.lng, seat.lat, rings, 1) > 0;
      final cell = _polylabel(rings);
      // A polygon holding the seat always beats one that does not, however
      // roomy the other is; among equals, room wins.
      final better = best == null ||
          (holdsSeat && !bestHoldsSeat) ||
          (holdsSeat == bestHoldsSeat && cell.clearance > best.clearance);
      if (better) {
        best = (lat: cell.lat, lng: cell.lng, clearance: cell.clearance);
        bestHoldsSeat = holdsSeat;
      }
    }
    final found = best;
    if (found == null) return;
    points[code] = (lat: found.lat, lng: found.lng);
    if (found.clearance > worst) {
      worst = found.clearance;
      worstCode = code;
    }
  });

  final buffer = StringBuffer()
    ..writeln(
      '// GENERATED by tool/build_town_label_points.dart — do not edit.',
    )
    ..writeln('//')
    ..writeln('// Where each township\'s name is drawn on the map: the point')
    ..writeln(
      '// inside it furthest from any edge. See the tool for why this is',
    )
    ..writeln('// not TownDirectory\'s point and must not replace it.')
    ..writeln('library;')
    ..writeln()
    ..writeln('/// Township code → the (lat, lng) its label is placed at.')
    ..writeln('const Map<String, (double, double)> townLabelPoints = {');
  final codes = points.keys.toList()..sort();
  for (final code in codes) {
    final p = points[code]!;
    buffer.writeln(
      "  '$code': (${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}),",
    );
  }
  buffer.writeln('};');
  File(_out).writeAsStringSync(buffer.toString());

  stdout.writeln('${points.length} label points -> $_out');
  stdout.writeln('roomiest: $worstCode');
}

class _P {
  const _P(this.x, this.y);
  final double x; // lng
  final double y; // lat
}

class _Cell {
  _Cell(this.x, this.y, this.h, List<List<_P>> rings, double kx)
    : d = _signedDistance(x, y, rings, kx) {
    max = d + h * math.sqrt2;
  }

  final double x;
  final double y;
  final double h; // half the cell size
  final double d; // signed distance to the polygon, positive inside
  late final double max; // the best any point in this cell could score
}

({double lat, double lng, double clearance}) _polylabel(List<List<_P>> rings) {
  final outer = rings.first;
  var minX = outer.first.x, maxX = minX;
  var minY = outer.first.y, maxY = minY;
  for (final p in outer) {
    if (p.x < minX) minX = p.x;
    if (p.x > maxX) maxX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }
  // Make a degree of longitude the same length as a degree of latitude here, so
  // "furthest from an edge" means the same thing in both axes.
  final kx = math.cos((minY + maxY) / 2 * math.pi / 180);

  final width = (maxX - minX) * kx;
  final height = maxY - minY;
  final cellSize = math.min(width, height);
  if (cellSize == 0) {
    return (lat: minY, lng: minX, clearance: 0);
  }
  var h = cellSize / 2;

  // Largest-first, so the first cell that cannot be beaten ends the search.
  final queue = PriorityQueue<_Cell>((a, b) => b.max.compareTo(a.max));
  for (var x = minX; x < maxX; x += h / kx) {
    for (var y = minY; y < maxY; y += h) {
      queue.add(_Cell(x + h / kx / 2, y + h / 2, h, rings, kx));
    }
  }

  var best = _Cell((minX + maxX) / 2, (minY + maxY) / 2, 0, rings, kx);
  while (queue.isNotEmpty) {
    final cell = queue.removeFirst();
    if (cell.d > best.d) best = cell;
    if (cell.max - best.d <= _precision) continue;
    h = cell.h / 2;
    for (final dx in [-h, h]) {
      for (final dy in [-h, h]) {
        queue.add(_Cell(cell.x + dx / kx, cell.y + dy, h, rings, kx));
      }
    }
  }
  return (lat: best.y, lng: best.x, clearance: best.d);
}

/// Distance from ([x], [y]) to the nearest edge of [rings], negative outside.
///
/// Every ring counts toward the distance so a label keeps clear of holes as
/// well as the outline; only the outer ring decides inside-ness, with holes
/// flipping it back out by the even-odd rule the crossing count already gives.
double _signedDistance(double x, double y, List<List<_P>> rings, double kx) {
  var inside = false;
  var minSq = double.infinity;
  for (final ring in rings) {
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.y > y) != (b.y > y) &&
          x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
      final d = _segmentDistanceSq(x, y, a, b, kx);
      if (d < minSq) minSq = d;
    }
  }
  final dist = minSq == 0 ? 0.0 : math.sqrt(minSq);
  return inside ? dist : -dist;
}

double _segmentDistanceSq(double px, double py, _P a, _P b, double kx) {
  var x = a.x, y = a.y;
  var dx = (b.x - x) * kx, dy = b.y - y;
  if (dx != 0 || dy != 0) {
    final t = (((px - x) * kx) * dx + (py - y) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      x = b.x;
      y = b.y;
    } else if (t > 0) {
      x += dx / kx * t;
      y += dy * t;
    }
  }
  dx = (px - x) * kx;
  dy = py - y;
  return dx * dx + dy * dy;
}

/// Minimal binary heap — `package:collection` is a dev dependency the tool
/// directory does not otherwise need.
class PriorityQueue<T> {
  PriorityQueue(this._compare);
  final int Function(T, T) _compare;
  final List<T> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[i], _items[parent]) >= 0) break;
      final tmp = _items[i];
      _items[i] = _items[parent];
      _items[parent] = tmp;
      i = parent;
    }
  }

  T removeFirst() {
    final first = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var smallest = i;
        if (l < _items.length && _compare(_items[l], _items[smallest]) < 0) {
          smallest = l;
        }
        if (r < _items.length && _compare(_items[r], _items[smallest]) < 0) {
          smallest = r;
        }
        if (smallest == i) break;
        final tmp = _items[i];
        _items[i] = _items[smallest];
        _items[smallest] = tmp;
        i = smallest;
      }
    }
    return first;
  }
}
