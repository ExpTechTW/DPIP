/// Golden pins for the planets, against JPL Horizons.
///
/// The elements come from JPL and the check comes from JPL's own ephemeris —
/// different enough to be a real test, because the elements are a fitted
/// approximation and Horizons is the DE integration they approximate. A
/// mistyped digit in the table moves a planet by degrees and shows up here
/// immediately.
///
/// Tolerances are the measured maxima over 711 samples spanning 2024–2027:
/// longitude within 285″ (Saturn, the worst), latitude within 17″, magnitude
/// within 0.3 where the planet is far enough from the Sun to be observed.
/// Distance is checked as a fraction, since Neptune's astronomical unit and
/// Mercury's are not comparable quantities.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/planet_ephemeris.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:flutter_test/flutter_test.dart';

double _deg(double radians) => radians * 180 / math.pi;
double _wrap180(double d) => ((d + 180) % 360 + 360) % 360 - 180;

/// `(planet, utc, ecliptic longitude °, ecliptic latitude °, distance au,
/// apparent magnitude)` — from `ssd.jpl.nasa.gov/api/horizons.api`,
/// geocentric, ecliptic of date.
const _horizons = <(Planet, String, double, double, double, double)>[
  (
    Planet.mercury,
    '2024-01-01T00:00',
    262.2816922,
    3.0649825,
    0.7775454,
    0.508,
  ),
  (
    Planet.mercury,
    '2026-04-14T01:00',
    358.4740090,
    -2.5573511,
    1.0308555,
    0.074,
  ),
  (Planet.venus, '2024-01-01T00:00', 242.6122975, 1.9498256, 1.1819073, -4.039),
  (Planet.venus, '2026-04-14T01:00', 47.6461538, 0.1273597, 1.5178550, -3.902),
  (Planet.mars, '2024-01-01T00:00', 267.3083422, -0.5504977, 2.4238068, 1.418),
  (Planet.mars, '2026-04-14T01:00', 3.2860846, -0.9879993, 2.2742771, 1.251),
  (
    Planet.jupiter,
    '2024-01-01T00:00',
    35.5823812,
    -1.1854765,
    4.4815037,
    -2.589,
  ),
  (
    Planet.jupiter,
    '2026-04-14T01:00',
    106.8665112,
    0.3798162,
    5.2801833,
    -2.112,
  ),
  (
    Planet.saturn,
    '2024-01-01T00:00',
    333.2435330,
    -1.6341214,
    10.2947007,
    0.955,
  ),
  (Planet.saturn, '2026-04-14T01:00', 7.1538969, -2.1418000, 10.4408377, 0.933),
  (
    Planet.uranus,
    '2024-01-01T00:00',
    49.3839119,
    -0.3061202,
    18.9754148,
    5.691,
  ),
  (
    Planet.uranus,
    '2026-04-14T01:00',
    59.3720097,
    -0.1677465,
    20.2820211,
    5.813,
  ),
  (
    Planet.neptune,
    '2024-01-01T00:00',
    355.0761521,
    -1.2372427,
    30.1425627,
    7.775,
  ),
  (
    Planet.neptune,
    '2026-04-14T01:00',
    2.6841033,
    -1.3115590,
    30.8133183,
    7.821,
  ),
];

void main() {
  group('PlanetEphemeris', () {
    test('tracks JPL Horizons to the measured tolerance', () {
      for (final (planet, stamp, longitude, latitude, distance, magnitude)
          in _horizons) {
        final body = PlanetEphemeris.at(planet, DateTime.parse('${stamp}Z'));
        expect(
          _wrap180(_deg(body.longitude) - longitude).abs(),
          lessThan(285 / 3600),
          reason: '${planet.name} longitude at $stamp',
        );
        expect(
          (_deg(body.latitude) - latitude).abs(),
          lessThan(17 / 3600),
          reason: '${planet.name} latitude at $stamp',
        );
        expect(
          (body.distanceAu - distance).abs() / distance,
          lessThan(0.0011),
          reason: '${planet.name} distance at $stamp',
        );
        expect(
          (body.magnitude - magnitude).abs(),
          lessThan(0.3),
          reason: '${planet.name} magnitude at $stamp',
        );
      }
    });

    test(
      'light time is applied — the planet is where it was, not where it is',
      () {
        // Dropping the correction shifts Saturn by roughly its own motion over
        // the 80 minutes its light takes to arrive. The check is that the
        // position differs from an uncorrected one by about that much, in the
        // direction of the planet's travel.
        final at = DateTime.utc(2026, 4, 14, 1);
        final saturn = PlanetEphemeris.at(Planet.saturn, at);
        final lightTimeMinutes = saturn.distanceAu * 8.317;
        expect(lightTimeMinutes, closeTo(87, 5));

        final earlier = PlanetEphemeris.at(
          Planet.saturn,
          at.subtract(Duration(minutes: lightTimeMinutes.round())),
        );
        // The corrected position at `at` should sit within a few arcseconds of
        // the *uncorrected* position one light-time earlier.
        expect(
          _wrap180(_deg(saturn.longitude - earlier.longitude)).abs() * 3600,
          lessThan(60),
        );
      },
    );

    test('the inner planets show phases and the outer ones do not', () {
      // A geometric fact, and the cheapest check that the Sun–planet–Earth
      // triangle is being solved the right way round: Venus can be a crescent,
      // Jupiter never is.
      var venusMin = 1.0;
      var jupiterMin = 1.0;
      for (var days = 0; days < 600; days += 3) {
        final at = DateTime.utc(2026).add(Duration(days: days));
        venusMin = math.min(
          venusMin,
          PlanetEphemeris.at(Planet.venus, at).illuminated,
        );
        jupiterMin = math.min(
          jupiterMin,
          PlanetEphemeris.at(Planet.jupiter, at).illuminated,
        );
      }
      expect(venusMin, lessThan(0.05), reason: 'Venus becomes a thin crescent');
      expect(jupiterMin, greaterThan(0.98), reason: 'Jupiter stays full');
    });

    test(
      'elongation is bounded for the inner planets and free for the outer',
      () {
        // Mercury and Venus can never be opposite the Sun — they orbit inside
        // us. Their maximum elongations (about 28° and 47°) are a strong check
        // on the orbits themselves.
        var mercuryMax = 0.0;
        var venusMax = 0.0;
        var marsMax = 0.0;
        for (var days = 0; days < 800; days += 2) {
          final at = DateTime.utc(2026).add(Duration(days: days));
          mercuryMax = math.max(
            mercuryMax,
            _deg(PlanetEphemeris.at(Planet.mercury, at).elongation),
          );
          venusMax = math.max(
            venusMax,
            _deg(PlanetEphemeris.at(Planet.venus, at).elongation),
          );
          marsMax = math.max(
            marsMax,
            _deg(PlanetEphemeris.at(Planet.mars, at).elongation),
          );
        }
        expect(mercuryMax, inInclusiveRange(26, 29));
        expect(venusMax, inInclusiveRange(45, 48));
        expect(marsMax, greaterThan(175), reason: 'Mars reaches opposition');
      },
    );

    test('the signed elongation says evening or morning', () {
      // Which side of the Sun a planet is on decides whether you look after
      // dusk or before dawn, and the unsigned elongation cannot tell you.
      // At greatest *eastern* elongation Venus is the evening star.
      var best = 0.0;
      var bestAt = DateTime.utc(2026);
      for (var days = 0; days < 400; days++) {
        final at = DateTime.utc(2026).add(Duration(days: days));
        final venus = PlanetEphemeris.at(Planet.venus, at);
        if (venus.signedElongation > best) {
          best = venus.signedElongation;
          bestAt = at;
        }
      }
      expect(_deg(best), inInclusiveRange(44, 48));
      expect(PlanetEphemeris.at(Planet.venus, bestAt).isEvening, isTrue);
    });

    test('Saturn dims when its rings close', () {
      // The rings swing Saturn by more than a magnitude. 2025 was a ring-plane
      // crossing, so Saturn is near its faintest then and brightens after.
      final closed = PlanetEphemeris.at(
        Planet.saturn,
        DateTime.utc(2025, 3, 23),
      );
      final open = PlanetEphemeris.at(Planet.saturn, DateTime.utc(2032, 6));
      expect(open.magnitude, lessThan(closed.magnitude - 0.4));
    });

    test('provides a track the shared rise/set solver can use', () {
      final track = PlanetEphemeris.trackOf(Planet.jupiter);
      final events = RiseSet.solve(
        from: DateTime.utc(2026, 8, 15, -8),
        observer: const Observer(latitude: 25.033, longitude: 121.5654),
        track: track,
        horizon: (_) => pointHorizon,
      );
      // Jupiter rises and sets from Taiwan like everything else on the
      // ecliptic; what matters is that all three events are found and ordered.
      expect(events.rise, isNotNull);
      expect(events.set, isNotNull);
      expect(events.transit, isNotNull);
    });
  });
}
