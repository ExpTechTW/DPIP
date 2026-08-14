/// The twenty-four solar terms — 二十四節氣.
///
/// Not folklore dates: each term is the instant the Sun's apparent ecliptic
/// longitude reaches an exact multiple of 15°, starting from the vernal
/// equinox at 0°. So this is the same search the moon phases use, pointed at
/// the Sun — 春分 is *defined* as λ☉ = 0°, 冬至 as λ☉ = 270°.
///
/// Two audiences, one calculation. The terms are the agricultural calendar
/// still printed on every Taiwanese wall calendar, and the four cardinal ones
/// are the solstices and equinoxes. They are also the backbone of the
/// lunisolar calendar in `lunisolar_calendar.dart`, whose leap-month rule is
/// stated entirely in terms of which 中氣 falls in which lunar month.
///
/// **Measured** against the CWA's published 節氣 table in `test/core/astro/`.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// Mean days per tropical year — the coast rate for the search below.
const double tropicalYearDays = 365.242189;

/// The twenty-four terms, in ecliptic order from the vernal equinox.
///
/// [longitudeDegrees] is the definition, not a label: everything else about a
/// term is derived from the instant the Sun reaches it.
enum SolarTerm {
  vernalEquinox(0),
  pureBrightness(15),
  grainRain(30),
  startOfSummer(45),
  grainFull(60),
  grainInEar(75),
  summerSolstice(90),
  minorHeat(105),
  majorHeat(120),
  startOfAutumn(135),
  endOfHeat(150),
  whiteDew(165),
  autumnalEquinox(180),
  coldDew(195),
  frostDescent(210),
  startOfWinter(225),
  minorSnow(240),
  majorSnow(255),
  winterSolstice(270),
  minorCold(285),
  majorCold(300),
  startOfSpring(315),
  rainWater(330),
  awakeningOfInsects(345);

  const SolarTerm(this.longitudeDegrees);

  /// The Sun's apparent ecliptic longitude at this term, degrees.
  final int longitudeDegrees;

  /// Whether this is a **中氣** (major term) — a multiple of 30°.
  ///
  /// The distinction is not decorative: the lunisolar leap month is the one
  /// that contains no 中氣.
  bool get isMajor => longitudeDegrees % 30 == 0;

  /// The four cardinal terms — the solstices and equinoxes.
  bool get isCardinal => longitudeDegrees % 90 == 0;
}

/// Finding solar terms.
abstract final class SolarTerms {
  /// The next occurrence of [term] strictly after [utc].
  ///
  /// The Sun's longitude advances about a degree a day and never reverses, so
  /// there is nothing to bracket: coast to the target at the mean rate, then
  /// re-measure and correct. The true rate strays only ±3.4% from the mean
  /// (the Earth's orbital eccentricity), so each pass cuts the error thirty
  /// fold and four passes land inside a second.
  static DateTime next(DateTime utc, SolarTerm term) {
    final target = term.longitudeDegrees * degrees;
    final at = _settle(utc.add(_coast(turn(target - _longitude(utc)))), target);
    // Asked from the term's own instant, the coast is zero and the search
    // lands back on it; "next" then means a year later.
    return at.isAfter(utc) ? at : _settle(at.add(_coast(2 * math.pi)), target);
  }

  /// The term the Sun is currently in — the most recent one reached.
  static SolarTerm at(DateTime utc) {
    final index = (_longitude(utc) / degrees / 15).floor() % 24;
    return SolarTerm.values[index];
  }

  /// The next term of any kind, with its instant.
  static (SolarTerm, DateTime) upcoming(DateTime utc) {
    final term = SolarTerm.values[(SolarTerm.values.indexOf(at(utc)) + 1) % 24];
    return (term, next(utc, term));
  }

  /// Every term whose instant falls in [year] (Taipei wall time is the
  /// caller's business — this returns UTC instants), in chronological order.
  ///
  /// A term can drift either side of a year boundary, so the list is built by
  /// walking forward from just before the year rather than by assuming each
  /// term lands in its usual month.
  static List<(SolarTerm, DateTime)> ofYear(int year, {Duration? offset}) {
    final shift = offset ?? Duration.zero;
    final start = DateTime.utc(year).subtract(shift);
    final end = DateTime.utc(year + 1).subtract(shift);
    final found = <(SolarTerm, DateTime)>[];
    for (final term in SolarTerm.values) {
      var at = next(start.subtract(const Duration(days: 400)), term);
      while (at.isBefore(start)) {
        at = next(at, term);
      }
      if (at.isBefore(end)) found.add((term, at));
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    return found;
  }

  /// The Sun's apparent longitude at [utc], radians.
  static double _longitude(DateTime utc) => SunEphemeris.at(utc).longitude;

  static DateTime _settle(DateTime estimate, double target) {
    var at = estimate;
    for (var pass = 0; pass < 4; pass++) {
      at = at.add(_coast(signedTurn(target - _longitude(at))));
    }
    return at;
  }

  /// How long the mean Sun takes to advance by [radians].
  static Duration _coast(double radians) => Duration(
    milliseconds:
        (radians /
                (2 * math.pi) *
                tropicalYearDays *
                Duration.millisecondsPerDay)
            .round(),
  );
}
