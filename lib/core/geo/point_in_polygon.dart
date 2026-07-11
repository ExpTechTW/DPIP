import 'package:dpip/core/models/lat_lng.dart';

/// Dependency-free ray-casting point-in-polygon tests over GeoJSON-style rings
/// (replaces the `geojson_vi` package for the town-lookup use case).
///
/// A ring is a list of `[longitude, latitude]` pairs in GeoJSON coordinate
/// order.
bool isPointInRing(LatLng point, List<List<double>> ring) {
  var inside = false;
  var j = ring.length - 1;
  for (var i = 0; i < ring.length; i++) {
    final xi = ring[i][0];
    final yi = ring[i][1];
    final xj = ring[j][0];
    final yj = ring[j][1];
    final intersect =
        ((yi > point.latitude) != (yj > point.latitude)) &&
        (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
    j = i;
  }
  return inside;
}

/// Tests whether [point] lies inside a GeoJSON polygon (a list of rings whose
/// first entry is the outer ring). Only the outer ring is considered, matching
/// the town-boundary lookup behaviour.
bool isPointInPolygon(LatLng point, List<List<List<double>>> polygon) {
  if (polygon.isEmpty) return false;
  return isPointInRing(point, polygon.first);
}

/// Tests whether [point] lies inside any polygon of a GeoJSON MultiPolygon.
bool isPointInMultiPolygon(
  LatLng point,
  List<List<List<List<double>>>> multiPolygon,
) {
  for (final polygon in multiPolygon) {
    if (isPointInPolygon(point, polygon)) return true;
  }
  return false;
}
