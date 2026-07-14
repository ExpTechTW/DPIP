import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Exact GPS→township resolution by **point-in-polygon** over the bundled
/// township boundaries (`assets/map/town_boundaries.json.gz`).
///
/// This replaces the nearest-centroid approximation, which mis-resolves near
/// township borders — where getting the wrong township means the wrong local
/// alerts. Correctness comes from ray-casting the actual boundary polygons
/// (holes and multi-part townships handled); speed comes from a uniform **grid
/// index** that narrows each query to the handful of townships whose bounding
/// box overlaps the query cell, so a lookup tests ~1–3 polygons instead of 367.
///
/// The bundled asset (`town_boundaries.bin.gz`) is a gzipped **delta + zig-zag
/// varint** encoding of the polygons (see `tool/build_town_boundaries.dart`):
/// coordinates are ≤4-decimal, so each is stored as the `×1e4` integer delta
/// from the previous vertex, LEB128-packed — ~72% smaller than the float-text
/// JSON, and lossless, so the golden lookups are unchanged. [fromBinary] decodes
/// it; the bounding box is recomputed from the points. [fromDecoded] still
/// builds from a plain `{ code: { b: bbox, p: [polygon…] } }` map (a polygon is
/// `[outerRing, hole…]`, a ring a flat `[lng,lat,…]` list) so the lookup is
/// unit-testable without the asset.
class TownBoundaries {
  TownBoundaries._(this._shapes, this._grid);

  final Map<String, _TownShape> _shapes;
  final _GridIndex _grid;

  /// Builds from the decoded boundary map (see the class doc for the shape).
  factory TownBoundaries.fromDecoded(Map<String, dynamic> json) {
    final shapes = <String, _TownShape>{};
    for (final entry in json.entries) {
      final obj = entry.value as Map<String, dynamic>;
      final b = (obj['b'] as List).cast<num>();
      final polygons = [
        for (final poly in obj['p'] as List)
          [
            for (final ring in poly as List)
              Float64List.fromList([
                for (final v in ring as List) (v as num).toDouble(),
              ]),
          ],
      ];
      shapes[entry.key] = _TownShape(
        minLng: b[0].toDouble(),
        minLat: b[1].toDouble(),
        maxLng: b[2].toDouble(),
        maxLat: b[3].toDouble(),
        polygons: polygons,
      );
    }
    return TownBoundaries._(shapes, _GridIndex.build(shapes));
  }

  /// Builds from the bundled compact binary (`gzip` → delta-varint; see the
  /// class doc and `tool/build_town_boundaries.dart`). The bounding box is
  /// recomputed from the vertices rather than stored.
  factory TownBoundaries.fromBinary(Uint8List bytes) {
    var pos = 0;
    int readVarint() {
      var result = 0;
      var shift = 0;
      while (true) {
        final b = bytes[pos++];
        result |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) return result;
        shift += 7;
      }
    }

    int unzigzag(int z) => (z & 1) == 0 ? z >> 1 : -((z + 1) >> 1);

    final shapes = <String, _TownShape>{};
    final townCount = readVarint();
    for (var t = 0; t < townCount; t++) {
      final codeLen = readVarint();
      final code = ascii.decode(bytes.sublist(pos, pos + codeLen));
      pos += codeLen;
      var minLng = double.infinity, minLat = double.infinity;
      var maxLng = -double.infinity, maxLat = -double.infinity;
      final polygons = <List<Float64List>>[];
      final polyCount = readVarint();
      for (var p = 0; p < polyCount; p++) {
        final ringCount = readVarint();
        final rings = <Float64List>[];
        for (var r = 0; r < ringCount; r++) {
          final pointCount = readVarint();
          final ring = Float64List(pointCount * 2);
          var px = 0, py = 0;
          for (var i = 0; i < pointCount; i++) {
            px += unzigzag(readVarint());
            py += unzigzag(readVarint());
            final lng = px / 1e4, lat = py / 1e4;
            ring[i * 2] = lng;
            ring[i * 2 + 1] = lat;
            if (lng < minLng) minLng = lng;
            if (lng > maxLng) maxLng = lng;
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
          }
          rings.add(ring);
        }
        polygons.add(rings);
      }
      shapes[code] = _TownShape(
        minLng: minLng,
        minLat: minLat,
        maxLng: maxLng,
        maxLat: maxLat,
        polygons: polygons,
      );
    }
    return TownBoundaries._(shapes, _GridIndex.build(shapes));
  }

  /// Loads and decodes the bundled boundaries (`gzip` → delta-varint binary).
  static Future<TownBoundaries> load() async {
    final bytes = await rootBundle.load('assets/map/town_boundaries.bin.gz');
    return TownBoundaries.fromBinary(
      Uint8List.fromList(gzip.decode(bytes.buffer.asUint8List())),
    );
  }

  /// The code of the township containing ([lat], [lng]), or null if the point is
  /// outside every township (e.g. at sea) — the caller then falls back to
  /// nearest-centroid.
  String? codeAt(double lat, double lng) {
    for (final code in _grid.candidates(lng, lat)) {
      if (_shapes[code]!.contains(lng, lat)) return code;
    }
    return null;
  }
}

/// One township's boundary: a bounding box (fast rejection) and its polygons.
class _TownShape {
  _TownShape({
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
    required this.polygons,
  });

  final double minLng, minLat, maxLng, maxLat;

  /// Polygons; each is `[outerRing, hole…]`; each ring is flat `[lng,lat,…]`.
  final List<List<Float64List>> polygons;

  bool contains(double lng, double lat) {
    if (lng < minLng || lng > maxLng || lat < minLat || lat > maxLat) {
      return false;
    }
    for (final polygon in polygons) {
      if (!_inRing(polygon[0], lng, lat)) continue;
      var inHole = false;
      for (var h = 1; h < polygon.length; h++) {
        if (_inRing(polygon[h], lng, lat)) {
          inHole = true;
          break;
        }
      }
      if (!inHole) return true;
    }
    return false;
  }

  /// Ray-casting: whether ([x], [y]) is inside the flat `[lng,lat,…]` [ring].
  static bool _inRing(Float64List ring, double x, double y) {
    var inside = false;
    final n = ring.length;
    var j = n - 2; // previous vertex (its lng index)
    for (var i = 0; i < n; i += 2) {
      final xi = ring[i], yi = ring[i + 1];
      final xj = ring[j], yj = ring[j + 1];
      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}

/// A uniform grid over the townships' extent; each cell lists the townships
/// whose bounding box overlaps it, so a query maps a point to a short candidate
/// list in O(1).
class _GridIndex {
  _GridIndex._(this._minLng, this._minLat, this._cols, this._rows, this._cells);

  static const double _cell = 0.05; // ~5 km

  final double _minLng, _minLat;
  final int _cols, _rows;
  final List<List<String>?> _cells; // row-major; null = empty cell

  static _GridIndex build(Map<String, _TownShape> shapes) {
    var minLng = double.infinity, minLat = double.infinity;
    var maxLng = -double.infinity, maxLat = -double.infinity;
    for (final s in shapes.values) {
      minLng = math.min(minLng, s.minLng);
      minLat = math.min(minLat, s.minLat);
      maxLng = math.max(maxLng, s.maxLng);
      maxLat = math.max(maxLat, s.maxLat);
    }
    final cols = ((maxLng - minLng) / _cell).ceil() + 1;
    final rows = ((maxLat - minLat) / _cell).ceil() + 1;
    final cells = List<List<String>?>.filled(cols * rows, null);
    shapes.forEach((code, s) {
      final c0 = ((s.minLng - minLng) / _cell).floor();
      final c1 = ((s.maxLng - minLng) / _cell).floor();
      final r0 = ((s.minLat - minLat) / _cell).floor();
      final r1 = ((s.maxLat - minLat) / _cell).floor();
      for (var r = r0; r <= r1; r++) {
        for (var c = c0; c <= c1; c++) {
          (cells[r * cols + c] ??= <String>[]).add(code);
        }
      }
    });
    return _GridIndex._(minLng, minLat, cols, rows, cells);
  }

  List<String> candidates(double lng, double lat) {
    final c = ((lng - _minLng) / _cell).floor();
    final r = ((lat - _minLat) / _cell).floor();
    if (c < 0 || c >= _cols || r < 0 || r >= _rows) return const [];
    return _cells[r * _cols + c] ?? const [];
  }
}
