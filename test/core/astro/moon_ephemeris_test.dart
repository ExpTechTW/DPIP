/// Golden pins for the lunar ephemeris.
///
/// Two independent authorities, because "it looks about right" is how an
/// astronomy bug survives:
///
///   * **Meeus's own worked example 45.a** pins the *transcription* of the
///     periodic-term table. One mistyped row moves the answer by arcminutes,
///     and nothing else in the app would notice.
///   * **JPL Horizons** pins the *result* — the DE ephemeris the truncated
///     series is an approximation of. The samples below were taken from
///     `ssd.jpl.nasa.gov/api/horizons.api` (geocentric, ecliptic of date) and
///     include the closest perigee and furthest apogee of 2024–2027, where a
///     distance error would be largest.
///
/// The tolerances are the measured error over the full 1385-sample sweep, not
/// a number chosen to make the test pass: 37″ of longitude, 32″ of latitude,
/// 59 km of distance. Widening one means the series changed.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:flutter_test/flutter_test.dart';

const double _arcsecond = math.pi / 180 / 3600;

/// `(utc, ecliptic longitude °, ecliptic latitude °, distance km)`.
const _horizons = <(String, double, double, double)>[
  ('2024-01-01T00:00', 155.9922, 3.5675, 404634),
  ('2024-06-04T23:00', 54.3551, 3.2986, 371314),
  ('2024-11-07T22:00', 299.4705, -4.7423, 383280),
  ('2025-04-12T21:00', 201.6714, -2.1600, 405914),
  ('2025-09-15T20:00', 101.2139, 4.8697, 376702),
  ('2025-11-19T18:00', 231.8805, -4.5897, 406643), // furthest apogee in range
  ('2026-02-18T19:00', 346.0357, 0.6534, 379828),
  ('2026-07-24T18:00', 248.3680, -5.1564, 405125),
  ('2026-12-24T13:00', 99.5921, 3.4321, 356681), // closest perigee in range
  ('2026-12-27T17:00', 146.8894, -0.4926, 366736),
];

double _degrees(double radians) => radians * 180 / math.pi;

void main() {
  group('MoonEphemeris', () {
    test('reproduces Meeus worked example 45.a', () {
      // 1992 April 12, 0h TD. Meeus gets λ = 133.162659°, β = -3.229127°,
      // Δ = 368409.7 km. The test instant is UTC, so ΔT (~59 s in 1992) is
      // added back by the ephemeris itself — feeding it 0h UTC and expecting
      // the 0h TD answer would be off by 0.008°, which the tolerance excludes.
      final moon = MoonEphemeris.at(
        DateTime.utc(1992, 4, 12).subtract(const Duration(seconds: 59)),
      );
      expect(_degrees(moon.longitude), closeTo(133.162659, 0.001));
      expect(_degrees(moon.latitude), closeTo(-3.229127, 0.001));
      // Meeus evaluates all 60 rows; this keeps 35, which costs 12 km here.
      // The angles are unaffected at this tolerance — it is the distance terms
      // that are still contributing past row 35.
      expect(moon.distanceKm, closeTo(368409.7, 20));
      // Meeus's π for the same instant: 0°.991990.
      expect(_degrees(moon.parallax), closeTo(0.991990, 0.0001));
    });

    test('tracks JPL Horizons to the measured tolerance', () {
      for (final (stamp, longitude, latitude, distance) in _horizons) {
        final moon = MoonEphemeris.at(DateTime.parse('${stamp}Z'));
        expect(
          _degrees(moon.longitude),
          closeTo(longitude, 37 / 3600),
          reason: 'longitude at $stamp',
        );
        expect(
          _degrees(moon.latitude),
          closeTo(latitude, 32 / 3600),
          reason: 'latitude at $stamp',
        );
        expect(
          moon.distanceKm,
          closeTo(distance, 59),
          reason: 'distance at $stamp',
        );
      }
    });

    test('distance spans perigee to apogee, and nothing beyond', () {
      // A term dropped from the wrong column shows up here before anywhere
      // else: the swing is 14%, and a broken series either flattens it or
      // overshoots the physical range.
      var closest = double.infinity;
      var furthest = 0.0;
      for (var hours = 0; hours < 24 * 400; hours += 3) {
        final d = MoonEphemeris.at(
          DateTime.utc(2026).add(Duration(hours: hours)),
        ).distanceKm;
        closest = math.min(closest, d);
        furthest = math.max(furthest, d);
      }
      expect(closest, inInclusiveRange(356400, 358000));
      expect(furthest, inInclusiveRange(405500, 406800));
    });

    test('parallax and apparent size follow the distance', () {
      final perigee = MoonEphemeris.at(DateTime.utc(2026, 12, 24, 13));
      final apogee = MoonEphemeris.at(DateTime.utc(2025, 11, 19, 18));
      expect(_degrees(perigee.parallax) * 60, closeTo(61.5, 0.5));
      expect(_degrees(apogee.parallax) * 60, closeTo(53.9, 0.5));
      // The famous "supermoon" difference: about 14% wider.
      expect(
        perigee.angularDiameter / apogee.angularDiameter,
        closeTo(1.14, 0.01),
      );
    });

    test('the equatorial conversion is consistent with the ecliptic one', () {
      // Round-trip: back-project RA/Dec through the obliquity and the ecliptic
      // longitude has to reappear. Catches a swapped sine in the rotation,
      // which a rise/set test would only show as a few minutes of drift.
      final moon = MoonEphemeris.at(DateTime.utc(2026, 5, 3, 7));
      final equatorial = moon.equatorial;
      final obliquity =
          (23.439291 - 0.0130042 * moon.centuries) * math.pi / 180;
      final longitude = math.atan2(
        math.sin(equatorial.rightAscension) * math.cos(obliquity) +
            math.tan(equatorial.declination) * math.sin(obliquity),
        math.cos(equatorial.rightAscension),
      );
      expect(
        _degrees(turn(longitude) - moon.longitude).abs(),
        lessThan(1 / 3600),
      );
    });

    test('is continuous across the longitude wrap', () {
      // λ passes 360° once a month; a naive normalisation there would put a
      // step in the phase, which the page renders as the Moon jumping.
      var previous = MoonEphemeris.at(DateTime.utc(2026)).longitude;
      for (var hours = 1; hours < 24 * 60; hours++) {
        final current = MoonEphemeris.at(
          DateTime.utc(2026).add(Duration(hours: hours)),
        ).longitude;
        final step = turn(current - previous);
        expect(step, lessThan(1 * math.pi / 180), reason: 'step at $hours h');
        previous = current;
      }
    });

    test('turn normalises onto [0, 2π)', () {
      expect(turn(0), 0);
      expect(turn(-_arcsecond), closeTo(2 * math.pi - _arcsecond, 1e-12));
      expect(turn(7 * math.pi), closeTo(math.pi, 1e-12));
    });
  });
}
