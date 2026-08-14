/// When the Moon rises, transits and sets at one place.
///
/// A thin naming of the shared solver in `sky_position.dart` — the Moon's own
/// contribution is only its track and its horizon. The horizon is the
/// interesting part: refraction lifts the limb 34′, while the parallax (nearly
/// a degree, and varying 14% with distance) converts the geocentric series
/// into what an observer on the surface sees. Because the parallax comes from
/// the distance already computed, it is exact for the night rather than a mean
/// value.
///
/// Some days have no moonrise at all: the Moon comes up ~50 minutes later each
/// day, so roughly once a month a calendar day gets skipped. `null` is a real
/// answer here, not a failure.
///
/// **Measured**, not asserted. Against the US Naval Observatory over 2026
/// (`test/core/astro/`) for Taipei, Sydney and Reykjavík — the last because at
/// 64°N the Moon skims the horizon and any weakness in the search shows there
/// first — and against the CWA's published Keelung timetable.
library;

import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/sky_position.dart';

/// Moonrise, transit and moonset within one window at one place.
class MoonRiseSet {
  const MoonRiseSet({
    required this.rise,
    required this.set,
    this.transit,
    this.startsAbove = false,
  });

  /// When the Moon's upper limb clears the horizon, or `null` if it does not
  /// rise in the window.
  final DateTime? rise;

  /// When it goes back down, on the same terms.
  final DateTime? set;

  /// Upper transit — the Moon at its highest, and the best moment to look.
  final DateTime? transit;

  /// Whether it was already up when the window opened.
  final bool startsAbove;

  /// Neither a rise nor a set fell in the window. [aboveHorizon] — or
  /// [startsAbove] — says which side of the horizon that was.
  bool get isCircumpolar => rise == null && set == null;

  /// Rise, transit and set within [window] (24 h by default) starting at
  /// [from], for the observer at [latitude] / [longitude] in degrees, east
  /// positive.
  ///
  /// Pass the UTC instant the local day begins — the caller owns the timezone,
  /// this owns the astronomy.
  factory MoonRiseSet.of(
    DateTime from, {
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 24),
  }) {
    final solved = RiseSet.solve(
      from: from,
      observer: Observer(latitude: latitude, longitude: longitude),
      track: moonTrack,
      horizon: moonHorizon,
      window: window,
    );
    return MoonRiseSet(
      rise: solved.rise,
      set: solved.set,
      transit: solved.transit,
      startsAbove: solved.startsAbove,
    );
  }

  /// Whether the Moon is above the horizon at [utc] — the other half of the
  /// answer when neither a rise nor a set falls inside the window.
  static bool aboveHorizon(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) {
    final moon = MoonEphemeris.at(utc);
    final observer = Observer(latitude: latitude, longitude: longitude);
    return observer.lookAt(moon.equatorial, utc).altitude >
        moon.horizonAltitude;
  }

  /// Where the Moon appears at [utc] — how high, and which way to look.
  static Horizontal lookFrom(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) => Observer(
    latitude: latitude,
    longitude: longitude,
  ).lookAt(MoonEphemeris.at(utc).equatorial, utc);
}

/// The Moon's track, for the shared solver.
Equatorial moonTrack(DateTime utc) => MoonEphemeris.at(utc).equatorial;

/// The Moon's rise/set horizon — distance-dependent, so it is recomputed at
/// every sample rather than fixed at a mean parallax.
double moonHorizon(Equatorial position) =>
    MoonEphemeris.horizonAltitudeFor(position.distanceKm!);
