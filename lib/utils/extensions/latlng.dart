import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

extension GeoJsonLatLng on LatLng {
  bool get isValid => latitude != 0 && longitude != 0;

  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point).setGeometry(toGeoJsonCoordinates());
  }

  double to(LatLng other) {
    final double sinLatA = sin(atan(tan(latitude)));
    final double sinLatB = sin(atan(tan(other.latitude)));
    final double cosLatA = cos(atan(tan(latitude)));
    final double cosLatB = cos(atan(tan(other.latitude)));

    return acos(sinLatA * sinLatB + cosLatA * cosLatB * cos(longitude - other.longitude)) * 6371.008;
  }
}
