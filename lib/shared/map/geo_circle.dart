/// GeoJSON circle helpers — MapLibre has no native geo-circle primitive, so a
/// geo circle (e.g. an EEW wavefront ring) is approximated as an N-sided
/// closed [LatLng.destinationPoint] polygon, drawn as an outline
/// ([circleFeature], a `LineLayerProperties` line layer) and/or a translucent
/// disc ([circleFillFeature], a `FillLayerProperties` fill layer).
library;

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

List<List<double>> _ring(LatLng center, double radiusMetres, int steps) => [
  for (var i = 0; i <= steps; i++)
    _pointOnCircle(center, radiusMetres, i, steps),
];

List<double> _pointOnCircle(
  LatLng center,
  double radiusMetres,
  int i,
  int steps,
) {
  final point = center.destinationPoint(i * 360.0 / steps, radiusMetres);
  return [point.longitude, point.latitude];
}
