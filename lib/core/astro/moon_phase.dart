/// Lunar phase math — pure local computation, no network, no ephemeris data.
///
/// The moon's phase is a single physical quantity: the Sun–Moon elongation.
/// The simplified Meeus series (mean elongations + five perturbations) is
/// accurate to ~0.3° for decades around J2000 — far below what a display can
/// resolve (1° of elongation is ~0.03% of brightness). So this file is the
/// whole feature: pass it any [DateTime] (UTC), it returns the phase, the
/// illuminated fraction, the age in days, or the next full moon. Nothing here
/// needs a server or a downloaded star table.
///
/// Convention: `angle` 0 = new moon, π = full moon, 2π = next new moon.
library;

import 'dart:math' as math;

/// The synodic month, mean Earth days between identical phases.
const double synodicMonthDays = 29.530588853;

/// Lunar phase of an instant.
class MoonPhase {
  const MoonPhase._(this.angle);

  /// Phase angle in radians: 0 = new, π/2 = first quarter (waxing),
  /// π = full, 3π/2 = last quarter (waning), 2π = next new.
  final double angle;

  /// Illuminated fraction 0 (new) … 1 (full).
  double get brightness => (1 - math.cos(angle)) / 2;

  /// Age in days since the last new moon (0…[synodicMonthDays]).
  double get ageInDays => angle / (2 * math.pi) * synodicMonthDays;

  /// Whether the disc is gaining light (new → full).
  bool get waxing => angle < math.pi;

  /// The eight classical phases, resolved by the 45° sector the angle falls in.
  MoonPhaseName get name =>
      MoonPhaseName.values[((angle / (2 * math.pi)) * 8).round() % 8];

  /// Phase at [utc] — any instant, past or future.
  factory MoonPhase.at(DateTime utc) => MoonPhase._(MoonPhase.angleAt(utc));

  /// Just the angle — the scalar form most callers want.
  static double angleAt(DateTime utc) {
    // Days since the J2000 epoch (2000-01-01 12:00 TT ≈ UTC), then the
    // Meeus series' own unit: Julian centuries — the mean-motion constants
    // below are per century, feeding days would drift by ~0.27 rad/year.
    final t =
        (utc.millisecondsSinceEpoch / Duration.millisecondsPerDay +
            2440587.5 -
            2451545.0) /
        36525.0;
    // Meeus, Astronomical Algorithms (2nd ed.), ch. 47 truncated series.
    final d = _mod(297.8501921 + 445267.1114034 * t, 360); // elongation
    final m = _mod(357.5291092 + 35999.0502909 * t, 360); // sun anomaly
    final mp = _mod(134.9633964 + 477198.8675055 * t, 360); // moon anomaly
    final phase =
        d +
        6.289 * math.sin(mp * _deg2rad) -
        1.274 * math.sin((2 * d - mp) * _deg2rad) -
        0.658 * math.sin((2 * d) * _deg2rad) +
        2.1 * math.sin(m * _deg2rad) -
        0.214 * math.sin((2 * mp) * _deg2rad);
    return _mod(phase, 360) * _deg2rad;
  }

  /// The next instant at which the phase angle wraps through [target]
  /// (default: full moon, π), to 15-minute precision.
  ///
  /// The angle is monotonic over a synodic month, so a coarse scan for the
  /// ascending crossing followed by bisection finds the exact wrap — no
  /// ephemeris, just a few dozen trig probes. [target] must lie in
  /// `(0, 2π)` (use a value near 0 to find the new moon; its crossing is
  /// the wrap point itself).
  static DateTime nextAngle(DateTime utc, {double target = math.pi}) {
    assert(target > 0 && target < 2 * math.pi);
    double g(int minutes) =>
        _mod(angleAt(utc.add(Duration(minutes: minutes))), 2 * math.pi);
    // Coarse scan — 2 h steps over a 40-day horizon (a synodic month + slack).
    const stepMin = 120;
    const horizonMin = 40 * 24 * 60;
    var prev = g(0);
    var crossAt = -1;
    for (var m = stepMin; m <= horizonMin; m += stepMin) {
      final v = g(m);
      if (prev < target && v >= target) {
        crossAt = m;
        break;
      }
      prev = v;
    }
    if (crossAt < 0) {
      throw StateError('no phase crossing within the 40-day horizon');
    }
    // Bisect the crossing window down to ~15 min.
    var lo = crossAt - stepMin;
    var hi = crossAt;
    while (hi - lo > 15) {
      final mid = (lo + hi) ~/ 2;
      if (g(mid) < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return utc.add(Duration(minutes: hi));
  }

  /// Next full moon strictly after [utc].
  static DateTime nextFullMoon(DateTime utc) => nextAngle(utc, target: math.pi);

  /// Optical libration at [utc] as `(longitude, latitude)` in **radians** —
  /// how far the sub-earth point wanders from (0, 0).
  ///
  /// The Moon keeps one face toward us, but not a perfectly still one: its
  /// orbit is elliptical and inclined, so over a month it rocks about ±7° in
  /// longitude and ±6.7° in latitude, showing a little around each edge in
  /// turn. Leaving it out is what makes a rendered moon look like a decal —
  /// every night identical — and it is two terms of the same series the phase
  /// already uses.
  ///
  /// Optical libration only: the physical (forced) libration is under a tenth
  /// of a degree and invisible at any size this is drawn.
  static ({double longitude, double latitude}) librationAt(DateTime utc) {
    final t =
        (utc.millisecondsSinceEpoch / Duration.millisecondsPerDay +
            2440587.5 -
            2451545.0) /
        36525.0;
    // Mean anomaly of the Moon and its argument of latitude (Meeus ch. 47).
    final mp = _mod(134.9633964 + 477198.8675055 * t, 360) * _deg2rad;
    final f = _mod(93.2720950 + 483202.0175233 * t, 360) * _deg2rad;
    // Amplitudes are the classical maxima: the ellipse's equation of centre
    // in longitude, the 5.145° orbital inclination projected in latitude.
    return (
      longitude: 6.289 * _deg2rad * math.sin(mp),
      latitude: -6.688 * _deg2rad * math.sin(f),
    );
  }

  static double _mod(double a, double b) => ((a % b) + b) % b;
  static const double _deg2rad = math.pi / 180;
}

/// The eight classical lunar phases.
enum MoonPhaseName {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}
