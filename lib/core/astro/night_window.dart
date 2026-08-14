/// When it is actually dark enough to observe.
///
/// The question every observer asks first, and the one no single reading
/// answers. Sunset is not darkness — the sky takes another hour and a half to
/// finish. And a sky with no Sun in it can still be useless, because a gibbous
/// Moon washes out everything faint.
///
/// So the observing window is the intersection of two conditions this package
/// computes separately: the Sun below −18° (astronomical night) **and** the
/// Moon below the horizon. Either one alone is a half-answer that reads as a
/// whole one.
///
/// The result can be empty, and often is: for a week around full moon there is
/// no dark window at all at some latitudes, and above about 49° there is none
/// in midsummer whatever the Moon does. Both are real answers.
library;

import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';
import 'package:dpip/core/astro/sun_events.dart';

/// One stretch of usable dark.
class DarkWindow {
  const DarkWindow({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Duration get length => to.difference(from);
}

/// Tonight's observing conditions at one place.
class NightConditions {
  const NightConditions({
    required this.astronomicalNight,
    required this.darkWindows,
    required this.moonIllumination,
    required this.moonRise,
    required this.moonSet,
  });

  /// Dusk to dawn with the Sun 18° down, or null if the Sun never gets there.
  final (DateTime, DateTime)? astronomicalNight;

  /// The parts of that night with the Moon also down. Empty when the Moon is
  /// up throughout — which is not an error, it is a bad night.
  final List<DarkWindow> darkWindows;

  /// The Moon's illuminated fraction in the middle of the night — the number
  /// that decides how bad "moon up" actually is.
  final double moonIllumination;

  final DateTime? moonRise;
  final DateTime? moonSet;

  /// The longest usable stretch, if any.
  DarkWindow? get best => darkWindows.isEmpty
      ? null
      : darkWindows.reduce((a, b) => a.length >= b.length ? a : b);

  /// Total dark time.
  Duration get totalDark => darkWindows.fold(
    Duration.zero,
    (sum, window) => sum + window.length,
  );

  /// Conditions for the night starting at [from] — pass the UTC instant the
  /// local day begins, as the other astronomy pages do.
  factory NightConditions.of(
    DateTime from, {
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 36),
  }) {
    final sun = SunEvents.of(
      from,
      latitude: latitude,
      longitude: longitude,
      window: window,
    );
    final night = sun.astronomicalNight;
    final observer = Observer(latitude: latitude, longitude: longitude);

    final moonEvents = MoonRiseSet.of(
      from,
      latitude: latitude,
      longitude: longitude,
      window: window,
    );

    final windows = <DarkWindow>[];
    if (night != null) {
      // Walk the astronomical night and keep the stretches with no Moon. A
      // scan rather than interval arithmetic, because the Moon can rise and
      // set inside one night and the cases multiply quickly.
      const step = Duration(minutes: 5);
      DateTime? openedAt;
      var at = night.$1;
      while (!at.isAfter(night.$2)) {
        final moon = MoonEphemeris.at(at);
        final moonUp =
            observer.lookAt(moon.equatorial, at).altitude >
            moon.horizonAltitude;
        if (!moonUp && openedAt == null) {
          openedAt = at;
        } else if (moonUp && openedAt != null) {
          windows.add(DarkWindow(from: openedAt, to: at));
          openedAt = null;
        }
        at = at.add(step);
      }
      if (openedAt != null) {
        windows.add(DarkWindow(from: openedAt, to: night.$2));
      }
    }

    final middle = night == null
        ? from.add(const Duration(hours: 12))
        : night.$1.add(night.$2.difference(night.$1) ~/ 2);

    return NightConditions(
      astronomicalNight: night,
      // Sub-ten-minute slivers are an artefact of the scan step, not an
      // observing opportunity.
      darkWindows: windows
          .where((w) => w.length > const Duration(minutes: 10))
          .toList(),
      moonIllumination: MoonEphemeris.at(middle).illuminated,
      moonRise: moonEvents.rise,
      moonSet: moonEvents.set,
    );
  }

  /// The Sun's position right now, so a caller can say "still daylight".
  static Horizontal sunNow(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) => Observer(
    latitude: latitude,
    longitude: longitude,
  ).lookAt(SunEphemeris.at(utc).equatorial, utc);
}
