/// How the Moon is *tilted* when you actually look at it.
///
/// A rendered Moon that ignores this is the commonest mistake in the genre: it
/// draws the terminator vertical and the north pole up, which is what you would
/// see from the north celestial pole and nowhere else. At Taiwan's latitude the
/// real crescent is visibly rolled, and low in the sky it lies almost on its
/// back — the "smiling moon" everybody has photographed.
///
/// Two independent angles are needed, and one will not do:
///
///   * [northBearing] — which way the Moon's own north pole points on the sky,
///     so the maria land where an observer sees them.
///   * [brightLimbBearing] — which way the lit side faces. This is *not* 90°
///     from the pole: the Sun is on the ecliptic and the Moon is near it, so
///     the terminator tilts against the polar axis by up to about 30° over a
///     month.
///
/// Both are derived as great-circle bearings between two apparent places
/// rather than from a position-angle convention. That is deliberate: the
/// statement "the crescent's bright side faces the Sun" is a physical fact
/// that cannot come out backwards, whereas a sign convention transcribed from
/// a book can, and would look plausible either way.
library;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// The Moon's orientation for one observer at one instant.
class MoonOrientation {
  const MoonOrientation({
    required this.northBearing,
    required this.brightLimbBearing,
    required this.horizontal,
  });

  /// Screen bearing of the Moon's north pole: measured from straight up,
  /// increasing clockwise. Zero means the pole points at the zenith.
  final double northBearing;

  /// Screen bearing of the middle of the lit limb, same convention. This is
  /// the direction of the Sun as seen from the Moon.
  final double brightLimbBearing;

  /// Where the Moon is — how high, and which way to face.
  final Horizontal horizontal;

  /// The tilt of the lit limb relative to the Moon's own axis, radians. Purely
  /// derived, but it is the number that says how much a "north-up" rendering
  /// would be wrong by.
  double get limbTiltFromPole => signedTurn(brightLimbBearing - northBearing);

  /// The Moon's orientation at [utc] for the observer at [latitude] /
  /// [longitude] in degrees, east positive.
  factory MoonOrientation.at(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) {
    final observer = Observer(latitude: latitude, longitude: longitude);
    final moon = MoonEphemeris.at(utc);
    final moonAt = observer.lookAt(moon.equatorial, utc);

    // A point a little way toward the celestial pole from the Moon. The Moon's
    // own axis leans under 1.5° from that, which is inside the libration
    // already being applied to the globe.
    const nudge = 0.001;
    final polewards = observer.lookAt(
      Equatorial(
        rightAscension: moon.equatorial.rightAscension,
        declination: moon.equatorial.declination + nudge,
        distanceKm: moon.distanceKm,
      ),
      utc,
    );

    final sunAt = observer.lookAt(SunEphemeris.at(utc).equatorial, utc);

    return MoonOrientation(
      northBearing: moonAt.bearingTo(polewards),
      brightLimbBearing: moonAt.bearingTo(sunAt),
      horizontal: moonAt,
    );
  }
}
