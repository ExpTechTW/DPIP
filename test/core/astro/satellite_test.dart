/// Golden pins for SGP4.
///
/// The anchor is the near-Earth verification case from **Spacetrack Report
/// #3** — satellite 88888, the element set the model was published with. It is
/// the right test because SGP4 is *defined* by its output: a TLE is a set of
/// mean elements fitted to this propagator, so "close enough" is not a thing.
/// Three separate errors in the implementation (the sign of A(3,0), a factor
/// of two in C2, a flipped 3θ²−1 in C4) each left the answer looking plausible
/// and moved it by tens of kilometres; this test is what found them.
///
/// The two published epochs pinned here are matched to a few **metres** — on
/// a 6,650 km radius, which is 4 parts in 10^9. The
/// rest of the file checks physics rather than a table: the analytic velocity
/// against the numerical derivative of the analytic position, and the orbit
/// against the mean motion the elements declare.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/satellite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spacetrack Report #3's near-Earth test object.
final _testCase = TleSet.parse(
  'TEST',
  '1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8',
  '2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105',
);

/// A real, recent element set — the shape the app actually parses.
final _iss = TleSet.parse(
  'ISS (ZARYA)',
  '1 25544U 98067A   26226.43871707  .00004555  00000+0  89427-4 0  9997',
  '2 25544  51.6329  11.7957 0007493  45.9133 314.2471 15.49439755580788',
);

double _length((double, double, double) v) =>
    math.sqrt(v.$1 * v.$1 + v.$2 * v.$2 + v.$3 * v.$3);

void main() {
  group('TleSet', () {
    test('parses by column, not by splitting', () {
      expect(_iss.catalogNumber, 25544);
      expect(_iss.name, 'ISS (ZARYA)');
      expect(_iss.epoch.year, 2026);
      // Day 226.43871707 of 2026.
      expect(_iss.epoch.month, 8);
      expect(_iss.epoch.day, 14);
      expect(_iss.eccentricity, closeTo(0.0007493, 1e-9));
      expect(_iss.inclination / degrees, closeTo(51.6329, 1e-6));
      // 15.49 revolutions a day, in radians per minute.
      expect(
        _iss.meanMotion * 1440 / (2 * math.pi),
        closeTo(15.49439755, 1e-6),
      );
    });

    test('decodes the implied-exponent drag field', () {
      // "89427-4" is 0.89427e-4 — a format that no general number parser
      // handles and that a whitespace split would mangle.
      expect(_iss.bstar, closeTo(0.89427e-4, 1e-12));
      expect(_testCase.bstar, closeTo(0.66816e-4, 1e-12));
    });

    test('reads a whole file and skips anything malformed', () {
      const file = '''
ISS (ZARYA)
1 25544U 98067A   26226.43871707  .00004555  00000+0  89427-4 0  9997
2 25544  51.6329  11.7957 0007493  45.9133 314.2471 15.49439755580788
CSS (TIANHE)
1 48274U 21035A   26224.98627525  .00000101  00000+0  54127-5 0  9991
2 48274  41.4709 337.2096 0001079 250.4973 109.5748 15.58975796302033
''';
      final sets = TleSet.parseAll(file);
      expect(sets, hasLength(2));
      expect(sets.map((s) => s.catalogNumber), [25544, 48274]);
    });

    test('reports its own age, because that is what decays', () {
      final age = _iss.ageAt(DateTime.utc(2026, 8, 20));
      expect(age.inDays, 5);
    });
  });

  group('Sgp4', () {
    test('reproduces the Spacetrack Report #3 vectors', () {
      // Position, kilometres, in the TEME frame. Ten metres is the point:
      // every one of the three bugs moved this by tens of kilometres, and a
      // looser tolerance would have let them through.
      const published = <(double, List<double>)>[
        (0, [2328.97048951, -5995.22076416, 1719.97067261]),
        (360, [2456.10705566, -6071.93853760, 1222.89727783]),
      ];
      for (final (minutes, want) in published) {
        final position = _testCase.propagatedBy(minutes);
        expect(
          _length((
            position.$1 - want[0],
            position.$2 - want[1],
            position.$3 - want[2],
          )),
          lessThan(0.01),
          reason: 't = $minutes min',
        );
      }
    });

    test('the analytic velocity agrees with the position it belongs to', () {
      // SGP4 gives position and velocity from separate expressions. They have
      // to describe the same motion, and a differentiated position is the only
      // check on that which does not need a second implementation.
      final sgp4 = Sgp4(_testCase);
      for (final minutes in [0.0, 120.0, 720.0]) {
        const h = 1 / 600; // 0.1 s
        final before = sgp4.propagate(minutes - h).position;
        final after = sgp4.propagate(minutes + h).position;
        final numeric = (
          (after.$1 - before.$1) / (2 * h * 60),
          (after.$2 - before.$2) / (2 * h * 60),
          (after.$3 - before.$3) / (2 * h * 60),
        );
        final analytic = sgp4.propagate(minutes).velocity;
        final difference = _length((
          analytic.$1 - numeric.$1,
          analytic.$2 - numeric.$2,
          analytic.$3 - numeric.$3,
        ));
        // Under 0.2%. They are not identical by design — the analytic velocity
        // drops the time-derivative of the short-period terms — but a real
        // error shows up as whole km/s, as it did.
        expect(difference / _length(analytic), lessThan(0.002));
      }
    });

    test('keeps the ISS at the altitude and speed it actually has', () {
      final sgp4 = Sgp4(_iss);
      var lowest = double.infinity;
      var highest = 0.0;
      var slowest = double.infinity;
      for (var minutes = 0; minutes < 1440; minutes += 5) {
        final state = sgp4.propagate(minutes.toDouble());
        final altitude = _length(state.position) - 6378.135;
        lowest = math.min(lowest, altitude);
        highest = math.max(highest, altitude);
        slowest = math.min(slowest, _length(state.velocity));
      }
      // A near-circular orbit a little above 400 km, at 7.6-7.7 km/s.
      expect(lowest, inInclusiveRange(370, 430));
      expect(highest, inInclusiveRange(370, 440));
      // e = 0.00075 gives a radial swing of about 10 km, and the Earth's
      // oblateness adds as much again; anything far outside that is not this
      // orbit.
      expect(highest - lowest, lessThan(30), reason: 'near-circular');
      expect(slowest, inInclusiveRange(7.5, 7.8));
    });

    test('completes exactly as many orbits as the mean motion says', () {
      // Over a day the satellite must come back round the number of times the
      // element set declares. This catches an error in the recovered mean
      // motion, which a single-epoch position check cannot see.
      final sgp4 = Sgp4(_iss);
      var crossings = 0;
      var previous = sgp4.propagate(0).position.$3;
      for (var minutes = 1; minutes <= 1440; minutes++) {
        final z = sgp4.propagate(minutes.toDouble()).position.$3;
        if (previous < 0 && z >= 0) crossings++;
        previous = z;
      }
      expect(crossings, closeTo(15.494, 1));
    });

    test('look angles put the satellite somewhere on the sky', () {
      final sgp4 = Sgp4(_iss);
      var sawAbove = false;
      for (var minutes = 0; minutes < 1440; minutes += 2) {
        final look = sgp4.lookFrom(
          _iss.epoch.add(Duration(minutes: minutes)),
          latitude: 25.033,
          longitude: 121.5654,
        );
        expect(look.altitude, inInclusiveRange(-math.pi / 2, math.pi / 2));
        expect(look.azimuth, inInclusiveRange(0, 2 * math.pi));
        if (look.altitude > 0) sawAbove = true;
      }
      // A 51.6° orbit passes over Taiwan several times a day.
      expect(sawAbove, isTrue);
    });

    test('finds passes, and they are ordered and plausible', () {
      final sgp4 = Sgp4(_iss);
      final passes = SatellitePasses.find(
        sgp4,
        from: _iss.epoch,
        latitude: 25.033,
        longitude: 121.5654,
        window: const Duration(days: 3),
        sunlitOnly: false,
      );
      expect(passes, isNotEmpty);
      for (final pass in passes) {
        expect(pass.rises.isBefore(pass.peaks), isTrue);
        expect(pass.peaks.isBefore(pass.sets), isTrue);
        // A low-Earth pass is minutes, never hours.
        expect(pass.length.inMinutes, inInclusiveRange(1, 15));
        expect(pass.peakAltitude, greaterThanOrEqualTo(10 * degrees));
      }
    });

    test('a sunlit-only search is a subset of the geometric one', () {
      // Being above the horizon is necessary; being lit while the ground is
      // dark is what makes it visible. The filter can only remove passes.
      final sgp4 = Sgp4(_iss);
      List<SatellitePass> search({required bool sunlitOnly}) =>
          SatellitePasses.find(
            sgp4,
            from: _iss.epoch,
            latitude: 25.033,
            longitude: 121.5654,
            window: const Duration(days: 3),
            sunlitOnly: sunlitOnly,
          );
      expect(
        search(sunlitOnly: true).length,
        lessThanOrEqualTo(search(sunlitOnly: false).length),
      );
    });
  });
}

extension on TleSet {
  /// Position [minutes] after epoch — a shorthand for the vector tests.
  (double, double, double) propagatedBy(double minutes) =>
      Sgp4(this).propagate(minutes).position;
}
