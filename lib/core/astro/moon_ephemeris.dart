/// Where the Moon is — one series, evaluated once, that everything else reads.
///
/// This is the astronomy layer's foundation. The phase, the distance readout,
/// the libration of the rendered globe and the rise/set times are not four
/// calculations: they are four *views* of one position. Deriving them from one
/// evaluation here, instead of from a hand-truncated series each, is what keeps
/// them consistent — a page that says "full moon" while the rise time disagrees
/// is the failure mode this removes.
///
/// The series is Meeus, *Astronomical Algorithms*, table 45.A/45.B (47.A/47.B
/// in the 2nd ed.) — the ELP-2000/82 truncation, kept to the terms that matter
/// at display resolution. Everything is closed form: no ephemeris file, no
/// network. That is deliberate for a disaster-preparedness app, where "works
/// with no service" outranks the last arcsecond.
///
/// **Measured**, not asserted. Against JPL Horizons over 2024–2027 (1385
/// samples, `tool/` harness): longitude within 37″, latitude within 32″,
/// distance within 59 km (0.015%). Meeus's own worked example 45.a is pinned
/// as a test. Distance is at the floor of this truncation — the remaining
/// error is the mean arguments' dropped quadratic terms, not the table.
library;

import 'dart:math' as math;

const double _degrees = math.pi / 180;

/// Earth's equatorial radius, km — turns distance into horizontal parallax.
const double _earthRadiusKm = 6378.14;

/// The Moon's mean radius, km — turns distance into apparent size.
const double _moonRadiusKm = 1737.4;

/// The Moon's geocentric position at one instant.
class MoonEphemeris {
  const MoonEphemeris({
    required this.longitude,
    required this.latitude,
    required this.distanceKm,
    required this.sunLongitude,
    required this.argumentOfLatitude,
    required this.centuries,
  });

  /// Geocentric ecliptic longitude λ of date, radians.
  final double longitude;

  /// Ecliptic latitude β, radians — ±5.3°, the tilt of the lunar orbit.
  final double latitude;

  /// Centre-to-centre Earth–Moon distance Δ, kilometres.
  final double distanceKm;

  /// The Sun's apparent ecliptic longitude, radians. Carried here because
  /// every phase quantity is a difference against it, and recomputing it
  /// elsewhere is exactly how two readouts start to disagree.
  final double sunLongitude;

  /// Mean argument of latitude F, radians — the libration needs it, and it is
  /// free here because the series already computed it.
  final double argumentOfLatitude;

  /// Julian centuries of Terrestrial Time from J2000.0 — the series' own unit.
  final double centuries;

  /// The Moon's position at [utc].
  factory MoonEphemeris.at(DateTime utc) {
    final t = centuriesFromJ2000(utc);

    // Mean arguments (Meeus 45.1–45.5), degrees. Their quadratic and higher
    // terms are dropped: over 1900–2100 they move λ by well under the
    // truncation error of the table below.
    final lp = 218.3164477 + 481267.88123421 * t; // mean longitude L'
    final d = 297.8501921 + 445267.1114034 * t; // elongation D
    final m = 357.5291092 + 35999.0502909 * t; // sun's anomaly M
    final mp = 134.9633964 + 477198.8675055 * t; // moon's anomaly M'
    final f = 93.2720950 + 483202.0175233 * t; // argument of latitude F

    // The Earth's orbit is slowly circularising, which detunes every term that
    // depends on the Sun's anomaly (Meeus 45.6).
    final e = 1 - 0.002516 * t - 0.0000074 * t * t;

    var sumL = 0.0; // 1e-6 degrees
    var sumR = 0.0; // 1e-3 km
    for (var i = 0; i < _longitudeAndRadius.length; i += 6) {
      final row = _longitudeAndRadius;
      final arg =
          (row[i] * d + row[i + 1] * m + row[i + 2] * mp + row[i + 3] * f) *
          _degrees;
      final scale = _eccentricityPower(e, row[i + 1]);
      sumL += row[i + 4] * scale * math.sin(arg);
      sumR += row[i + 5] * scale * math.cos(arg);
    }

    var sumB = 0.0; // 1e-6 degrees
    for (var i = 0; i < _latitude.length; i += 5) {
      final row = _latitude;
      final arg =
          (row[i] * d + row[i + 1] * m + row[i + 2] * mp + row[i + 3] * f) *
          _degrees;
      sumB += row[i + 4] * _eccentricityPower(e, row[i + 1]) * math.sin(arg);
    }

    // Venus, Jupiter and the Earth's flattening, folded into three fictitious
    // arguments (Meeus, p. 308). Small, but A1 alone is 0.004° — bigger than
    // everything the table truncation drops.
    final a1 = (119.75 + 131.849 * t) * _degrees;
    final a2 = (53.09 + 479264.290 * t) * _degrees;
    final a3 = (313.45 + 481266.484 * t) * _degrees;
    sumL +=
        3958 * math.sin(a1) +
        1962 * math.sin((lp - f) * _degrees) +
        318 * math.sin(a2);
    sumB +=
        -2235 * math.sin(lp * _degrees) +
        382 * math.sin(a3) +
        175 * math.sin(a1 - f * _degrees) +
        175 * math.sin(a1 + f * _degrees) +
        127 * math.sin((lp - mp) * _degrees) -
        115 * math.sin((lp + mp) * _degrees);

    return MoonEphemeris(
      longitude: turn((lp + sumL / 1e6) * _degrees),
      latitude: sumB / 1e6 * _degrees,
      distanceKm: 385000.56 + sumR / 1000,
      sunLongitude: _sunLongitude(t),
      argumentOfLatitude: turn(f * _degrees),
      centuries: t,
    );
  }

  /// Sun–Moon elongation, radians: 0 = new, π/2 = first quarter, π = full,
  /// 3π/2 = last quarter. The phase *is* this difference of two longitudes —
  /// not a series of its own.
  double get phaseAngle => turn(longitude - sunLongitude);

  /// Illuminated fraction of the disc, 0 (new) … 1 (full).
  ///
  /// Strictly the elongation, not the Sun–Moon–Earth phase angle; they differ
  /// by at most Δ/R ≈ 0.15°, which moves the fraction by under 0.2% — a fifth
  /// of the last digit the page shows.
  double get illuminated => (1 - math.cos(phaseAngle)) / 2;

  /// Equatorial coordinates of date, radians — the frame rise and set need.
  ({double rightAscension, double declination}) get equatorial {
    // Mean obliquity (Meeus 21.2, linear term). Nutation adds under 0.003°,
    // inside the truncation error either way.
    final obliquity = (23.439291 - 0.0130042 * centuries) * _degrees;
    final sinB = math.sin(latitude);
    final cosB = math.cos(latitude);
    final sinL = math.sin(longitude);
    final sinE = math.sin(obliquity);
    final cosE = math.cos(obliquity);
    return (
      rightAscension: turn(
        math.atan2(sinL * cosE - (sinB / cosB) * sinE, math.cos(longitude)),
      ),
      declination: math.asin(sinB * cosE + cosB * sinE * sinL),
    );
  }

  /// Equatorial horizontal parallax, radians — how far the Moon's apparent
  /// place shifts between the Earth's centre and a point on its surface.
  /// Nearly a degree, which is why a rise time computed without it is minutes
  /// wrong.
  double get parallax => math.asin(_earthRadiusKm / distanceKm);

  /// Apparent angular diameter, radians — 29.4′ at apogee, 33.5′ at perigee.
  double get angularDiameter => 2 * math.asin(_moonRadiusKm / distanceKm);

  /// Julian centuries of Terrestrial Time from J2000.0 at [utc].
  ///
  /// The series is defined on TT, which runs ~75 s ahead of UTC this decade.
  /// Left out, that offset alone costs 60″ of longitude — four times the whole
  /// truncation error — so it is worth the one polynomial (Espenak & Meeus's
  /// ΔT fit for 2005–2050). Rise/set still takes its *hour angle* from UT;
  /// only the position is TT.
  static double centuriesFromJ2000(DateTime utc) {
    final years = utc.year + (utc.month - 0.5) / 12 - 2000;
    final deltaT = 62.92 + 0.32217 * years + 0.005589 * years * years;
    return (utc.millisecondsSinceEpoch / Duration.millisecondsPerDay +
            deltaT / Duration.secondsPerDay +
            2440587.5 -
            2451545.0) /
        36525.0;
  }

  /// `e` raised to |[solarAnomaly]| — the correction applies once per power of
  /// M in the argument.
  static double _eccentricityPower(double e, double solarAnomaly) =>
      switch (solarAnomaly.abs()) {
        0 => 1.0,
        1 => e,
        _ => e * e,
      };

  /// The Sun's apparent ecliptic longitude, radians (Meeus ch. 24, low
  /// precision — 0.01°, far finer than a phase readout resolves).
  static double _sunLongitude(double t) {
    final l0 = 280.46646 + 36000.76983 * t;
    final m = (357.52911 + 35999.05029 * t) * _degrees;
    final centre =
        (1.914602 - 0.004817 * t) * math.sin(m) +
        0.019993 * math.sin(2 * m) +
        0.000289 * math.sin(3 * m);
    return turn((l0 + centre) * _degrees);
  }
}

/// Wraps an angle into `[0, 2π)`.
double turn(double radians) {
  const full = 2 * math.pi;
  return ((radians % full) + full) % full;
}

/// Periodic terms for longitude and distance — Meeus table 45.A, first 35 rows.
///
/// Packed six to a row as `D, M, M', F, Σl (1e-6°), Σr (1e-3 km)`: a flat list
/// of numbers, because that is what a table is. Written out as 35 lines of
/// `+ 6288.774 * sin(mp)` it would be the same data with 35 more chances to
/// mistype it — which is how the three separate hand-written series this
/// replaces came to disagree with each other.
///
/// The cut is where accuracy stops improving: rows 36–60 buy 25″ of longitude
/// and 12 km of distance, both far below what the page renders.
const List<double> _longitudeAndRadius = [
  0, 0, 1, 0, 6288774, -20905355, //
  2, 0, -1, 0, 1274027, -3699111, //
  2, 0, 0, 0, 658314, -2955968, //
  0, 0, 2, 0, 213618, -569925, //
  0, 1, 0, 0, -185116, 48888, //
  0, 0, 0, 2, -114332, -3149, //
  2, 0, -2, 0, 58793, 246158, //
  2, -1, -1, 0, 57066, -152138, //
  2, 0, 1, 0, 53322, -170733, //
  2, -1, 0, 0, 45758, -204586, //
  0, 1, -1, 0, -40923, -129620, //
  1, 0, 0, 0, -34720, 108743, //
  0, 1, 1, 0, -30383, 104755, //
  2, 0, 0, -2, 15327, 10321, //
  0, 0, 1, 2, -12528, 0, //
  0, 0, 1, -2, 10980, 79661, //
  4, 0, -1, 0, 10675, -34782, //
  0, 0, 3, 0, 10034, -23210, //
  4, 0, -2, 0, 8548, -21636, //
  2, 1, -1, 0, -7888, 24208, //
  2, 1, 0, 0, -6766, 30824, //
  1, 0, -1, 0, -5163, -8379, //
  1, 1, 0, 0, 4987, -16675, //
  2, -1, 1, 0, 4036, -12831, //
  2, 0, 2, 0, 3994, -10445, //
  4, 0, 0, 0, 3861, -11650, //
  2, 0, -3, 0, 3665, 14403, //
  0, 1, -2, 0, -2689, -7003, //
  2, 0, -1, 2, -2602, 0, //
  2, -1, -2, 0, 2390, 10056, //
  1, 0, 1, 0, -2348, 6322, //
  2, -2, 0, 0, 2236, -9884, //
  0, 1, 2, 0, -2120, 5751, //
  0, 2, 0, 0, -2069, 0, //
  2, -2, -1, 0, 2048, -4950, //
];

/// Periodic terms for ecliptic latitude — Meeus table 45.B, first 25 rows.
/// Packed five to a row as `D, M, M', F, Σb (1e-6°)`.
const List<double> _latitude = [
  0, 0, 0, 1, 5128122, //
  0, 0, 1, 1, 280602, //
  0, 0, 1, -1, 277693, //
  2, 0, 0, -1, 173237, //
  2, 0, -1, 1, 55413, //
  2, 0, -1, -1, 46271, //
  2, 0, 0, 1, 32573, //
  0, 0, 2, 1, 17198, //
  2, 0, 1, -1, 9266, //
  0, 0, 2, -1, 8822, //
  2, -1, 0, -1, 8216, //
  2, 0, -2, -1, 4324, //
  2, 0, 1, 1, 4200, //
  2, 1, 0, -1, -3359, //
  2, -1, -1, 1, 2463, //
  2, -1, 0, 1, 2211, //
  2, -1, -1, -1, 2065, //
  0, 1, -1, -1, -1870, //
  4, 0, -1, -1, 1828, //
  0, 1, 0, 1, -1794, //
  0, 0, 0, 3, -1749, //
  0, 1, -1, 1, -1565, //
  1, 0, 0, 1, -1491, //
  0, 1, 1, 1, -1475, //
  0, 1, 1, -1, -1410, //
];
