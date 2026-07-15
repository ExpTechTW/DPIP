import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('typhoonGeojsonBounds', () {
    test('spans every coordinate across Point, LineString and Polygon', () {
      final geo = <String, dynamic>{
        'type': 'FeatureCollection',
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [121.0, 23.0],
            },
          },
          {
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [120.0, 22.0],
                [122.0, 24.0],
              ],
            },
          },
          {
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [119.5, 21.5],
                  [123.0, 25.0],
                  [120.0, 22.0],
                ],
              ],
            },
          },
        ],
      };
      final bounds = typhoonGeojsonBounds(geo)!;
      expect(bounds.southwest.longitude, closeTo(119.5, 1e-9));
      expect(bounds.southwest.latitude, closeTo(21.5, 1e-9));
      expect(bounds.northeast.longitude, closeTo(123.0, 1e-9));
      expect(bounds.northeast.latitude, closeTo(25.0, 1e-9));
    });

    test('returns null for an empty or feature-less collection', () {
      expect(
        typhoonGeojsonBounds(<String, dynamic>{
          'type': 'FeatureCollection',
          'features': <dynamic>[],
        }),
        isNull,
      );
      expect(
        typhoonGeojsonBounds(<String, dynamic>{'type': 'FeatureCollection'}),
        isNull,
      );
    });
  });
}
