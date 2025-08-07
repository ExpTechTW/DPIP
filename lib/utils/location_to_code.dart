class GeoJsonProperties {
  final String town;
  final String county;
  final String name;
  final int code;

  GeoJsonProperties({required this.town, required this.county, required this.name, required this.code});

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
  GeoJsonHelper._();

  static Map<String, dynamic>? _$geoJsonData;

  static GeoJsonProperties? checkPointInPolygons(double lat, double lng) {
    if (_$geoJsonData == null) return null;
  }
}
