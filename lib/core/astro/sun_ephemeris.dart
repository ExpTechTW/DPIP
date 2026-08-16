/// Where the Sun is — the other half of every question on this page.
///
/// The Sun sets the phase of the Moon, the dates of the solar terms, the
/// length of the day and the depth of the night, so it is computed once here
/// and read everywhere, exactly as the Moon is. Meeus ch. 24 (low precision):
/// closed form, ~0.01° in longitude, which is a hundredth of the Sun's own
/// diameter and two orders finer than a rise time can be defined to.
///
/// **Measured** against JPL Horizons over 2024–2027 in `test/core/astro/`.
///
/// It matters beyond stargazing: civil twilight is when outdoor work stops
/// needing light, which is the number an evacuation or a search is planned
/// against.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';

/// One astronomical unit in kilometres (IAU 2012 definition).
const double astronomicalUnitKm = 149597870.7;

/// The Sun's radius, km — turns distance into apparent size.
const double _sunRadiusKm = 695700;

/// The Sun's geocentric position at one instant.
class SunEphemeris {
  const SunEphemeris({
    required this.longitude,
    required this.distanceKm,
    required this.meanAnomaly,
    required this.meanLongitude,
    required this.centuries,
  });

  /// Apparent geocentric ecliptic longitude λ of date, radians. Latitude is
  /// under 1″ and is taken as zero — the ecliptic is, by definition, the
  /// Sun's own path.
  final double longitude;

  /// Earth–Sun distance, kilometres.
  final double distanceKm;

  /// The Sun's mean anomaly M, radians — kept because the equation of time
  /// and the seasons both want it and it is already computed.
  final double meanAnomaly;

  /// Geometric mean longitude L₀, radians.
  final double meanLongitude;

  /// Julian centuries of Terrestrial Time from J2000.0.
  final double centuries;

  /// The Sun at [utc].
  factory SunEphemeris.at(DateTime utc) =>
      SunEphemeris.atCenturies(julianCenturies(utc));

  /// The Sun at [t] Julian centuries TT — the form callers that already have
  /// the time argument use, so it is never recomputed.
  factory SunEphemeris.atCenturies(double t) {
    final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
    final m = (357.52911 + 35999.05029 * t - 0.0001537 * t * t) * degrees;
    final eccentricity = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
    // Equation of the centre: the correction from a circular orbit to the
    // real elliptical one, which is why the Sun runs fast in January.
    final centre =
        (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m) +
        (0.019993 - 0.000101 * t) * math.sin(2 * m) +
        0.000289 * math.sin(3 * m);
    final trueLongitude = l0 + centre;
    final trueAnomaly = m + centre * degrees;
    final radiusVector =
        1.000001018 *
        (1 - eccentricity * eccentricity) /
        (1 + eccentricity * math.cos(trueAnomaly));
    // Apparent longitude: the aberration of light (−20.5″) and the nutation
    // in longitude, together about 0.006°.
    final node = (125.04 - 1934.136 * t) * degrees;
    final apparent = trueLongitude - 0.00569 - 0.00478 * math.sin(node);

    return SunEphemeris(
      longitude: turn(apparent * degrees),
      distanceKm: radiusVector * astronomicalUnitKm,
      meanAnomaly: turn(m),
      meanLongitude: turn(l0 * degrees),
      centuries: t,
    );
  }

  /// Equatorial coordinates of date.
  Equatorial get equatorial => Equatorial.fromEcliptic(
    longitude: longitude,
    latitude: 0,
    obliquity: meanObliquity(centuries),
    distanceKm: distanceKm,
  );

  /// Apparent angular diameter, radians — 31.5′ in July, 32.5′ in January.
  double get angularDiameter => 2 * math.asin(_sunRadiusKm / distanceKm);

  /// Apparent solar time minus mean solar time — the **equation of time**
  /// (Meeus 28.3), the ±16-minute swing that makes a sundial disagree with a
  /// clock and draws the analemma.
  ///
  /// Two causes, both visible in the terms: the Earth's orbit is elliptical
  /// (so the Sun's apparent motion is uneven) and its axis is tilted (so that
  /// motion projects unevenly onto the equator).
  Duration get equationOfTime {
    final y = math.pow(math.tan(meanObliquity(centuries) / 2), 2).toDouble();
    final eccentricity =
        0.016708634 -
        0.000042037 * centuries -
        0.0000001267 * centuries * centuries;
    final value =
        y * math.sin(2 * meanLongitude) -
        2 * eccentricity * math.sin(meanAnomaly) +
        4 *
            eccentricity *
            y *
            math.sin(meanAnomaly) *
            math.cos(2 * meanLongitude) -
        0.5 * y * y * math.sin(4 * meanLongitude) -
        1.25 * eccentricity * eccentricity * math.sin(2 * meanAnomaly);
    // Radians of Earth rotation → seconds of clock time.
    return Duration(
      milliseconds: (value / degrees * 4 * Duration.millisecondsPerMinute)
          .round(),
    );
  }

  /// The Sun's track, for the shared rise/set solver.
  static Equatorial track(DateTime utc) => SunEphemeris.at(utc).equatorial;
}
