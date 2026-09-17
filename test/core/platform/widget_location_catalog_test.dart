import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/widget_location_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final townDirectory = TownDirectory.fromJson({
    '407': {
      'city': '臺中',
      'town': '西屯',
      'lat': 24.1658213,
      'lng': 120.6336717,
      'cityLevel': '市',
      'townLevel': '區',
    },
    '700': {
      'city': '臺南',
      'town': '中西',
      'lat': 22.994821,
      'lng': 120.196452,
      'cityLevel': '市',
      'townLevel': '區',
    },
  });

  group('createWidgetLocationCatalog', () {
    test('projects saved region codes in order', () {
      final catalog = createWidgetLocationCatalog(
        savedCodes: ['407', '700'],
        townDirectory: townDirectory,
      );

      expect(catalog.schemaVersion, 1);
      expect(catalog.locations, hasLength(2));

      expect(catalog.locations[0].regionCode, '407');
      expect(catalog.locations[0].displayName, '西屯區');
      expect(catalog.locations[0].administrativeAreaName, '臺中市');
      expect(catalog.locations[0].latitude, 24.1658213);
      expect(catalog.locations[0].longitude, 120.6336717);

      expect(catalog.locations[1].regionCode, '700');
      expect(catalog.locations[1].displayName, '中西區');
      expect(catalog.locations[1].administrativeAreaName, '臺南市');
    });

    test('omits unresolved codes while preserving resolved order', () {
      final catalog = createWidgetLocationCatalog(
        savedCodes: ['407', '999', '700'],
        townDirectory: townDirectory,
      );

      expect(
        catalog.locations.map((location) => location.regionCode).toList(),
        ['407', '700'],
      );
    });

    test('serializes the exact widget location catalog contract', () {
      final catalog = createWidgetLocationCatalog(
        savedCodes: ['407'],
        townDirectory: townDirectory,
      );

      expect(catalog.toJson(), {
        'schemaVersion': 1,
        'locations': [
          {
            'regionCode': '407',
            'displayName': '西屯區',
            'administrativeAreaName': '臺中市',
            'latitude': 24.1658213,
            'longitude': 120.6336717,
          },
        ],
      });
    });

    test('serializes an empty saved-location catalog', () {
      final catalog = createWidgetLocationCatalog(
        savedCodes: const [],
        townDirectory: townDirectory,
      );

      expect(catalog.toJson(), {'schemaVersion': 1, 'locations': <Object>[]});
    });
  });
}
