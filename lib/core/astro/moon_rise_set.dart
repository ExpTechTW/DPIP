/// When the Moon rises and sets at one place.
///
/// There is no closed form for this: the Moon moves against the stars fast
/// enough (about half a degree an hour, its own diameter) that the geometry
/// changes while it crosses the horizon. So this does what every almanac does
/// — walks the Moon's altitude across the day, finds where it crosses the
/// horizon, and bisects each crossing to the second. That is also why some
/// days have no moonrise at all: the Moon comes up ~50 minutes later each day,
/// so roughly once a month a calendar day gets skipped. `null` is a real
/// answer here, not a failure.
///
/// The horizon is not zero altitude. Refraction lifts the Moon by about 34′
/// when it is on the horizon, and — because rise and set are defined for an
/// observer on the surface but the position is computed for the Earth's centre
/// — the parallax of nearly a degree has to come back out. Meeus's standard
/// altitude `h₀ = 0.7275π − 34′` (ch. 14) does both, and since the parallax is
/// derived from the distance we already have, it is exact for the night rather
/// than a mean value.
///
/// **Measured**, not asserted. Against the US Naval Observatory over 2026
/// (`test/core/astro/`), for Taipei, Sydney and Reykjavík — the last chosen
/// because at 64°N the Moon skims the horizon and any weakness in the search
/// shows up there first.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/moon_ephemeris.dart';

const double _degrees = math.pi / 180;

/// Moonrise and moonset within one window at one place.
class MoonRiseSet {
  const MoonRiseSet({required this.rise, required this.set});

  /// When the Moon's upper limb clears the horizon, or `null` if it does not
  /// rise in the window — either because it is already up all day, or because
  /// the ~50-minute daily slip pushed the rise past midnight.
  final DateTime? rise;

  /// When it goes back down, on the same terms.
  final DateTime? set;

  /// Whether the Moon neither rose nor set — up all window, or down all
  /// window. [aboveHorizon] tells which.
  bool get isCircumpolar => rise == null && set == null;

  /// Rise and set within [window] (24 h by default) starting at [from], for
  /// the observer at [latitude] / [longitude] in degrees, east positive.
  ///
  /// Pass the UTC instant the local day begins — the caller owns the timezone,
  /// this owns the astronomy.
  factory MoonRiseSet.of(
    DateTime from, {
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 24),
  }) {
    final observer = _Observer(latitude * _degrees, longitude * _degrees);
    // Ten minutes is fine everywhere the Moon crosses at a sane angle, and is
    // still under half the shortest skimming appearance at 64°N.
    const stepMinutes = 10;
    DateTime? rise;
    DateTime? set;

    var previousAt = from;
    var previous = observer.heightAboveHorizon(from);
    for (var m = stepMinutes; m <= window.inMinutes; m += stepMinutes) {
      final at = from.add(Duration(minutes: m));
      final current = observer.heightAboveHorizon(at);
      if (previous.isNegative && !current.isNegative) {
        rise ??= observer.cross(previousAt, at);
      } else if (!previous.isNegative && current.isNegative) {
        set ??= observer.cross(previousAt, at);
      }
      previousAt = at;
      previous = current;
    }
    return MoonRiseSet(rise: rise, set: set);
  }

  /// Whether the Moon is above the horizon at [utc] — the other half of the
  /// answer when neither a rise nor a set falls inside the window.
  static bool aboveHorizon(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) => !_Observer(
    latitude * _degrees,
    longitude * _degrees,
  ).heightAboveHorizon(utc).isNegative;
}

/// One place on the Earth, in radians.
class _Observer {
  const _Observer(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// How far the Moon is above its rise/set horizon at [utc], radians.
  /// Negative below, positive above — so a sign change is a crossing.
  double heightAboveHorizon(DateTime utc) {
    final moon = MoonEphemeris.at(utc);
    final equatorial = moon.equatorial;
    final hourAngle =
        _greenwichSiderealTime(utc) + longitude - equatorial.rightAscension;
    final altitude = math.asin(
      math.sin(latitude) * math.sin(equatorial.declination) +
          math.cos(latitude) *
              math.cos(equatorial.declination) *
              math.cos(hourAngle),
    );
    // Refraction lifts the limb 34′; the parallax converts the geocentric
    // position to the observer's. See the library doc.
    final horizon = 0.7275 * moon.parallax - 34 / 60 * _degrees;
    return altitude - horizon;
  }

  /// The instant of the crossing bracketed by [before] and [after], to about a
  /// tenth of a second. Bisection, because the bracket is already tight and a
  /// halving loop cannot wander off the way a secant step can.
  DateTime cross(DateTime before, DateTime after) {
    var low = before;
    var high = after;
    final rising = heightAboveHorizon(before).isNegative;
    for (var i = 0; i < 13; i++) {
      final middle = low.add(
        Duration(microseconds: high.difference(low).inMicroseconds ~/ 2),
      );
      if (heightAboveHorizon(middle).isNegative == rising) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return high;
  }

  /// Greenwich mean sidereal time at [utc], radians (Meeus 11.4).
  ///
  /// Sidereal time is the Earth's rotation angle, so it takes UT — not the
  /// Terrestrial Time the position series runs on. Mixing the two is the
  /// classic way to be a minute wrong all year.
  static double _greenwichSiderealTime(DateTime utc) {
    final julianDay =
        utc.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;
    final sinceEpoch = julianDay - 2451545.0;
    final centuries = sinceEpoch / 36525.0;
    final degrees =
        280.46061837 +
        360.98564736629 * sinceEpoch +
        0.000387933 * centuries * centuries;
    return turn(degrees * _degrees);
  }
}
