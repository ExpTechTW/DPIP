import 'package:dpip/core/geo/town_directory.dart';

final class WidgetLocationCatalogLocation {
  const WidgetLocationCatalogLocation({
    required this.regionCode,
    required this.displayName,
    required this.administrativeAreaName,
    required this.latitude,
    required this.longitude,
  });

  final String regionCode;
  final String displayName;
  final String administrativeAreaName;
  final double latitude;
  final double longitude;

  Map<String, Object> toJson() {
    return {
      'regionCode': regionCode,
      'displayName': displayName,
      'administrativeAreaName': administrativeAreaName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

final class WidgetLocationCatalog {
  const WidgetLocationCatalog({
    this.schemaVersion = 1,
    required this.locations,
  });

  final int schemaVersion;
  final List<WidgetLocationCatalogLocation> locations;

  Map<String, Object> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'locations': [for (final location in locations) location.toJson()],
    };
  }
}

WidgetLocationCatalog createWidgetLocationCatalog({
  required List<String> savedCodes,
  required TownDirectory townDirectory,
}) {
  final locations = <WidgetLocationCatalogLocation>[];

  for (final code in savedCodes) {
    final town = townDirectory.byCode(code);

    if (town == null) continue;

    locations.add(
      WidgetLocationCatalogLocation(
        regionCode: town.code,
        displayName: town.townName,
        administrativeAreaName: town.cityName,
        latitude: town.lat,
        longitude: town.lng,
      ),
    );
  }

  return WidgetLocationCatalog(locations: locations);
}
