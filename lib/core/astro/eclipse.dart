/// Eclipses, found rather than tabulated.
///
/// An eclipse is not a separate calculation. It is what the positions this
/// package already computes happen to do when the Sun, Earth and Moon line up,
/// so both kinds are found by walking the syzygies and measuring:
///
///   * **Lunar** — at each full moon, how far the Moon's centre is from the
///     axis of the Earth's shadow. The shadow's umbra and penumbra have known
///     angular radii at the Moon's distance, so comparing that separation with
///     them gives the type and the magnitude. A lunar eclipse is the same
///     everywhere on the night side, so there are no local circumstances
///     beyond "is the Moon up".
///   * **Solar** — at each new moon, how far the Moon's centre is from the
///     Sun's *as seen from where you are standing*. This is why
///     `Observer.topocentric` exists: the Moon's parallax is nearly a degree,
///     twice its own diameter, so a solar eclipse is a local event and a
///     geocentric calculation would describe one nobody can see. Working
///     topocentrically gives real local magnitude and contact times without
///     Besselian elements.
///
/// The shadow radii carry the standard 1.02 enlargement for the Earth's
/// atmosphere, which is what makes a predicted umbral magnitude agree with an
/// observed one.
///
/// **Measured** against NASA's eclipse catalogue in `test/core/astro/`.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// The Sun's equatorial horizontal parallax at 1 au — 8.794″.
const double _solarParallax = 8.794 / 3600 * degrees;

/// Enlargement of the Earth's shadow by its atmosphere (Danjon's 1/50 rule).
const double _atmosphere = 1.02;

/// What kind of eclipse, if any.
enum EclipseKind {
  none,

  /// The Moon in the Earth's outer shadow only — a subtle shading.
  penumbral,

  /// Part of the Moon in the umbra, or part of the Sun covered.
  partial,

  /// The Moon entirely in the umbra.
  total,

  /// The Moon too far away to cover the Sun: a ring is left.
  annular,
}

/// One eclipse.
class Eclipse {
  const Eclipse({
    required this.kind,
    required this.peak,
    required this.magnitude,
    required this.isSolar,
    this.penumbralMagnitude,
    this.begins,
    this.ends,
  });

  final EclipseKind kind;

  /// Greatest eclipse — least separation.
  final DateTime peak;

  /// Fraction of the eclipsed body's diameter covered at [peak]. Over 1 means
  /// total; for a solar eclipse it is the fraction of the Sun's diameter.
  final double magnitude;

  /// For a lunar eclipse, how deep into the outer shadow it goes. A penumbral
  /// eclipse has this without an umbral magnitude.
  final double? penumbralMagnitude;

  final bool isSolar;

  /// First and last contact, where the eclipse is visible at all.
  final DateTime? begins;
  final DateTime? ends;

  bool get isVisible => kind != EclipseKind.none;
}

/// Finding eclipses.
abstract final class Eclipses {
  /// The next lunar eclipse after [utc], searching at most [withinDays].
  ///
  /// Lunar eclipses are global: whoever has the Moon above the horizon sees
  /// the same event at the same instant, so nothing here depends on a place.
  static Eclipse? nextLunar(
    DateTime utc, {
    int withinDays = 400,
  }) {
    var full = MoonPhase.nextFullMoon(utc);
    final limit = utc.add(Duration(days: withinDays));
    while (full.isBefore(limit)) {
      final eclipse = lunarAt(full);
      if (eclipse.isVisible) return eclipse;
      full = MoonPhase.nextFullMoon(full.add(const Duration(days: 1)));
    }
    return null;
  }

  /// The lunar eclipse, if any, at the full moon near [near].
  static Eclipse lunarAt(DateTime near) {
    final peak = _minimise(near, _shadowSeparation);
    final separation = _shadowSeparation(peak);
    final moon = MoonEphemeris.at(peak);
    final sun = SunEphemeris.at(peak);

    final moonSemidiameter = moon.angularDiameter / 2;
    final sunSemidiameter = sun.angularDiameter / 2;
    final solarParallax = _solarParallax / (sun.distanceKm / astronomicalUnitKm);
    // Meeus ch. 54: the shadow's angular radii at the Moon's distance.
    final penumbra =
        _atmosphere * (moon.parallax + solarParallax + sunSemidiameter);
    final umbra =
        _atmosphere * (moon.parallax + solarParallax - sunSemidiameter);

    final umbralMagnitude =
        (umbra + moonSemidiameter - separation) / (2 * moonSemidiameter);
    final penumbralMagnitude =
        (penumbra + moonSemidiameter - separation) / (2 * moonSemidiameter);

    final kind = umbralMagnitude >= 1
        ? EclipseKind.total
        : umbralMagnitude > 0
        ? EclipseKind.partial
        : penumbralMagnitude > 0
        ? EclipseKind.penumbral
        : EclipseKind.none;

    if (kind == EclipseKind.none) {
      return Eclipse(
        kind: kind,
        peak: peak,
        magnitude: 0,
        isSolar: false,
      );
    }

    // Contacts: where the relevant magnitude passes through zero.
    final threshold = kind == EclipseKind.penumbral ? penumbra : umbra;
    double clearance(DateTime at) {
      final m = MoonEphemeris.at(at);
      return _shadowSeparation(at) - (threshold + m.angularDiameter / 2);
    }

    return Eclipse(
      kind: kind,
      peak: peak,
      magnitude: kind == EclipseKind.penumbral
          ? penumbralMagnitude
          : umbralMagnitude,
      penumbralMagnitude: penumbralMagnitude,
      isSolar: false,
      begins: _crossBefore(peak, clearance),
      ends: _crossAfter(peak, clearance),
    );
  }

  /// The next solar eclipse after [utc] **visible from this place**.
  ///
  /// A solar eclipse elsewhere on Earth is not an event here, so this asks the
  /// only question that matters to a reader: does the Moon cover any of the
  /// Sun from where I am standing, and is the Sun up at the time?
  static Eclipse? nextSolar(
    DateTime utc, {
    required double latitude,
    required double longitude,
    int withinDays = 1200,
  }) {
    var newMoon = MoonPhase.nextNewMoon(utc);
    final limit = utc.add(Duration(days: withinDays));
    while (newMoon.isBefore(limit)) {
      final eclipse = solarAt(
        newMoon,
        latitude: latitude,
        longitude: longitude,
      );
      if (eclipse.isVisible) return eclipse;
      newMoon = MoonPhase.nextNewMoon(newMoon.add(const Duration(days: 1)));
    }
    return null;
  }

  /// The solar eclipse, if any, seen from this place at the new moon near
  /// [near].
  static Eclipse solarAt(
    DateTime near, {
    required double latitude,
    required double longitude,
  }) {
    final observer = Observer(latitude: latitude, longitude: longitude);

    double separation(DateTime at) {
      final moon = observer.topocentric(MoonEphemeris.at(at).equatorial, at);
      final sun = SunEphemeris.at(at).equatorial;
      return moon.separationFrom(sun);
    }

    final peak = _minimise(near, separation);
    final gap = separation(peak);
    final moon = MoonEphemeris.at(peak);
    final sun = SunEphemeris.at(peak);
    // The Moon's apparent size grows with the parallax correction, since the
    // observer is up to an Earth radius nearer to it than the centre is.
    final moonRadius =
        moon.angularDiameter /
        2 *
        (moon.distanceKm / (moon.distanceKm - _observerShift(observer, peak)));
    final sunRadius = sun.angularDiameter / 2;

    final magnitude = (sunRadius + moonRadius - gap) / (2 * sunRadius);
    final kind = magnitude <= 0
        ? EclipseKind.none
        : gap < (moonRadius - sunRadius).abs()
        ? (moonRadius >= sunRadius ? EclipseKind.total : EclipseKind.annular)
        : EclipseKind.partial;

    if (kind == EclipseKind.none) {
      return Eclipse(kind: kind, peak: peak, magnitude: 0, isSolar: true);
    }

    double clearance(DateTime at) {
      final m = MoonEphemeris.at(at);
      final s = SunEphemeris.at(at);
      return separation(at) - (m.angularDiameter + s.angularDiameter) / 2;
    }

    final begins = _crossBefore(peak, clearance);
    final ends = _crossAfter(peak, clearance);

    // The geometry alone is not visibility. Standing on the night side of the
    // Earth, the parallax correction still produces a small formal separation
    // — an eclipse that is happening, just not to you. Requiring the Sun to be
    // above the horizon at some point between the contacts is what turns the
    // geometry into an answer, and it is the difference between listing the
    // 2026 Iceland eclipse for Taiwan and correctly not listing it.
    var sunIsUp = false;
    final from = begins ?? peak;
    final to = ends ?? peak;
    final span = to.difference(from).inMinutes;
    for (var minute = 0; minute <= span; minute += 5) {
      final at = from.add(Duration(minutes: minute));
      if (observer.lookAt(SunEphemeris.at(at).equatorial, at).altitude >
          sunHorizon) {
        sunIsUp = true;
        break;
      }
    }
    if (!sunIsUp) {
      return Eclipse(
        kind: EclipseKind.none,
        peak: peak,
        magnitude: 0,
        isSolar: true,
      );
    }

    return Eclipse(
      kind: kind,
      peak: peak,
      magnitude: magnitude,
      isSolar: true,
      begins: begins,
      ends: ends,
    );
  }

  /// Whether the Moon is above the horizon at [at] — the only local question a
  /// lunar eclipse raises, since the event itself is the same everywhere.
  static bool moonIsUp(
    DateTime at, {
    required double latitude,
    required double longitude,
  }) {
    final moon = MoonEphemeris.at(at);
    return Observer(
          latitude: latitude,
          longitude: longitude,
        ).lookAt(moon.equatorial, at).altitude >
        moon.horizonAltitude;
  }

  /// How much nearer the observer is to the Moon than the Earth's centre is,
  /// in kilometres — the reason the Moon looks fractionally larger overhead.
  static double _observerShift(Observer observer, DateTime at) {
    final moon = MoonEphemeris.at(at);
    final horizontal = observer.lookAt(moon.equatorial, at);
    return 6378.14 * math.sin(horizontal.altitude);
  }

  /// Angular distance from the Moon's centre to the axis of the Earth's
  /// shadow — the antisolar point.
  static double _shadowSeparation(DateTime at) {
    final moon = MoonEphemeris.at(at);
    final sun = SunEphemeris.at(at);
    final shadow = Equatorial.fromEcliptic(
      longitude: sun.longitude + math.pi,
      latitude: 0,
      obliquity: meanObliquity(sun.centuries),
    );
    return moon.equatorial.separationFrom(shadow);
  }

  /// The instant near [seed] at which [of] is least — ternary search, because
  /// the separation is smooth and single-minimum across a syzygy.
  static DateTime _minimise(DateTime seed, double Function(DateTime) of) {
    var low = seed.subtract(const Duration(hours: 12));
    var high = seed.add(const Duration(hours: 12));
    for (var i = 0; i < 40; i++) {
      final third = high.difference(low).inMilliseconds ~/ 3;
      final a = low.add(Duration(milliseconds: third));
      final b = high.subtract(Duration(milliseconds: third));
      if (of(a) < of(b)) {
        high = b;
      } else {
        low = a;
      }
    }
    return low.add(
      Duration(milliseconds: high.difference(low).inMilliseconds ~/ 2),
    );
  }

  /// Where [of] last crossed zero before [peak].
  static DateTime? _crossBefore(DateTime peak, double Function(DateTime) of) =>
      _bisect(peak.subtract(const Duration(hours: 6)), peak, of);

  /// Where [of] next crosses zero after [peak].
  static DateTime? _crossAfter(DateTime peak, double Function(DateTime) of) =>
      _bisect(peak.add(const Duration(hours: 6)), peak, of);

  /// Bisects between an instant where [of] is positive ([outside]) and one
  /// where it is negative ([inside]).
  static DateTime? _bisect(
    DateTime outside,
    DateTime inside,
    double Function(DateTime) of,
  ) {
    if (of(outside) < 0 || of(inside) > 0) return null;
    var lo = outside;
    var hi = inside;
    for (var i = 0; i < 30; i++) {
      final mid = lo.add(
        Duration(microseconds: hi.difference(lo).inMicroseconds ~/ 2),
      );
      if (of(mid) > 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return hi;
  }
}
