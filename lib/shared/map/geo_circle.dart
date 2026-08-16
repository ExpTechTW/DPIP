/// GeoJSON circle helpers — MapLibre has no native geo-circle primitive, so a
/// geo circle (e.g. an EEW wavefront ring) is approximated as an N-sided
/// closed [LatLng.destinationPoint] polygon, drawn as an outline
/// ([circleFeature], a `LineLayerProperties` line layer) and/or a translucent
/// disc ([circleFillFeature], a `FillLayerProperties` fill layer).
///
/// The ring math is hoisted so a repeated ring is cheap: the bearing table is
/// cached per step count, and each ring computes its centre/delta constants
/// once instead of re-deriving them per vertex (~7 trig per point → 2).
library;

import 'dart:math' as math;

import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/core/models/lat_lng.dart';

/// A GeoJSON `Feature` (closed `LineString` geometry) tracing a [steps]-sided
/// approximation of the circle of [radiusMetres] around [center].
///
/// [properties] are attached to the feature (e.g. `{'type': 'p'}`) so one
/// source can carry several rings, distinguished by a layer filter.
Map<String, dynamic> circleFeature(
  LatLng center,
  double radiusMetres, {
  int steps = 64,
  Map<String, dynamic> properties = const {},
}) => {
  'type': 'Feature',
  'geometry': {
    'type': 'LineString',
    'coordinates': _ring(center, radiusMetres, steps),
  },
  'properties': properties,
};

/// A GeoJSON `Feature` (closed `Polygon` geometry) tracing the same circle as
/// [circleFeature], for a `FillLayerProperties` translucent disc under the
/// outline ring — e.g. the already-shaken area inside an EEW wavefront.
Map<String, dynamic> circleFillFeature(
  LatLng center,
  double radiusMetres, {
  int steps = 64,
  Map<String, dynamic> properties = const {},
}) => {
  'type': 'Feature',
  'geometry': {
    'type': 'Polygon',
    'coordinates': [_ring(center, radiusMetres, steps)],
  },
  'properties': properties,
};

/// (sin, cos) of each bearing — the same table for every ring of that step
/// count, so per-vertex trig is just the asin/atan2 of the forward geodesic.
final Map<int, List<(double, double)>> _bearingCache = {};

List<(double, double)> _bearings(int steps) => _bearingCache.putIfAbsent(
  steps,
  () => [
    for (var i = 0; i <= steps; i++)
      () {
        final theta = i * 2 * math.pi / steps;
        return (math.sin(theta), math.cos(theta));
      }(),
  ],
);

List<List<double>> _ring(LatLng center, double radiusMetres, int steps) {
  const earthRadius = 6378137.0;
  final delta = radiusMetres / earthRadius;
  final sinD = math.sin(delta);
  final cosD = math.cos(delta);
  final lat1 = degToRad(center.latitude);
  final lon1 = degToRad(center.longitude);
  final sinLat1 = math.sin(lat1);
  final cosLat1 = math.cos(lat1);
  return [
    for (final (sinTheta, cosTheta) in _bearings(steps))
      _vertex(sinLat1, cosLat1, lat1, lon1, sinD, cosD, sinTheta, cosTheta),
  ];
}

/// One vertex of the forward geodesic — centre/delta constants are passed in
/// so only the per-vertex asin/atan2 remain.
List<double> _vertex(
  double sinLat1,
  double cosLat1,
  double lat1,
  double lon1,
  double sinD,
  double cosD,
  double sinTheta,
  double cosTheta,
) {
  final lat2 = math.asin(sinLat1 * cosD + cosLat1 * sinD * cosTheta);
  final lon2 =
      lon1 +
      math.atan2(sinTheta * sinD * cosLat1, cosD - sinLat1 * math.sin(lat2));
  return [lon2 * 180.0 / math.pi, lat2 * 180.0 / math.pi];
}
