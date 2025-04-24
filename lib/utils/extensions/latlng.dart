import 'package:dpip/utils/geojson.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

extension GeoJsonLatLng on LatLng {
  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point).setGeometry(toGeoJsonCoordinates());
  }
}
