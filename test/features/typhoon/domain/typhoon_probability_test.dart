/// Storm-wind-circle strike-probability contours. `coords` comes from
/// `latLngsFromPairs`, which reverses GeoJSON's `[lng, lat]` pairs into
/// [LatLng]'s own `(lat, lng)` order — get that reversal backwards and every
/// probability contour on the map is mirrored across the equator/prime
/// meridian, which for Taiwan lands the whole polygon in the ocean rather than
/// failing loudly. [CycloneProbability.tdNo] is blank-trimmed because CWA
/// sometimes sends `"tdNo": " "` instead of omitting the field once a system
/// has been named; an untrimmed value would read as "present" everywhere a
/// caller checks for null.
library;

import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProbabilityLevel.decode', () {
    test('reads coords as (lat, lng), not the wire (lng, lat)', () {
      final level = ProbabilityLevel.decode({
        'p': 40,
        'coords': [
          [121.5, 25.0],
          [122.0, 25.5],
        ],
      });

      expect(level.p, 40);
      expect(level.coords, hasLength(2));
      expect(level.coords[0].latitude, 25.0);
      expect(level.coords[0].longitude, 121.5);
      expect(level.coords[1].latitude, 25.5);
      expect(level.coords[1].longitude, 122.0);
    });

    test('a contour with no points decodes to an empty coord list', () {
      final level = ProbabilityLevel.decode(const {'p': 70, 'coords': []});
      expect(level.coords, isEmpty);
    });
  });

  group('CycloneProbability.decode', () {
    test('assembles every probability level for the storm', () {
      final cyclone = CycloneProbability.decode({
        'tdNo': '15',
        'levels': [
          {
            'p': 70,
            'coords': [
              [121.0, 24.0],
            ],
          },
          {
            'p': 40,
            'coords': [
              [122.0, 25.0],
            ],
          },
        ],
      });

      expect(cyclone.tdNo, '15');
      expect(cyclone.levels, hasLength(2));
      expect(cyclone.levels[0].p, 70);
      expect(cyclone.levels[1].p, 40);
    });

    test(
      'a blank tdNo (CWA sends " " instead of omitting it) reads as null',
      () {
        final cyclone = CycloneProbability.decode(const {
          'tdNo': ' ',
          'levels': [],
        });
        expect(cyclone.tdNo, isNull);
      },
    );

    test('a missing levels list decodes to zero levels, not a throw', () {
      final cyclone = CycloneProbability.decode(const {'tdNo': '15'});
      expect(cyclone.levels, isEmpty);
    });
  });

  group('TyphoonProbability.decode', () {
    test('decodes updated plus every cyclone entry', () {
      final probability = TyphoonProbability.decode({
        'updated': 1758000000,
        'cyclones': [
          {
            'tdNo': '15',
            'levels': [
              {
                'p': 70,
                'coords': [
                  [121.0, 24.0],
                ],
              },
            ],
          },
        ],
      });

      expect(probability.updated, 1758000000);
      expect(probability.cyclones, hasLength(1));
      expect(probability.cyclones.single.tdNo, '15');
    });

    test('an empty payload defaults updated to 0 and cyclones to empty', () {
      final probability = TyphoonProbability.decode(const {});
      expect(probability.updated, 0);
      expect(probability.cyclones, isEmpty);
    });

    test('a non-map cyclone entry is skipped instead of failing the batch', () {
      final probability = TyphoonProbability.decode({
        'updated': 1,
        'cyclones': [
          'not-a-cyclone',
          {'tdNo': '16', 'levels': <Map<String, dynamic>>[]},
        ],
      });

      expect(probability.cyclones, hasLength(1));
      expect(probability.cyclones.single.tdNo, '16');
    });
  });
}
