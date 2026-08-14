/// The Moon as the page shows it — phase, illumination, distance, libration.
///
/// A thin reading of [MoonEphemeris]: every value here is the same position
/// looked at differently, so nothing in this file evaluates a series of its
/// own. Pass any UTC instant, past or future; nothing needs a server or a
/// downloaded star table.
///
/// Convention: `angle` 0 = new moon, π = full moon, 2π = the next new moon.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/moon_ephemeris.dart';

/// The synodic month — mean Earth days between identical phases.
const double synodicMonthDays = 29.530588853;

/// Inclination of the lunar equator to the ecliptic (Meeus ch. 51).
const double _lunarEquatorInclination = 1.54242 * math.pi / 180;

/// How the Moon looks from Earth at one instant.
class MoonPhase {
  const MoonPhase._(this._ephemeris);

  final MoonEphemeris _ephemeris;

  /// The Moon at [utc].
  factory MoonPhase.at(DateTime utc) => MoonPhase._(MoonEphemeris.at(utc));

  /// Phase angle in radians: 0 = new, π/2 = first quarter (waxing),
  /// π = full, 3π/2 = last quarter (waning), 2π = next new.
  double get angle => _ephemeris.phaseAngle;

  /// Illuminated fraction, 0 (new) … 1 (full).
  double get brightness => _ephemeris.illuminated;

  /// Centre-to-centre distance in kilometres — 356,500 at perigee to 406,700
  /// at apogee, a 14% swing that is most of why some full moons look larger.
  double get distanceKm => _ephemeris.distanceKm;

  /// Apparent angular diameter in degrees — 0.49° to 0.56°.
  double get apparentDiameterDegrees =>
      _ephemeris.angularDiameter * 180 / math.pi;

  /// Age in days since the last new moon (0…[synodicMonthDays]).
  double get ageInDays => angle / (2 * math.pi) * synodicMonthDays;

  /// Whether the disc is gaining light (new → full).
  bool get waxing => angle < math.pi;

  /// The eight classical phases, resolved by the 45° sector the angle sits in.
  MoonPhaseName get name =>
      MoonPhaseName.values[((angle / (2 * math.pi)) * 8).round() % 8];

  /// Just the angle — the scalar form the shader wants.
  static double angleAt(DateTime utc) => MoonEphemeris.at(utc).phaseAngle;

  /// The next instant at which the phase angle reaches [target] (default: full
  /// moon, π), strictly after [utc].
  ///
  /// The elongation gains 2π every synodic month and never reverses, so there
  /// is nothing to search for: coast to the target at the mean rate, then
  /// re-measure and correct. The true rate strays at most a fifth from the
  /// mean, so each pass cuts the error fivefold and five passes land within
  /// five seconds — no scan, no bracket, no horizon to fall off.
  static DateTime nextAngle(DateTime utc, {double target = math.pi}) {
    final at = _settle(utc.add(_coast(turn(target - angleAt(utc)))), target);
    // Asked from the target instant itself, the coast is zero and the search
    // lands right back on it. "Next" then means a month later.
    return at.isAfter(utc) ? at : _settle(at.add(_coast(2 * math.pi)), target);
  }

  /// Next full moon strictly after [utc].
  static DateTime nextFullMoon(DateTime utc) => nextAngle(utc);

  /// Next new moon strictly after [utc]. New is the wrap point, so the target
  /// is the wrap itself — the coast to it is a whole month from just after one
  /// and almost nothing from just before the next, which is the right answer
  /// in both directions.
  static DateTime nextNewMoon(DateTime utc) => nextAngle(utc, target: 0);

  /// Optical libration at [utc] as `(longitude, latitude)` in **radians** —
  /// the selenographic point facing Earth.
  ///
  /// The Moon keeps one face toward us, but not a still one: its orbit is
  /// elliptical and its equator tilted, so over a month it rocks about ±7° in
  /// longitude and ±6.7° in latitude, showing a little around each limb in
  /// turn. Leaving it out is what makes a rendered moon look like a decal —
  /// every night identical.
  ///
  /// Optical libration only (Meeus ch. 51). The physical libration is under a
  /// tenth of a degree, invisible at any size this is drawn.
  static ({double longitude, double latitude}) librationAt(DateTime utc) {
    final moon = MoonEphemeris.at(utc);
    // Mean longitude of the ascending node of the lunar orbit.
    final node = (125.0445479 - 1934.1362891 * moon.centuries) * math.pi / 180;
    final w = moon.longitude - node;
    final sinB = math.sin(moon.latitude);
    final cosB = math.cos(moon.latitude);
    final sinI = math.sin(_lunarEquatorInclination);
    final cosI = math.cos(_lunarEquatorInclination);
    final a = math.atan2(
      math.sin(w) * cosB * cosI - sinB * sinI,
      math.cos(w) * cosB,
    );
    return (
      longitude: _shortestWay(a - moon.argumentOfLatitude),
      latitude: math.asin(-math.sin(w) * cosB * sinI - sinB * cosI),
    );
  }

  /// Refines an estimate onto [target] by re-measuring and correcting.
  static DateTime _settle(DateTime estimate, double target) {
    var at = estimate;
    for (var pass = 0; pass < 5; pass++) {
      at = at.add(_coast(_shortestWay(target - angleAt(at))));
    }
    return at;
  }

  /// How long the mean phase takes to advance by [radians].
  static Duration _coast(double radians) => Duration(
    milliseconds:
        (radians /
                (2 * math.pi) *
                synodicMonthDays *
                Duration.millisecondsPerDay)
            .round(),
  );

  /// Wraps an angle into `(-π, π]` — the signed error, so a correction can go
  /// backwards instead of round the whole month.
  static double _shortestWay(double radians) {
    final wrapped = turn(radians);
    return wrapped > math.pi ? wrapped - 2 * math.pi : wrapped;
  }
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
