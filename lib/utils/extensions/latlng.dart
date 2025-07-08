import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

extension GeoJsonLatLng on LatLng {
  bool get isValid => latitude != 0 && longitude != 0;

  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point).setGeometry(toGeoJsonCoordinates());
  }

  double to(LatLng other) {
    final lat1 = latitude * pi / 180;
    final lat2 = other.latitude * pi / 180;
    final lon1 = longitude * pi / 180;
    final lon2 = other.longitude * pi / 180;

    final dlon = lon2 - lon1;
    final dlat = lat2 - lat1;
    final a = sin(dlat/2) * sin(dlat/2) + cos(lat1) * cos(lat2) * sin(dlon/2) * sin(dlon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    return 6371.0 * c;
  }
}
