import 'package:dpip/utils/geojson.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

extension GeoJsonLatLng on LatLng {
  bool get isValid => latitude != 0 && longitude != 0;

  List<double> get asGeoJsonCooridnate => [longitude, latitude];

  GeoJsonFeatureBuilder toGeoJsonFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)..setGeometry(asGeoJsonCooridnate);
  }

  GeoJsonBuilder toGeoJsonBuilder() {
    return GeoJsonBuilder()..addFeature(toGeoJsonFeatureBuilder());
  }

  Map<String, dynamic> toGeoJsonMap() {
    return toGeoJsonBuilder().build();
  }

  /// Calculates the distance between the supplied coordinates in meters. The distance between the coordinates is
  /// calculated using the Haversine formula (see https://en.wikipedia.org/wiki/Haversine_formula).
  double to(LatLng other) => Geolocator.distanceBetween(latitude, longitude, other.latitude, other.longitude);
}
