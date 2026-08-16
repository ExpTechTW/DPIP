/// The two clocks every ephemeris needs, and the angles derived from them.
///
/// Astronomy runs on two time scales and mixing them is the classic way to be
/// quietly wrong all year:
///
///   * **Terrestrial Time** is uniform, and is what the orbital series are
///     defined on. It runs about 75 s ahead of UTC this decade.
///   * **Universal Time** is the Earth's rotation angle, and is what sidereal
///     time — and therefore every hour angle, altitude and rise time — must be
///     built from.
///
/// So a rise time takes the body's position from TT and the observer's
/// orientation from UT. Both live here, next to each other, so neither can be
/// reached for by accident.
library;

import 'dart:math' as math;

/// Radians per degree — the conversion every file in `astro/` needs.
const double degrees = math.pi / 180;

/// Radians per arcminute.
const double arcminutes = degrees / 60;

/// Julian Day of [utc] on the **UT** scale.
double julianDay(DateTime utc) =>
    utc.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;

/// TT − UT in seconds: Espenak & Meeus's fit for 2005–2050, which is the span
/// this app plausibly runs over.
///
/// It matters more than its size suggests. Left out entirely, the Moon's
/// longitude is 60″ wrong — four times the truncation error of the series it
/// feeds. The Earth's rotation is not predictable, so no model is exact; being
/// a few seconds off is irrelevant, being 75 s off is not.
double deltaTSeconds(DateTime utc) {
  final years = utc.year + (utc.month - 0.5) / 12 - 2000;
  return 62.92 + 0.32217 * years + 0.005589 * years * years;
}

/// Julian centuries of **Terrestrial Time** from J2000.0 — the unit the
/// orbital series are written in.
double julianCenturies(DateTime utc) =>
    (julianDay(utc) + deltaTSeconds(utc) / Duration.secondsPerDay - 2451545.0) /
    36525.0;

/// Mean obliquity of the ecliptic in radians (Meeus 21.2, linear term).
///
/// Nutation adds under 0.003°, which is inside the truncation error of every
/// series in this package — carrying it would be precision theatre.
double meanObliquity(double centuries) =>
    (23.439291 - 0.0130042 * centuries) * degrees;

/// Greenwich mean sidereal time at [utc], radians (Meeus 11.4).
///
/// Built from UT on purpose — see the library doc.
double greenwichSiderealTime(DateTime utc) {
  final sinceEpoch = julianDay(utc) - 2451545.0;
  final centuries = sinceEpoch / 36525.0;
  return turn(
    (280.46061837 +
            360.98564736629 * sinceEpoch +
            0.000387933 * centuries * centuries) *
        degrees,
  );
}

/// Wraps an angle into `[0, 2π)`.
double turn(double radians) {
  const full = 2 * math.pi;
  return ((radians % full) + full) % full;
}

/// Wraps an angle into `(-π, π]` — the signed form, so a correction can go
/// backwards instead of the long way round.
double signedTurn(double radians) {
  final wrapped = turn(radians);
  return wrapped > math.pi ? wrapped - 2 * math.pi : wrapped;
}

/// Solves Kepler's equation `M = E − e sin E` for the eccentric anomaly.
///
/// Newton–Raphson from `E₀ = M + e sin M`. For every orbit in the solar
/// system (e < 0.25 here) that converges to machine precision in a handful of
/// passes; the iteration cap is a backstop, not the expected exit.
double eccentricAnomaly(double meanAnomaly, double eccentricity) {
  var e = meanAnomaly + eccentricity * math.sin(meanAnomaly);
  for (var pass = 0; pass < 12; pass++) {
    final delta =
        (e - eccentricity * math.sin(e) - meanAnomaly) /
        (1 - eccentricity * math.cos(e));
    e -= delta;
    if (delta.abs() < 1e-12) break;
  }
  return e;
}
