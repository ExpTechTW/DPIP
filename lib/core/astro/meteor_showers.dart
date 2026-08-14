/// The major meteor showers, and whether tonight is worth staying up for.
///
/// The table is tiny — a dozen radiants and peak dates — but the useful part
/// is not the table. It is the two things that decide whether a shower is
/// worth watching from *here*, both of which this package already computes:
///
///   * **Radiant altitude.** Rates fall roughly as the sine of the radiant's
///     height. A shower whose radiant never rises above the horizon at your
///     latitude produces nothing, however famous it is.
///   * **Moonlight.** A full moon at the peak wipes out all but the brightest
///     meteors. This is the single most common reason a "great shower" turns
///     out to be a disappointment, and it is knowable months ahead.
///
/// So a shower gets a computed condition rather than a ZHR number that implies
/// a promise. ZHR is a *zenithal* rate under a dark sky — it is the ceiling,
/// almost never the observation.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/moon_ephemeris.dart';
import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:dpip/core/astro/sky_position.dart';

/// One shower's fixed properties.
class MeteorShower {
  const MeteorShower({
    required this.id,
    required this.peakMonth,
    required this.peakDay,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.rightAscensionJ2000,
    required this.declinationJ2000,
    required this.zenithalRate,
    required this.velocityKmS,
  });

  /// A stable key for localisation — never shown raw.
  final String id;

  /// Peak date. Showers drift by a day or so between years; the radiant and
  /// the date are conventional, not computed.
  final int peakMonth;
  final int peakDay;

  /// The span over which the shower is active at all.
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  /// Radiant, J2000 degrees.
  final double rightAscensionJ2000;
  final double declinationJ2000;

  /// Zenithal hourly rate at maximum, under a dark sky with the radiant
  /// overhead — a ceiling, not a forecast.
  final int zenithalRate;

  /// Entry speed, km/s. Fast showers give brighter, shorter trails.
  final double velocityKmS;

  /// The radiant's position, precessed to the equinox of date.
  Equatorial radiantAt(DateTime utc) {
    final t = julianCenturies(utc) * 100;
    final ra = rightAscensionJ2000 * degrees;
    final dec = declinationJ2000 * degrees;
    return Equatorial(
      rightAscension: turn(
        ra +
            (3.07496 + 1.33621 * math.sin(ra) * math.tan(dec)) *
                t *
                15 /
                3600 *
                degrees,
      ),
      declination: dec + 20.0431 * math.cos(ra) * t / 3600 * degrees,
    );
  }

  /// The peak instant in [year], as a UTC time. Conventional to the day; the
  /// hour is taken as local midnight, when radiants are typically highest.
  DateTime peakOf(int year, {Duration zone = const Duration(hours: 8)}) =>
      DateTime.utc(year, peakMonth, peakDay).subtract(zone);
}

/// How good a shower will actually be from one place.
class ShowerConditions {
  const ShowerConditions({
    required this.shower,
    required this.peak,
    required this.bestTime,
    required this.bestAltitude,
    required this.moonIllumination,
    required this.moonIsUp,
  });

  final MeteorShower shower;
  final DateTime peak;

  /// When the radiant is highest during the dark hours around the peak.
  final DateTime bestTime;

  /// The radiant's altitude then, radians. Negative means it never rises.
  final double bestAltitude;

  /// The Moon's illuminated fraction at the peak.
  final double moonIllumination;

  /// Whether the Moon is above the horizon at [bestTime].
  final bool moonIsUp;

  /// An estimate of the rate actually visible, meteors per hour.
  ///
  /// The ZHR scaled by the sine of the radiant's altitude, then cut by
  /// moonlight. Both factors are approximations of a messy reality — this is
  /// an expectation, not a measurement, and it is deliberately pessimistic
  /// about the Moon because that is the way disappointment runs.
  double get visibleRate {
    if (bestAltitude <= 0) return 0;
    final geometry = math.sin(bestAltitude);
    final moon = moonIsUp ? 1 - 0.8 * moonIllumination : 1.0;
    return shower.zenithalRate * geometry * moon;
  }

  /// Better than a third of the theoretical rate, and the radiant well up.
  bool get isFavourable => visibleRate >= shower.zenithalRate / 3;
}

/// The showers worth listing, by peak date through the year.
///
/// Rates and radiants follow the IMO's working list of visual showers.
const List<MeteorShower> meteorShowers = [
  MeteorShower(
    id: 'quadrantids',
    peakMonth: 1,
    peakDay: 3,
    startMonth: 12,
    startDay: 28,
    endMonth: 1,
    endDay: 12,
    rightAscensionJ2000: 230.0,
    declinationJ2000: 49.0,
    zenithalRate: 110,
    velocityKmS: 41,
  ),
  MeteorShower(
    id: 'lyrids',
    peakMonth: 4,
    peakDay: 22,
    startMonth: 4,
    startDay: 14,
    endMonth: 4,
    endDay: 30,
    rightAscensionJ2000: 271.0,
    declinationJ2000: 34.0,
    zenithalRate: 18,
    velocityKmS: 49,
  ),
  MeteorShower(
    id: 'etaAquariids',
    peakMonth: 5,
    peakDay: 6,
    startMonth: 4,
    startDay: 19,
    endMonth: 5,
    endDay: 28,
    rightAscensionJ2000: 338.0,
    declinationJ2000: -1.0,
    zenithalRate: 50,
    velocityKmS: 66,
  ),
  MeteorShower(
    id: 'deltaAquariids',
    peakMonth: 7,
    peakDay: 30,
    startMonth: 7,
    startDay: 12,
    endMonth: 8,
    endDay: 23,
    rightAscensionJ2000: 340.0,
    declinationJ2000: -16.0,
    zenithalRate: 25,
    velocityKmS: 41,
  ),
  MeteorShower(
    id: 'perseids',
    peakMonth: 8,
    peakDay: 12,
    startMonth: 7,
    startDay: 17,
    endMonth: 8,
    endDay: 24,
    rightAscensionJ2000: 48.0,
    declinationJ2000: 58.0,
    zenithalRate: 100,
    velocityKmS: 59,
  ),
  MeteorShower(
    id: 'orionids',
    peakMonth: 10,
    peakDay: 21,
    startMonth: 10,
    startDay: 2,
    endMonth: 11,
    endDay: 7,
    rightAscensionJ2000: 95.0,
    declinationJ2000: 16.0,
    zenithalRate: 20,
    velocityKmS: 66,
  ),
  MeteorShower(
    id: 'southernTaurids',
    peakMonth: 11,
    peakDay: 5,
    startMonth: 9,
    startDay: 10,
    endMonth: 11,
    endDay: 20,
    rightAscensionJ2000: 52.0,
    declinationJ2000: 15.0,
    zenithalRate: 5,
    velocityKmS: 27,
  ),
  MeteorShower(
    id: 'leonids',
    peakMonth: 11,
    peakDay: 17,
    startMonth: 11,
    startDay: 6,
    endMonth: 11,
    endDay: 30,
    rightAscensionJ2000: 152.0,
    declinationJ2000: 22.0,
    zenithalRate: 15,
    velocityKmS: 71,
  ),
  MeteorShower(
    id: 'geminids',
    peakMonth: 12,
    peakDay: 14,
    startMonth: 12,
    startDay: 4,
    endMonth: 12,
    endDay: 20,
    rightAscensionJ2000: 112.0,
    declinationJ2000: 33.0,
    zenithalRate: 150,
    velocityKmS: 35,
  ),
  MeteorShower(
    id: 'ursids',
    peakMonth: 12,
    peakDay: 22,
    startMonth: 12,
    startDay: 17,
    endMonth: 12,
    endDay: 26,
    rightAscensionJ2000: 217.0,
    declinationJ2000: 76.0,
    zenithalRate: 10,
    velocityKmS: 33,
  ),
];

/// Working out how a shower will go.
abstract final class MeteorShowerConditions {
  /// Conditions for [shower] at its peak in [year], from this place.
  ///
  /// The best moment is found by scanning the night around the peak rather
  /// than assumed to be midnight: a radiant that rises at 02:00 is best just
  /// before dawn, and saying "midnight" would be wrong by hours.
  static ShowerConditions of(
    MeteorShower shower,
    int year, {
    required double latitude,
    required double longitude,
    Duration zone = const Duration(hours: 8),
  }) {
    final peak = shower.peakOf(year, zone: zone);
    final observer = Observer(latitude: latitude, longitude: longitude);

    var bestTime = peak;
    var bestAltitude = -math.pi;
    // The night either side of local midnight at the peak.
    for (var minutes = -8 * 60; minutes <= 8 * 60; minutes += 15) {
      final at = peak.add(Duration(minutes: minutes));
      final altitude = observer
          .lookAt(shower.radiantAt(at), at)
          .altitude;
      if (altitude > bestAltitude) {
        bestAltitude = altitude;
        bestTime = at;
      }
    }

    return ShowerConditions(
      shower: shower,
      peak: peak,
      bestTime: bestTime,
      bestAltitude: bestAltitude,
      moonIllumination: MoonEphemeris.at(peak).illuminated,
      moonIsUp: MoonRiseSet.aboveHorizon(
        bestTime,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// Showers active on [utc], soonest peak first.
  static List<MeteorShower> activeOn(DateTime utc) {
    final month = utc.month;
    final day = utc.day;
    bool covers(MeteorShower s) {
      final from = s.startMonth * 100 + s.startDay;
      final to = s.endMonth * 100 + s.endDay;
      final now = month * 100 + day;
      // A shower can straddle the new year, so the window may wrap.
      return from <= to ? now >= from && now <= to : now >= from || now <= to;
    }

    return meteorShowers.where(covers).toList();
  }
}
