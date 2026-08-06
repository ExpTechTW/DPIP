import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_overlay.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortenTyphoonTimeLabel', () {
    test('drops month and day leading zero', () {
      expect(shortenTyphoonTimeLabel('07月07日08時'), '7日08時');
      expect(shortenTyphoonTimeLabel('07月14日14時'), '14日14時');
      expect(shortenTyphoonTimeLabel('7日08時'), '7日08時');
      expect(shortenTyphoonTimeLabel('other'), 'other');
    });
  });

  group('asymmetricStormRing', () {
    test('is four constant-radius quarter-circles', () {
      const centre = LatLng(24, 121);
      const circle = StormCircle(avg: 100, ne: 120, se: 80, sw: 90, nw: 110);
      final ring = asymmetricStormRing(centre, circle, steps: 8);
      expect(ring.length, 9);
      expect(ring.first.latitude, closeTo(ring.last.latitude, 1e-9));
      double km(LatLng p) => centre.distanceTo(p) / 1000;
      expect(km(ring[0]), closeTo(120, 0.5));
      expect(km(ring[2]), closeTo(80, 0.5));
    });
  });

  group('forecastConeRing', () {
    test('builds convex hull from forecast r70 radii', () {
      const track = TyphoonTrack(
        name: '',
        year: 2026,
        tdNo: '15',
        analysis: [TrackFix(time: 1, latitude: 16.4, longitude: 118.4)],
        forecast: [
          TrackForecast(
            tau: 6,
            time: 2,
            latitude: 16.1,
            longitude: 118.2,
            r70: 50,
          ),
          TrackForecast(
            tau: 24,
            time: 4,
            latitude: 16.6,
            longitude: 121.8,
            r70: 150,
          ),
        ],
      );
      final cone = forecastConeRing(track);
      expect(cone.length, greaterThan(6));
      expect(cone.first.latitude, closeTo(cone.last.latitude, 1e-9));
    });
  });

  group('buildTyphoonOverlay', () {
    test('emits kinds from track + potential + probability', () {
      final pot = TyphoonPotential(
        tdNo: '1',
        name: 'X',
        past: const [LatLng(20, 120), LatLng(21, 121)],
        forecast: const [LatLng(21, 121), LatLng(22, 122)],
        cone: const [LatLng(20, 120), LatLng(22, 120), LatLng(22, 122)],
        circle: null,
        current: const LatLng(21, 121),
        points: const [
          ForecastPoint(label: '07月14日08時', latitude: 22, longitude: 122),
        ],
      );
      final prob = TyphoonProbability(
        updated: 1,
        cyclones: [
          CycloneProbability(
            tdNo: '1',
            levels: [
              ProbabilityLevel(
                p: 100,
                coords: const [
                  LatLng(20, 120),
                  LatLng(21, 120),
                  LatLng(21, 121),
                ],
              ),
            ],
          ),
        ],
      );
      final storm = TyphoonTrack(
        name: 'X',
        year: 2026,
        tdNo: '1',
        analysis: const [
          TrackFix(time: 1, latitude: 20, longitude: 120, wind: 15),
          TrackFix(time: 2, latitude: 21, longitude: 121, wind: 33),
        ],
        now: const TrackNow(
          c15: StormCircle(avg: 100, ne: 100, se: 100, sw: 100, nw: 100),
          c25: StormCircle(avg: 50, ne: 50, se: 50, sw: 50, nw: 50),
        ),
        forecast: const [
          TrackForecast(tau: 6, time: 3, latitude: 22, longitude: 122, r70: 80),
        ],
      );
      final fc = buildTyphoonOverlay(
        tracks: [storm],
        potentials: [pot],
        probability: prob,
        selectedKey: 'TD1',
        cyclones: const [
          TyphoonCyclone(
            name: 'X',
            year: 2026,
            tdNo: '1',
            time: 1,
            latitude: 21,
            longitude: 121,
          ),
        ],
      );
      final kinds = {
        for (final f in fc['features'] as List)
          (f as Map)['properties']['kind'] as String,
      };
      expect(
        kinds,
        containsAll([
          'past',
          'forecast',
          'cone',
          'current',
          'forecastPoint',
          'probability',
          'circle15',
          'circleAvg15',
          'circle25',
          'circleAvg25',
        ]),
      );
      final points = (fc['features'] as List).where(
        (f) => (f as Map)['properties']?['kind'] == 'forecastPoint',
      );
      expect(points, hasLength(1));
      expect((points.first as Map)['properties']['label'], '14日08時');
    });

    test('colours past from track wind; hull cone when no official cone', () {
      final dolphin = TyphoonTrack(
        name: 'DOLPHIN',
        cwaName: '白海豚',
        year: 2026,
        tdNo: '14',
        analysis: const [
          TrackFix(time: 1, latitude: 12.9, longitude: 179.8, wind: 15),
          TrackFix(time: 2, latitude: 20.0, longitude: 160.0, wind: 33),
          TrackFix(time: 3, latitude: 25.3, longitude: 141.9, wind: 45),
        ],
        forecast: const [
          TrackForecast(
            tau: 6,
            time: 4,
            latitude: 25.3,
            longitude: 140.7,
            r70: 40,
          ),
        ],
      );
      final td15 = TyphoonTrack(
        name: '',
        year: 2026,
        tdNo: '15',
        analysis: const [
          TrackFix(time: 1, latitude: 14.5, longitude: 126.0, wind: 15),
          TrackFix(time: 2, latitude: 16.4, longitude: 118.4, wind: 15),
        ],
        forecast: const [
          TrackForecast(
            tau: 6,
            time: 3,
            latitude: 16.1,
            longitude: 118.2,
            r70: 50,
          ),
          TrackForecast(
            tau: 24,
            time: 4,
            latitude: 16.6,
            longitude: 121.8,
            r70: 150,
          ),
        ],
      );
      final pot14 = TyphoonPotential(
        tdNo: '14',
        name: '白海豚',
        past: const [],
        forecast: const [],
        cone: const [
          LatLng(25.0, 141.0),
          LatLng(25.0, 142.0),
          LatLng(26.0, 142.0),
        ],
        circle: null,
        current: null,
        points: const [
          ForecastPoint(label: '08月05日14時', latitude: 25.3, longitude: 140.7),
        ],
      );

      final out = buildTyphoonOverlay(
        tracks: [dolphin, td15],
        potentials: [pot14],
        selectedKey: 'TD15',
        cyclones: [
          TyphoonCyclone(
            name: 'DOLPHIN',
            cwaName: '白海豚',
            year: 2026,
            tdNo: '14',
            time: 3,
            latitude: 25.3,
            longitude: 141.9,
          ),
          const TyphoonCyclone(
            name: '',
            year: 2026,
            tdNo: '15',
            time: 2,
            latitude: 16.4,
            longitude: 118.4,
          ),
        ],
      );

      final past = (out['features'] as List)
          .where((f) => (f as Map)['properties']?['kind'] == 'past')
          .toList();
      // DOLPHIN 2 segments + TD15 1 segment.
      expect(past, hasLength(3));
      for (final f in past) {
        expect((f as Map)['properties']['intensity'], isNotNull);
      }
      final dolphinPast = past.where(
        (f) => (f as Map)['properties']?['tdNo'] == '14',
      );
      expect(dolphinPast, hasLength(2));
      expect((dolphinPast.first as Map)['properties']['intensity'], 'moderate');

      final cones15 = (out['features'] as List).where((f) {
        final p = (f as Map)['properties'];
        return p?['kind'] == 'cone' && p?['tdNo'] == '15';
      });
      expect(cones15, hasLength(1));
      final ring15 =
          (((cones15.first as Map)['geometry'] as Map)['coordinates']
                  as List)[0]
              as List;
      expect(ring15.length, greaterThan(6));
      expect(ring15.first, ring15.last);

      final cones14 = (out['features'] as List).where((f) {
        final p = (f as Map)['properties'];
        return p?['kind'] == 'cone' && p?['tdNo'] == '14';
      });
      expect(cones14, hasLength(1));
      // Official potential cone (3 verts), not r70 hull.
      final ring14 =
          (((cones14.first as Map)['geometry'] as Map)['coordinates']
                  as List)[0]
              as List;
      expect(ring14.length, 3);

      final currents = (out['features'] as List).where(
        (f) => (f as Map)['properties']?['kind'] == 'current',
      );
      expect(currents, hasLength(2));
      final selected = currents.where(
        (f) => (f as Map)['properties']?['selected'] == 1,
      );
      expect(selected, hasLength(1));
      expect((selected.first as Map)['properties']['tdNo'], '15');
    });

    test('forecast points fall back to +Nh when potential has none', () {
      final track = TyphoonTrack(
        name: '',
        year: 2026,
        tdNo: '15',
        analysis: const [TrackFix(time: 1, latitude: 16.4, longitude: 118.4)],
        forecast: const [
          TrackForecast(tau: 6, time: 2, latitude: 16.1, longitude: 118.2),
          TrackForecast(tau: 24, time: 3, latitude: 16.6, longitude: 121.8),
        ],
      );
      final out = buildTyphoonOverlay(tracks: [track]);
      final points = (out['features'] as List)
          .where((f) => (f as Map)['properties']?['kind'] == 'forecastPoint')
          .toList();
      expect(points, hasLength(2));
      expect((points[0] as Map)['properties']['label'], '+6h');
      expect((points[1] as Map)['properties']['label'], '+24h');
    });
  });
}
