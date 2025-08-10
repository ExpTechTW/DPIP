import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

extension GeoJsonLatLng on LatLng {
  bool get isValid => latitude != 0 && longitude != 0;

  List<double> get asGeoJsonCooridnate => [longitude, latitude];

  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)..setGeometry(asGeoJsonCooridnate);
  }

  /// Calculates the distance between the supplied coordinates in meters. The distance between the coordinates is
  /// calculated using the Haversine formula (see https://en.wikipedia.org/wiki/Haversine_formula).
  double to(LatLng other) => Geolocator.distanceBetween(latitude, longitude, other.latitude, other.longitude);
}
