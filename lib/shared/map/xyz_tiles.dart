/// Slippy-map XYZ helpers for viewport tile coverage.
library;

import 'dart:math' as math;

import 'package:dpip/core/geo/geo_math.dart';

/// One Web-Mercator tile at zoom [z].
typedef XyzTile = ({int z, int x, int y});

/// Integer tile X for [lng] at zoom [z] (clamped to the valid range).
int lngToTileX(double lng, int z) {
  final n = 1 << z;
  return (((lng + 180.0) / 360.0) * n).floor().clamp(0, n - 1);
}

/// Integer tile Y for [lat] at zoom [z] (Web Mercator; north → smaller y).
int latToTileY(double lat, int z) {
  final n = 1 << z;
  final latRad = degToRad(lat.clamp(-85.05112878, 85.05112878));
  final y =
      ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
          2.0) *
      n;
  return y.floor().clamp(0, n - 1);
}

/// All XYZ tiles covering the lat/lng box at [z], optionally expanded by
/// [pad] tiles on each side. Returns at most [maxTiles] (empty when the box
/// would exceed that — caller should drop to a coarser zoom).
List<XyzTile> tilesCovering({
  required double south,
  required double west,
  required double north,
  required double east,
  required int z,
  int pad = 0,
  int maxTiles = 48,
}) {
  if (z < 0) return const [];
  final n = 1 << z;
  var minX = lngToTileX(west, z) - pad;
  var maxX = lngToTileX(east, z) + pad;
  var minY = latToTileY(north, z) - pad;
  var maxY = latToTileY(south, z) + pad;
  minX = minX.clamp(0, n - 1);
  maxX = maxX.clamp(0, n - 1);
  minY = minY.clamp(0, n - 1);
  maxY = maxY.clamp(0, n - 1);
  if (minX > maxX || minY > maxY) return const [];
  final count = (maxX - minX + 1) * (maxY - minY + 1);
  if (count > maxTiles) return const [];
  final out = <XyzTile>[];
  for (var x = minX; x <= maxX; x++) {
    for (var y = minY; y <= maxY; y++) {
      out.add((z: z, x: x, y: y));
    }
  }
  return out;
}
