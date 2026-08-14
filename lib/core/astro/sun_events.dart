/// The shape of one day's light at one place.
///
/// Sunrise, sunset, solar noon, the three twilights and the photographers'
/// golden and blue hours are all the same question asked at different
/// altitudes — so they are one scan of the Sun's track against six thresholds,
/// not six algorithms.
///
/// The thresholds are conventions, and worth knowing which is which:
///
///   * **Sunrise / sunset** — the *upper limb* on the horizon: 34′ of
///     refraction plus 16′ of semidiameter below geometric zero.
///   * **Civil twilight** (−6°) — the one that matters outside astronomy. It
///     is the boundary of being able to work outdoors without light, which is
///     what an evacuation window or a search is planned against.
///   * **Nautical** (−12°) — the horizon is no longer visible at sea.
///   * **Astronomical** (−18°) — the sky is as dark as it will get.
///   * **Golden hour** (−4° to +6°) and **blue hour** (−6° to −4°) — light
///     quality, not visibility.
///
/// **Measured** against the US Naval Observatory and the CWA's published
/// sunrise/sunset timetable in `test/core/astro/`.
library;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// The upper end of golden hour — above this the light is ordinary daylight.
const double goldenHourTop = 6 * degrees;

/// The boundary between golden and blue hour.
const double goldenHourBottom = -4 * degrees;

/// One day of daylight at one place.
class SunEvents {
  const SunEvents({
    required this.rise,
    required this.set,
    required this.noon,
    required this.civilDawn,
    required this.civilDusk,
    required this.nauticalDawn,
    required this.nauticalDusk,
    required this.astronomicalDawn,
    required this.astronomicalDusk,
    required this.goldenMorningEnd,
    required this.goldenEveningStart,
    required this.blueMorningStart,
    required this.blueEveningEnd,
    required this.startsAbove,
    required this.from,
    required this.window,
  });

  /// Upper limb clears the horizon. Null above the Arctic and Antarctic
  /// circles in season — polar day and polar night are answers, not errors.
  final DateTime? rise;
  final DateTime? set;

  /// Solar noon — the Sun's upper transit, which is *not* clock noon: the
  /// equation of time moves it up to ±16 minutes across the year, plus the
  /// offset between the place and its timezone meridian.
  final DateTime? noon;

  final DateTime? civilDawn;
  final DateTime? civilDusk;
  final DateTime? nauticalDawn;
  final DateTime? nauticalDusk;
  final DateTime? astronomicalDawn;
  final DateTime? astronomicalDusk;

  /// Golden hour runs from [blueMorningStart] up through sunrise to
  /// [goldenMorningEnd], and mirrors in the evening.
  final DateTime? goldenMorningEnd;
  final DateTime? goldenEveningStart;
  final DateTime? blueMorningStart;
  final DateTime? blueEveningEnd;

  /// Whether the Sun was already up when the window opened.
  final bool startsAbove;

  /// The UTC instant the window opened.
  final DateTime from;

  /// The window this was solved over — how [dayLength] resolves the polar case.
  final Duration window;

  /// How long the Sun is above the horizon.
  ///
  /// Defined even when a rise or a set is missing: polar day is the whole
  /// window, polar night is none of it. A caller that just subtracted two
  /// nullable times would have to invent one of those answers.
  Duration get dayLength {
    if (rise == null && set == null) {
      return startsAbove ? window : Duration.zero;
    }
    if (rise == null) return set!.difference(from);
    if (set == null) return from.add(window).difference(rise!);
    return set!.isAfter(rise!)
        ? set!.difference(rise!)
        : window - rise!.difference(set!);
  }

  /// The nightly window with no sunlight at all — astronomical dusk to the
  /// next astronomical dawn. Null when the Sun never gets 18° down, which is
  /// most of the summer above about 49° latitude.
  ///
  /// This is the first half of "when can I actually observe"; the other half
  /// is whether the Moon is up, which the caller combines from
  /// `MoonRiseSet`.
  /// Null also when the window opened at midnight rather than midday: the
  /// dawn found would then be *this* morning's, before the dusk, and a pair in
  /// that order is not a night. Solve from noon to get a usable one.
  (DateTime, DateTime)? get astronomicalNight =>
      astronomicalDusk != null &&
          astronomicalDawn != null &&
          astronomicalDawn!.isAfter(astronomicalDusk!)
      ? (astronomicalDusk!, astronomicalDawn!)
      : null;

  /// One day's events from [from] (the UTC instant the local day begins), for
  /// the observer at [latitude] / [longitude] in degrees, east positive.
  factory SunEvents.of(
    DateTime from, {
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 24),
  }) {
    final observer = Observer(latitude: latitude, longitude: longitude);
    RiseSet at(double altitude) => RiseSet.solve(
      from: from,
      observer: observer,
      track: SunEphemeris.track,
      horizon: (_) => altitude,
      window: window,
    );

    final day = at(sunHorizon);
    final civil = at(civilTwilight);
    final nautical = at(nauticalTwilight);
    final astronomical = at(astronomicalTwilight);
    final goldenTop = at(goldenHourTop);
    final goldenFloor = at(goldenHourBottom);

    return SunEvents(
      rise: day.rise,
      set: day.set,
      noon: day.transit,
      civilDawn: civil.rise,
      civilDusk: civil.set,
      nauticalDawn: nautical.rise,
      nauticalDusk: nautical.set,
      astronomicalDawn: astronomical.rise,
      astronomicalDusk: astronomical.set,
      goldenMorningEnd: goldenTop.rise,
      goldenEveningStart: goldenTop.set,
      blueMorningStart: goldenFloor.rise,
      blueEveningEnd: goldenFloor.set,
      startsAbove: day.startsAbove,
      from: from,
      window: window,
    );
  }

  /// Where the Sun appears at [utc] — how high, and which way.
  static Horizontal lookFrom(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) => Observer(
    latitude: latitude,
    longitude: longitude,
  ).lookAt(SunEphemeris.at(utc).equatorial, utc);
}
