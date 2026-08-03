import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_overlay.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asymmetricStormRing', () {
    test('closes and uses quadrant radii', () {
      const centre = LatLng(24, 121);
      const circle = StormCircle(avg: 100, ne: 120, se: 80, sw: 90, nw: 110);
      final ring = asymmetricStormRing(centre, circle, steps: 8);
      expect(ring.length, 9);
      expect(ring.first.latitude, closeTo(ring.last.latitude, 1e-9));
      expect(ring.first.longitude, closeTo(ring.last.longitude, 1e-9));
      // Due north samples the NE–NW blend → farther than SE.
      final north = ring[0];
      final south = ring[4];
      final dN = centre.distanceTo(north);
      final dS = centre.distanceTo(south);
      expect(dN, greaterThan(dS));
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
      final track = TrackPayload(
        updated: 1,
        cyclones: [
          TyphoonTrack(
            name: 'X',
            year: 2026,
            analysis: const [
              TrackFix(time: 1, latitude: 21, longitude: 121),
            ],
            now: const TrackNow(
              c15: StormCircle(avg: 100, ne: 100, se: 100, sw: 100, nw: 100),
              c25: StormCircle(avg: 50, ne: 50, se: 50, sw: 50, nw: 50),
            ),
            forecast: const [],
          ),
        ],
      );
      final fc = typhoonFeatureCollection(
        potential: pot,
        probability: prob,
        track: track,
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
          'circle25',
        ]),
      );
    });
  });
}
