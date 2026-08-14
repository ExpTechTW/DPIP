/// Where a body is in the sky, and when it crosses the horizon.
///
/// One coordinate pipeline and one rise/set solver for everything. The Moon,
/// the Sun, a planet and a catalogue star differ only in how their [Equatorial]
/// position is produced and how high their horizon sits — so that is all a
/// caller supplies. Everything downstream (altitude, azimuth, rise, transit,
/// set, twilight) is shared, which is why the Sun's rise and the Moon's cannot
/// drift apart in their treatment of refraction, sidereal time or the day
/// boundary.
///
/// Azimuth is measured **from north, increasing eastward** — the convention a
/// phone compass reports, so pointing instructions need no translation.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';

/// Refraction at the horizon: a body's *apparent* place is about 34′ above its
/// true one, so it is seen to rise while still geometrically below.
const double horizonRefraction = 34 * arcminutes;

/// Standard altitude for a point source — a star or a planet. Refraction only:
/// it has no disc worth speaking of and its parallax is nil.
const double pointHorizon = -horizonRefraction;

/// Standard altitude for sunrise and sunset: the refraction above, plus the
/// Sun's own 16′ semidiameter, because "sunrise" means the upper limb.
const double sunHorizon = -(horizonRefraction + 16 * arcminutes);

/// Civil twilight — the Sun 6° down. Bright enough to work outdoors without
/// light, which is why this is the one that matters for an evacuation.
const double civilTwilight = -6 * degrees;

/// Nautical twilight — 12° down; the horizon is no longer distinguishable.
const double nauticalTwilight = -12 * degrees;

/// Astronomical twilight — 18° down; the sky is as dark as it will get.
const double astronomicalTwilight = -18 * degrees;

/// A body's position on the celestial sphere, in the equinox of date.
class Equatorial {
  const Equatorial({
    required this.rightAscension,
    required this.declination,
    this.distanceKm,
  });

  /// Right ascension α, radians.
  final double rightAscension;

  /// Declination δ, radians.
  final double declination;

  /// Distance from the Earth's centre in kilometres, where the body has a
  /// meaningful one. Null for a star, whose parallax is not worth carrying.
  final double? distanceKm;

  /// Builds from ecliptic longitude/latitude of date.
  factory Equatorial.fromEcliptic({
    required double longitude,
    required double latitude,
    required double obliquity,
    double? distanceKm,
  }) {
    final sinB = math.sin(latitude);
    final cosB = math.cos(latitude);
    final sinL = math.sin(longitude);
    final sinE = math.sin(obliquity);
    final cosE = math.cos(obliquity);
    return Equatorial(
      rightAscension: turn(
        math.atan2(sinL * cosE - (sinB / cosB) * sinE, math.cos(longitude)),
      ),
      declination: math.asin(sinB * cosE + cosB * sinE * sinL),
      distanceKm: distanceKm,
    );
  }

  /// Angular separation from [other], radians — the quantity behind every
  /// "conjunction", "elongation" and "how close will they be" question.
  double separationFrom(Equatorial other) {
    final d1 = declination;
    final d2 = other.declination;
    final cosine =
        math.sin(d1) * math.sin(d2) +
        math.cos(d1) *
            math.cos(d2) *
            math.cos(rightAscension - other.rightAscension);
    return math.acos(cosine.clamp(-1.0, 1.0));
  }
}

/// Where a body appears to an observer: how high, and which way.
class Horizontal {
  const Horizontal({required this.altitude, required this.azimuth});

  /// Altitude above the true horizon, radians. Negative is below.
  final double altitude;

  /// Azimuth from north, increasing eastward, radians `[0, 2π)`.
  final double azimuth;

  /// The compass point, as an index into the sixteen-way rose starting at N.
  int get compassIndex => (azimuth / (2 * math.pi) * 16).round() % 16;

  /// The direction of [target] as seen from this position, measured from
  /// straight up (the zenith) and increasing clockwise — which is the same as
  /// increasing azimuth, because facing a bearing puts larger azimuths to your
  /// right.
  ///
  /// This is the great-circle bearing on the horizontal sphere, with altitude
  /// playing the part of latitude. Deriving orientation this way rather than
  /// from a position-angle convention removes the whole class of sign errors:
  /// "the crescent points at the Sun" is a fact, not a convention, and a
  /// bearing computed from the two apparent places cannot get it backwards.
  double bearingTo(Horizontal target) {
    final deltaAzimuth = target.azimuth - azimuth;
    return math.atan2(
      math.cos(target.altitude) * math.sin(deltaAzimuth),
      math.cos(altitude) * math.sin(target.altitude) -
          math.sin(altitude) *
              math.cos(target.altitude) *
              math.cos(deltaAzimuth),
    );
  }
}

/// A place on the Earth. Degrees in, radians kept.
class Observer {
  const Observer({required this.latitude, required this.longitude});

  /// Latitude in **degrees**, north positive.
  final double latitude;

  /// Longitude in **degrees**, east positive.
  final double longitude;

  double get _phi => latitude * degrees;

  /// Local hour angle of [position] at [utc], radians, wrapped to `(-π, π]`.
  /// Zero at upper transit; negative before it, positive after.
  double hourAngle(Equatorial position, DateTime utc) => signedTurn(
    greenwichSiderealTime(utc) + longitude * degrees - position.rightAscension,
  );

  /// Where [position] appears at [utc].
  Horizontal lookAt(Equatorial position, DateTime utc) {
    final h = hourAngle(position, utc);
    final sinDec = math.sin(position.declination);
    final cosDec = math.cos(position.declination);
    final sinPhi = math.sin(_phi);
    final cosPhi = math.cos(_phi);
    return Horizontal(
      altitude: math.asin(sinPhi * sinDec + cosPhi * cosDec * math.cos(h)),
      // Measured from north: the numerator is the east component, and the
      // sign of the denominator is what puts a transiting body due south in
      // the northern hemisphere rather than due north.
      azimuth: turn(
        math.atan2(
          -cosDec * math.sin(h),
          cosPhi * sinDec - sinPhi * cosDec * math.cos(h),
        ),
      ),
    );
  }

  /// The **parallactic angle** at [position], radians — the tilt between "up"
  /// on the sky (celestial north) and "up" for the observer (the zenith).
  ///
  /// Without it a crescent Moon is drawn with its horns pointing the way they
  /// would from the north pole. At Taiwan's latitude the real crescent is
  /// noticeably rolled, and near the horizon it lies almost on its back.
  double parallacticAngle(Equatorial position, DateTime utc) {
    final h = hourAngle(position, utc);
    return math.atan2(
      math.sin(h),
      math.tan(_phi) * math.cos(position.declination) -
          math.sin(position.declination) * math.cos(h),
    );
  }
}

/// A body's position as a function of time — the one thing each ephemeris has
/// to supply to use the shared solver.
typedef SkyTrack = Equatorial Function(DateTime utc);

/// The altitude counted as "on the horizon" for this body at this instant.
/// A constant for the Sun and the stars; distance-dependent for the Moon,
/// whose parallax moves it by nearly a degree.
typedef HorizonAltitude = double Function(Equatorial position);

/// Rise, transit and set within one window.
class RiseSet {
  const RiseSet({this.rise, this.transit, this.set, required this.startsAbove});

  /// When the body crosses the horizon upward, or null if it does not in the
  /// window. Null is an ordinary answer — a body can be up the whole time, down
  /// the whole time, or (for the Moon) simply have slipped past midnight.
  final DateTime? rise;

  /// Upper transit — the highest point, and the best moment to look.
  final DateTime? transit;

  /// When it crosses downward.
  final DateTime? set;

  /// Whether it was already above the horizon when the window opened. This is
  /// what disambiguates "never rose because it was up all day" from "never rose
  /// because it was down all day".
  final bool startsAbove;

  /// Neither a rise nor a set fell in the window.
  bool get isAlwaysUp => rise == null && set == null && startsAbove;

  /// Below the horizon for the whole window.
  bool get isAlwaysDown => rise == null && set == null && !startsAbove;

  /// Solves for the crossings of [track] over [window] starting at [from].
  ///
  /// A scan, not a formula: the Moon moves half a degree an hour and the Sun's
  /// declination drifts, so the geometry changes while the body crosses. The
  /// sampling step has to be short enough to bracket the briefest appearance —
  /// ten minutes holds even at 64°N, where the Moon skims the horizon rather
  /// than cutting it.
  static RiseSet solve({
    required DateTime from,
    required Observer observer,
    required SkyTrack track,
    required HorizonAltitude horizon,
    Duration window = const Duration(hours: 24),
    Duration step = const Duration(minutes: 10),
  }) {
    double above(DateTime at) {
      final position = track(at);
      return observer.lookAt(position, at).altitude - horizon(position);
    }

    DateTime bisect(
      DateTime low,
      DateTime high,
      bool Function(double) isBelow,
    ) {
      var lo = low;
      var hi = high;
      for (var i = 0; i < 14; i++) {
        final mid = lo.add(
          Duration(microseconds: hi.difference(lo).inMicroseconds ~/ 2),
        );
        if (isBelow(above(mid))) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return hi;
    }

    DateTime? rise;
    DateTime? set;
    DateTime? transit;

    final stepMinutes = step.inMinutes;
    var previousAt = from;
    var previousHeight = above(from);
    var previousHourAngle = observer.hourAngle(track(from), from);
    final startsAbove = !previousHeight.isNegative;

    for (var m = stepMinutes; m <= window.inMinutes; m += stepMinutes) {
      final at = from.add(Duration(minutes: m));
      final height = above(at);
      if (previousHeight.isNegative && !height.isNegative) {
        rise ??= bisect(previousAt, at, (h) => h.isNegative);
      } else if (!previousHeight.isNegative && height.isNegative) {
        set ??= bisect(previousAt, at, (h) => !h.isNegative);
      }
      // Upper transit is the hour angle passing through zero. Taken on the
      // signed hour angle, so the wrap from +π to -π (lower transit) is not
      // mistaken for it.
      final currentHourAngle = observer.hourAngle(track(at), at);
      if (transit == null &&
          previousHourAngle < 0 &&
          currentHourAngle >= 0 &&
          currentHourAngle - previousHourAngle < math.pi) {
        var lo = previousAt;
        var hi = at;
        for (var i = 0; i < 14; i++) {
          final mid = lo.add(
            Duration(microseconds: hi.difference(lo).inMicroseconds ~/ 2),
          );
          if (observer.hourAngle(track(mid), mid) < 0) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        transit = hi;
      }
      previousAt = at;
      previousHeight = height;
      previousHourAngle = currentHourAngle;
    }

    return RiseSet(
      rise: rise,
      transit: transit,
      set: set,
      startsAbove: startsAbove,
    );
  }
}
