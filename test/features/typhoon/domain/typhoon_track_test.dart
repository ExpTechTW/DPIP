/// A cyclone's full track — past fixes, current dynamics, and the forecast —
/// repeats the `t`/`lat`/`lon`/`pres`/`dir` wire-key renames across three
/// different fix shapes ([TrackFix], [TrackNow], and [TrackForecast], which
/// adds a `tau` lead time). [TrackNow.c15]/[TrackNow.c25] are `null` exactly
/// when the system is too weak to define that wind radius; a decoder that
/// defaulted a missing circle to a zero-radius [StormCircle] instead of
/// `null` would have the map draw a wind field for a system that has none.
library;

import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackFix', () {
    test('fromJson reads t/lat/lon/pres, toJson restores the wire keys', () {
      final json = <String, dynamic>{
        't': 1758000000,
        'lat': 23.5,
        'lon': 121.8,
        'wind': 45.5,
        'gust': 58.0,
        'pres': 955.0,
      };

      final fix = TrackFix.fromJson(json);

      expect(fix.time, 1758000000);
      expect(fix.latitude, 23.5);
      expect(fix.longitude, 121.8);
      expect(fix.wind, 45.5);
      expect(fix.gust, 58.0);
      expect(fix.pressure, 955.0);
      expect(fix.toJson(), json);
    });
  });

  group('TrackNow', () {
    test('fromJson reads dir/move and both storm circles', () {
      final json = <String, dynamic>{
        'speed': 18.0,
        'dir': 'WNW',
        'move': ['向西北西移動', 'moving WNW'],
        'c15': {
          'avg': 220.0,
          'ne': 250.0,
          'se': 260.0,
          'sw': 200.0,
          'nw': 180.0,
        },
        'c25': {'avg': 100.0, 'ne': 110.0, 'se': 120.0, 'sw': 90.0, 'nw': 80.0},
      };

      final now = TrackNow.fromJson(json);

      expect(now.speed, 18.0);
      expect(now.direction, 'WNW');
      expect(now.move, ['向西北西移動', 'moving WNW']);
      expect(now.c15?.avg, 220.0);
      expect(now.c25?.nw, 80.0);
      expect(now.toJson(), json);
    });

    test('a weak system has null circles, not a zero-radius placeholder', () {
      final now = TrackNow.fromJson(const {
        'speed': 8.0,
        'dir': 'N',
        'move': null,
        'c15': null,
        'c25': null,
      });

      expect(now.c15, isNull);
      expect(now.c25, isNull);
      expect(now.move, isNull);
    });
  });

  group('TrackForecast', () {
    test('fromJson reads the lead time and both probability radii', () {
      final json = <String, dynamic>{
        'tau': 24,
        't': 1758086400,
        'lat': 24.0,
        'lon': 121.0,
        'wind': 40.0,
        'gust': 52.0,
        'pres': 965.0,
        'speed': 15.0,
        'dir': 'NW',
        'r15': 200.0,
        'r70': 100.0,
        'state': ['減弱為輕度颱風', 'weakening to a mild typhoon'],
      };

      final forecast = TrackForecast.fromJson(json);

      expect(forecast.tau, 24);
      expect(forecast.time, 1758086400);
      expect(forecast.latitude, 24.0);
      expect(forecast.longitude, 121.0);
      expect(forecast.r15, 200.0);
      expect(forecast.r70, 100.0);
      expect(forecast.state, ['減弱為輕度颱風', 'weakening to a mild typhoon']);
      expect(forecast.toJson(), json);
    });
  });

  group('TyphoonTrack and TrackPayload', () {
    test(
      'fromJson assembles analysis, now and forecast; toJson round-trips',
      () {
        final fixJson = <String, dynamic>{
          't': 1758000000,
          'lat': 23.5,
          'lon': 121.8,
          'wind': 45.5,
          'gust': 58.0,
          'pres': 955.0,
        };
        final nowJson = <String, dynamic>{
          'speed': 18.0,
          'dir': 'WNW',
          'move': ['向西北西移動', 'moving WNW'],
          'c15': {
            'avg': 220.0,
            'ne': 250.0,
            'se': 260.0,
            'sw': 200.0,
            'nw': 180.0,
          },
          'c25': null,
        };
        final forecastJson = <String, dynamic>{
          'tau': 24,
          't': 1758086400,
          'lat': 24.0,
          'lon': 121.0,
          'wind': 40.0,
          'gust': 52.0,
          'pres': 965.0,
          'speed': 15.0,
          'dir': 'NW',
          'r15': 200.0,
          'r70': 100.0,
          'state': null,
        };
        final trackJson = <String, dynamic>{
          'name': 'HAISHEN',
          'cwaName': '海神',
          'year': 2026,
          'tdNo': '15',
          'tyNo': '13',
          'analysis': [fixJson],
          'now': nowJson,
          'forecast': [forecastJson],
        };

        final track = TyphoonTrack.fromJson(trackJson);

        expect(track.name, 'HAISHEN');
        expect(track.analysis.single.latitude, 23.5);
        expect(track.now?.direction, 'WNW');
        expect(track.forecast.single.tau, 24);
        expect(track.toJson(), trackJson);

        final payload = TrackPayload.fromJson({
          'updated': 1758000000,
          'cyclones': [trackJson],
        });
        expect(payload.updated, 1758000000);
        expect(payload.cyclones.single, track);
        expect(payload.toJson(), {
          'updated': 1758000000,
          'cyclones': [trackJson],
        });
      },
    );

    test('no active cyclones decodes to an empty track list', () {
      final payload = TrackPayload.fromJson(const {
        'updated': 1,
        'cyclones': <Map<String, dynamic>>[],
      });
      expect(payload.cyclones, isEmpty);
    });
  });
}
