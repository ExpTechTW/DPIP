import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class GeoJsonProperties {
  final String town;
  final String county;
  final String name;
  final int code;

  GeoJsonProperties({
    required this.town,
    required this.county,
    required this.name,
    required this.code,
  });

  factory GeoJsonProperties.fromJson(Map<String, dynamic> json) {
    return GeoJsonProperties(
      town: json['TOWN'] as String,
      county: json['COUNTY'] as String,
      name: json['NAME'] as String,
      code: json['CODE'] as int,
    );
  }

  @override
  String toString() {
    return 'GeoJsonProperties(town: $town, county: $county, name: $name, code: $code)';
  }
}

class GeoJsonHelper {
  static Map<String, dynamic>? _geoJsonData;

  static Future<void> loadGeoJson(String geojsonAssetPath) async {
    final String geojsonStr = await rootBundle.loadString(geojsonAssetPath);
    _geoJsonData = json.decode(geojsonStr);
  }

  static GeoJsonProperties? checkPointInPolygons(double lat, double lng) {
    if (_geoJsonData == null) return null;
    for (final feature in _geoJsonData!['features']) {
      if (feature['geometry']['type'] == 'Polygon' || feature['geometry']['type'] == 'MultiPolygon') {
        List<List<List<double>>> polygons = _getPolygons(feature['geometry']);

        for (final polygon in polygons) {
          if (_isPointInPolygon(lat, lng, polygon)) {
            return GeoJsonProperties.fromJson(feature['properties']);
          }
        }
      }
    }
    return null;
  }

  static List<List<List<double>>> _getPolygons(Map<String, dynamic> geometry) {
    List<List<List<double>>> polygons = [];

    if (geometry['type'] == 'Polygon') {
      polygons.add(_convertToDoubleList(geometry['coordinates'][0]));
    } else if (geometry['type'] == 'MultiPolygon') {
      for (var polygon in geometry['coordinates']) {
        polygons.add(_convertToDoubleList(polygon[0]));
      }
    }

    return polygons;
  }

  static List<List<double>> _convertToDoubleList(List<dynamic> coordinates) {
    return coordinates.map<List<double>>((coord) {
      if (coord is List) {
        return coord.map<double>((e) => e is num ? e.toDouble() : 0.0).toList();
      } else {
        return <double>[0.0, 0.0];
      }
    }).toList();
  }

  static bool _isPointInPolygon(double lat, double lng, List<List<double>> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      double xi = polygon[i][0], yi = polygon[i][1];
      double xj = polygon[j][0], yj = polygon[j][1];

      bool intersect = ((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) isInside = !isInside;

      j = i;
    }
    return isInside;
  }
}
