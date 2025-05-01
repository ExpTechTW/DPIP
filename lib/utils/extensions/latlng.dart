import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

extension GeoJsonLatLng on LatLng {
  bool get isValid => latitude != 0 && longitude != 0;

  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point).setGeometry(toGeoJsonCoordinates());
  }
}
