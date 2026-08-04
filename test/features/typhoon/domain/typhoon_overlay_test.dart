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
      // 2 samples × 4 quadrants + close.
      expect(ring.length, 9);
      expect(ring.first.latitude, closeTo(ring.last.latitude, 1e-9));
      expect(ring.first.longitude, closeTo(ring.last.longitude, 1e-9));
      // distanceTo is metres; storm radii are km.
      double km(LatLng p) => centre.distanceTo(p) / 1000;
      // Bearing 0° and 45° both use NE = 120 (not a lerp toward SE).
      expect(km(ring[0]), closeTo(120, 0.5));
      expect(km(ring[1]), closeTo(120, 0.5));
      // Bearing 90° starts SE = 80.
      expect(km(ring[2]), closeTo(80, 0.5));
      expect(km(ring[4]), closeTo(90, 0.5)); // SW @ 180°
    });
  });

  group('pastTrackSegments', () {
    test('colours each segment by destination wind (CWA)', () {
      final segs = pastTrackSegments(const [
        TrackFix(time: 1, latitude: 20, longitude: 120, wind: 10),
        TrackFix(time: 2, latitude: 21, longitude: 121, wind: 20),
        TrackFix(time: 3, latitude: 22, longitude: 122, wind: 40),
        TrackFix(time: 4, latitude: 23, longitude: 123, wind: 55),
      ]);
      expect(segs, hasLength(3));
      expect(segs[0]['properties']['intensity'], 'mild');
      expect(segs[1]['properties']['intensity'], 'moderate');
      expect(segs[2]['properties']['intensity'], 'intense');
    });
  });

  group('forecastConeRing', () {
    test('builds an envelope from forecast r70 radii', () {
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
            tau: 12,
            time: 3,
            latitude: 16.0,
            longitude: 118.0,
            r70: 100,
          ),
          TrackForecast(
            tau: 24,
            time: 4,
            latitude: 16.2,
            longitude: 119.0,
            r70: 150,
          ),
        ],
      );
      final cone = forecastConeRing(track);
      expect(cone.length, greaterThan(6));
      expect(cone.first.latitude, closeTo(cone.last.latitude, 1e-9));
      expect(cone.first.longitude, closeTo(cone.last.longitude, 1e-9));
    });

    test('returns empty when no r70 is present', () {
      const track = TyphoonTrack(
        name: 'X',
        year: 2026,
        analysis: [TrackFix(time: 1, latitude: 20, longitude: 120)],
        forecast: [
          TrackForecast(tau: 6, time: 2, latitude: 21, longitude: 121),
        ],
      );
      expect(forecastConeRing(track), isEmpty);
    });
  });

  group('typhoonFeatureCollection', () {
    test('tags kinds from potential + probability + track circles', () {
      final pot = TyphoonPotential(
        updated: 1,
        name: 'X',
        past: const [LatLng(20, 120), LatLng(21, 121)],
        forecast: const [LatLng(21, 121), LatLng(22, 122)],
        cone: const [LatLng(20, 120), LatLng(22, 120), LatLng(22, 122)],
        circle: null,
        current: const LatLng(21, 121),
        points: const [
          ForecastPoint(label: 't1', latitude: 22, longitude: 122),
        ],
      );
      final prob = TyphoonProbability(
        updated: 1,
        levels: [
          ProbabilityLevel(
            p: 100,
            coords: const [LatLng(20, 120), LatLng(21, 120), LatLng(21, 121)],
          ),
        ],
      );
      final storm = TyphoonTrack(
        name: 'X',
        year: 2026,
        analysis: const [TrackFix(time: 1, latitude: 21, longitude: 121)],
        now: const TrackNow(
          c15: StormCircle(avg: 100, ne: 100, se: 100, sw: 100, nw: 100),
          c25: StormCircle(avg: 50, ne: 50, se: 50, sw: 50, nw: 50),
        ),
        forecast: const [],
      );
      final fc = typhoonFeatureCollection(
        potential: pot,
        probability: prob,
        selected: storm,
        cyclones: const [
          TyphoonCyclone(
            name: 'X',
            year: 2026,
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
      final c25 =
          (fc['features'] as List).firstWhere(
                (f) => (f as Map)['properties']?['kind'] == 'circle25',
              )
              as Map;
      expect(c25['geometry']?['type'], 'Polygon');
      final avg25 =
          (fc['features'] as List).firstWhere(
                (f) => (f as Map)['properties']?['kind'] == 'circleAvg25',
              )
              as Map;
      expect(avg25['geometry']?['type'], 'LineString');
    });
  });

  group('augmentTyphoonGeojson', () {
    test('rebuilds asymmetric storm circles from track now', () {
      final geo = <String, dynamic>{
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'kind': 'circle15'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [120.0, 23.0],
                  [122.0, 23.0],
                  [122.0, 25.0],
                  [120.0, 25.0],
                  [120.0, 23.0],
                ],
              ],
            },
          },
        ],
      };
      final storm = TyphoonTrack(
        name: 'X',
        year: 2026,
        tdNo: '1',
        analysis: const [TrackFix(time: 1, latitude: 24, longitude: 121)],
        now: const TrackNow(
          c15: StormCircle(avg: 100, ne: 140, se: 80, sw: 90, nw: 110),
        ),
        forecast: const [],
      );
      final out = augmentTyphoonGeojson(geo, selected: storm, tracks: [storm]);
      final c15 = (out['features'] as List).where(
        (f) => (f as Map)['properties']?['kind'] == 'circle15',
      );
      expect(c15.length, 1);
      final ring =
          (((c15.first as Map)['geometry'] as Map)['coordinates'] as List)[0]
              as List;
      expect(ring.length, greaterThan(5));
      final north = ring[0] as List;
      final south = ring[ring.length ~/ 2] as List;
      final dN = (north[1] as num) - 24.0;
      final dS = 24.0 - (south[1] as num);
      expect(dN.abs(), greaterThan(dS.abs()));
    });

    test('draws past, forecast, and r70 cone for every cyclone', () {
      final geo = <String, dynamic>{
        'type': 'FeatureCollection',
        'features': [
          // Server mash-up: single past/forecast/cone for one storm only.
          {
            'type': 'Feature',
            'properties': {'kind': 'past'},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [141.9, 25.3],
                [140.0, 25.0],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'kind': 'forecast'},
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [141.9, 25.3],
                [130.0, 27.0],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'kind': 'cone'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [141.0, 25.0],
                  [142.0, 25.0],
                  [142.0, 26.0],
                  [141.0, 25.0],
                ],
              ],
            },
          },
          {
            'type': 'Feature',
            'properties': {'kind': 'probability', 'p': 100},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [120.0, 20.0],
                  [121.0, 20.0],
                  [121.0, 21.0],
                  [120.0, 20.0],
                ],
              ],
            },
          },
        ],
      };
      // Selected is the unnamed TD nearest Taiwan — previously this wiped
      // DOLPHIN's past and never drew TD15's cone.
      final dolphin = TyphoonTrack(
        name: 'DOLPHIN',
        cwaName: '白海豚',
        year: 2026,
        tdNo: '14',
        analysis: const [
          TrackFix(time: 1, latitude: 12.9, longitude: 179.8, wind: 15),
          TrackFix(time: 2, latitude: 25.3, longitude: 141.9, wind: 45),
        ],
        now: const TrackNow(
          c15: StormCircle(avg: 150, ne: 160, se: 140, sw: 130, nw: 150),
          c25: StormCircle(avg: 50, ne: 55, se: 45, sw: 40, nw: 50),
        ),
        forecast: const [
          TrackForecast(
            tau: 6,
            time: 3,
            latitude: 25.3,
            longitude: 140.7,
            r70: 40,
          ),
          TrackForecast(
            tau: 24,
            time: 4,
            latitude: 25.5,
            longitude: 138.0,
            r70: 110,
          ),
        ],
      );
      final td15 = TyphoonTrack(
        name: '',
        cwaName: '',
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
      final out = augmentTyphoonGeojson(
        geo,
        selected: td15,
        tracks: [dolphin, td15],
        cyclones: const [
          TyphoonCyclone(
            name: 'DOLPHIN',
            cwaName: '白海豚',
            year: 2026,
            tdNo: '14',
            time: 2,
            latitude: 25.3,
            longitude: 141.9,
          ),
          TyphoonCyclone(
            name: '',
            cwaName: '',
            year: 2026,
            tdNo: '15',
            time: 2,
            latitude: 16.4,
            longitude: 118.4,
          ),
        ],
      );
      final features = out['features'] as List;

      int countKind(String kind) => features
          .where((f) => (f as Map)['properties']?['kind'] == kind)
          .length;

      // Both storms' past segments (1 each from 2 analysis fixes).
      expect(countKind('past'), 2);
      // Both storms' forecast lines.
      expect(countKind('forecast'), 2);
      // Both storms' r70 cones.
      expect(countKind('cone'), 2);
      // DOLPHIN has L7+L10; TD15 has neither.
      expect(countKind('circle15'), 1);
      expect(countKind('circle25'), 1);
      // Probability kept from server.
      expect(countKind('probability'), 1);
      // Both centres injected.
      expect(countKind('current'), 2);

      final td15Points = features.where((f) {
        final props = (f as Map)['properties'];
        return props?['kind'] == 'forecastPoint' && props?['cyclone'] == 'TD15';
      });
      expect(td15Points.length, 2);
      final dolphinPoints = features.where((f) {
        final props = (f as Map)['properties'];
        return props?['kind'] == 'forecastPoint' && props?['cyclone'] == 'TD14';
      });
      expect(dolphinPoints.length, 2);
    });
  });
}
