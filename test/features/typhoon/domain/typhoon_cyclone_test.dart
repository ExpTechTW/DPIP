/// The active-cyclone index — one flat fix per storm, keyed by the same
/// `t`/`lat`/`lon`/`pres`/`dir` wire renames used across every other typhoon
/// dataset. Unlike [TyphoonProbability]/[WarningPayload]/[TrackPayload], whose
/// payload wrappers all tolerate a missing list, [CycloneIndex.cyclones] is a
/// plain required cast with no fallback — a response that omits `cyclones`
/// entirely throws instead of degrading to an empty index. That is a real
/// difference in how strict this one wire contract is, so it is pinned down
/// here rather than assumed to match its siblings.
library;

import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TyphoonCyclone', () {
    test('fromJson reads every renamed wire key, toJson restores them', () {
      final json = <String, dynamic>{
        'name': 'HAISHEN',
        'cwaName': '海神',
        'year': 2026,
        'tdNo': '15',
        'tyNo': '13',
        't': 1758000000,
        'lat': 23.5,
        'lon': 121.8,
        'wind': 45.5,
        'gust': 58.0,
        'pres': 955.0,
        'speed': 18.0,
        'dir': 'WNW',
      };

      final cyclone = TyphoonCyclone.fromJson(json);

      expect(cyclone.name, 'HAISHEN');
      expect(cyclone.cwaName, '海神');
      expect(cyclone.year, 2026);
      expect(cyclone.tdNo, '15');
      expect(cyclone.tyNo, '13');
      expect(cyclone.time, 1758000000);
      expect(cyclone.latitude, 23.5);
      expect(cyclone.longitude, 121.8);
      expect(cyclone.wind, 45.5);
      expect(cyclone.gust, 58.0);
      expect(cyclone.pressure, 955.0);
      expect(cyclone.speed, 18.0);
      expect(cyclone.direction, 'WNW');
      expect(cyclone.toJson(), json);
    });

    test('an unnamed system has null optional fields, not a -99 sentinel', () {
      final cyclone = TyphoonCyclone.fromJson(const {
        'name': 'INVEST',
        'cwaName': null,
        'year': 2026,
        'tdNo': null,
        'tyNo': null,
        't': 1758000000,
        'lat': 20.0,
        'lon': 130.0,
        'wind': null,
        'gust': null,
        'pres': null,
        'speed': null,
        'dir': null,
      });

      expect(cyclone.tdNo, isNull);
      expect(cyclone.wind, isNull);
      expect(cyclone.direction, isNull);
    });
  });

  group('CycloneIndex', () {
    test('fromJson/toJson round-trips the updated stamp and every cyclone', () {
      final cycloneJson = <String, dynamic>{
        'name': 'HAISHEN',
        'cwaName': '海神',
        'year': 2026,
        'tdNo': '15',
        'tyNo': '13',
        't': 1758000000,
        'lat': 23.5,
        'lon': 121.8,
        'wind': 45.5,
        'gust': 58.0,
        'pres': 955.0,
        'speed': 18.0,
        'dir': 'WNW',
      };
      final json = <String, dynamic>{
        'updated': 1758000000,
        'cyclones': [cycloneJson],
      };

      final index = CycloneIndex.fromJson(json);

      expect(index.updated, 1758000000);
      expect(index.cyclones, hasLength(1));
      expect(index.cyclones.single.name, 'HAISHEN');
      expect(index.toJson(), json);
    });

    test('an explicit empty list decodes to zero cyclones', () {
      final index = CycloneIndex.fromJson(const {
        'updated': 1,
        'cyclones': <Map<String, dynamic>>[],
      });
      expect(index.cyclones, isEmpty);
    });

    test('an omitted cyclones key throws rather than degrading to empty', () {
      expect(
        () => CycloneIndex.fromJson(const {'updated': 1}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
