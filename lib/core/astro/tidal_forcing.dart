/// The astronomical part of the tide.
///
/// **This is not a tide table, and it does not pretend to be.** A real
/// prediction for a harbour needs that harbour's harmonic constants — the
/// ocean's local response to the forcing, which depends on the shape of the
/// coast and cannot be derived from astronomy. The CWA publishes those tables
/// and they are the authority.
///
/// What *is* purely astronomical, and therefore computable offline from the
/// positions this package already has, is the **forcing** itself: the
/// equilibrium tide, the shape the ocean would take if it could respond
/// instantly. That gives the things a tide table's numbers do not explain —
///
///   * **Spring and neap.** The Sun's pull is 46% of the Moon's. When they
///     line up (new and full moon) the ranges add; at the quarters they
///     partly cancel. This is a phase relationship, not a lookup.
///   * **Perigean springs.** The forcing goes as the *cube* of distance, so a
///     spring tide at lunar perigee is far stronger than one at apogee — a
///     14% distance swing becomes a 48% swing in pull. A spring tide at
///     perigee during a storm is the combination that floods, which is why
///     this belongs in a disaster app at all.
///
/// The two coefficients below are the standard equilibrium amplitudes: 0.358 m
/// for the Moon at mean distance and 0.164 m for the Sun. Their ratio, 0.46,
/// is the solar-to-lunar tidal ratio, and it is the one number here that can
/// be checked against a textbook without any ocean in the way.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/astro/sky_position.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';

/// Equilibrium tide amplitude for the Moon at its mean distance, metres.
const double _lunarAmplitude = 0.358;

/// The same for the Sun at 1 au.
const double _solarAmplitude = 0.164;

/// Mean Earth–Moon distance, km — the reference the cube law scales from.
const double _meanLunarDistanceKm = 384400;

/// How strong the tide-raising forces are, and why.
class TidalForcing {
  const TidalForcing({
    required this.at,
    required this.equilibriumMetres,
    required this.lunarMetres,
    required this.solarMetres,
    required this.springNeap,
    required this.lunarDistanceKm,
  });

  final DateTime at;

  /// The equilibrium tide height at this place, metres. Its *shape* over a day
  /// is meaningful; its absolute value is not a water level.
  final double equilibriumMetres;

  /// The two contributions, so the reason for a big tide is visible rather
  /// than just its size.
  final double lunarMetres;
  final double solarMetres;

  /// 1 at spring (Sun and Moon aligned), 0 at neap (at right angles).
  ///
  /// Derived from the phase angle, because that *is* the alignment: springs
  /// happen at new and full moon, neaps at the quarters.
  final double springNeap;

  final double lunarDistanceKm;

  /// How much stronger the Moon's pull is than at its mean distance. The cube
  /// law turns perigee into about +23% and apogee into about −18%.
  double get distanceFactor =>
      math.pow(_meanLunarDistanceKm / lunarDistanceKm, 3).toDouble();

  /// A spring tide near perigee — the combination that produces the highest
  /// water of the year, and the one that matters alongside a storm surge.
  bool get isPerigeanSpring => springNeap > 0.8 && distanceFactor > 1.15;

  /// Spring, neap, or between.
  TidePhase get phase => springNeap > 0.75
      ? TidePhase.spring
      : springNeap < 0.25
      ? TidePhase.neap
      : TidePhase.middling;

  /// The forcing at [utc] for the observer at [latitude] / [longitude],
  /// degrees, east positive.
  factory TidalForcing.at(
    DateTime utc, {
    required double latitude,
    required double longitude,
  }) {
    final observer = Observer(latitude: latitude, longitude: longitude);
    final moon = MoonEphemeris.at(utc);
    final sun = SunEphemeris.at(utc);

    // The second-degree tidal potential: (3cos²z − 1)/2, where z is the zenith
    // distance. It peaks both under the body and directly opposite it, which
    // is why there are two high tides a day and not one.
    double potential(Equatorial position, DateTime at) {
      final cosZenith = math.sin(observer.lookAt(position, at).altitude);
      return (3 * cosZenith * cosZenith - 1) / 2;
    }

    final lunar =
        _lunarAmplitude *
        math.pow(_meanLunarDistanceKm / moon.distanceKm, 3) *
        potential(moon.equatorial, utc);
    final solar =
        _solarAmplitude *
        math.pow(astronomicalUnitKm / sun.distanceKm, 3) *
        potential(sun.equatorial, utc);

    // |cos| of the phase angle: 1 at new and full, 0 at the quarters.
    final alignment = math.cos(moon.phaseAngle).abs();

    return TidalForcing(
      at: utc,
      equilibriumMetres: (lunar + solar).toDouble(),
      lunarMetres: lunar.toDouble(),
      solarMetres: solar.toDouble(),
      springNeap: alignment,
      lunarDistanceKm: moon.distanceKm,
    );
  }

  /// The highs and lows of the equilibrium tide over [window] from [from].
  ///
  /// Turning points of a smooth curve, found by sampling and refining. These
  /// are the times the *forcing* peaks; a real harbour lags them by a fixed
  /// interval of its own (its 高潮間隙), which is exactly the piece this
  /// cannot know.
  static List<TidalExtreme> extremes(
    DateTime from, {
    required double latitude,
    required double longitude,
    Duration window = const Duration(hours: 24),
  }) {
    double height(DateTime at) => TidalForcing.at(
      at,
      latitude: latitude,
      longitude: longitude,
    ).equilibriumMetres;

    final found = <TidalExtreme>[];
    const step = 10;
    var previous = height(from);
    var current = height(from.add(const Duration(minutes: step)));
    for (var m = step; m < window.inMinutes; m += step) {
      final at = from.add(Duration(minutes: m));
      final next = height(at.add(const Duration(minutes: step)));
      final risingBefore = current > previous;
      final risingAfter = next > current;
      if (risingBefore != risingAfter) {
        // Refine by golden-section on the bracketing interval.
        var lo = at.subtract(const Duration(minutes: step));
        var hi = at.add(const Duration(minutes: step));
        for (var i = 0; i < 24; i++) {
          final third = hi.difference(lo).inMilliseconds ~/ 3;
          final a = lo.add(Duration(milliseconds: third));
          final b = hi.subtract(Duration(milliseconds: third));
          final better = risingBefore
              ? height(a) > height(b)
              : height(a) < height(b);
          if (better) {
            hi = b;
          } else {
            lo = a;
          }
        }
        final peak = lo.add(
          Duration(milliseconds: hi.difference(lo).inMilliseconds ~/ 2),
        );
        found.add(
          TidalExtreme(at: peak, metres: height(peak), isHigh: risingBefore),
        );
      }
      previous = current;
      current = next;
    }
    return found;
  }

  /// The next perigean spring tide after [utc] — the highest water of the
  /// season, and the state to check a storm surge against.
  static DateTime? nextPerigeanSpring(DateTime utc, {int withinDays = 400}) {
    final limit = utc.add(Duration(days: withinDays));
    var syzygy = MoonPhase.nextNewMoon(utc);
    var full = MoonPhase.nextFullMoon(utc);
    while (syzygy.isBefore(limit) || full.isBefore(limit)) {
      final next = syzygy.isBefore(full) ? syzygy : full;
      final moon = MoonEphemeris.at(next);
      if (math.pow(_meanLunarDistanceKm / moon.distanceKm, 3) > 1.15) {
        return next;
      }
      if (syzygy.isBefore(full)) {
        syzygy = MoonPhase.nextNewMoon(syzygy.add(const Duration(days: 1)));
      } else {
        full = MoonPhase.nextFullMoon(full.add(const Duration(days: 1)));
      }
    }
    return null;
  }
}

/// A turning point of the equilibrium tide.
class TidalExtreme {
  const TidalExtreme({
    required this.at,
    required this.metres,
    required this.isHigh,
  });

  final DateTime at;
  final double metres;
  final bool isHigh;
}

/// Where in the fortnightly cycle the tide sits.
enum TidePhase { spring, middling, neap }
