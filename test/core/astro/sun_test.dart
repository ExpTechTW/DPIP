/// Golden pins for the Sun: position, daylight, and the solar terms.
///
/// Three authorities, each checking something the others cannot:
///
///   * **JPL Horizons** for the ecliptic longitude and distance.
///   * **The CWA's published 2026 sunrise/sunset timetable** for Keelung —
///     the table a user in Taiwan would compare this app against.
///   * **The CWA's 中華民國115年日曆資料表** for the twenty-four solar terms.
///     Every term is checked, not a sample, because a term is defined by an
///     exact solar longitude and a wrong one would mean the search, not the
///     data, is broken.
///
/// The published tables give minutes, so a one-minute disagreement is their
/// rounding. Sunrise and sunset matched Keelung exactly on all six sampled
/// dates; the solar term *dates* all match, while the term *instants* are
/// good to a few minutes — the low-precision solar series is 0.01° in
/// longitude and the Sun takes about 14 minutes to move that far.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/solar_terms.dart';
import 'package:dpip/core/astro/sun_ephemeris.dart';
import 'package:dpip/core/astro/sun_events.dart';
import 'package:flutter_test/flutter_test.dart';

const _taiwan = Duration(hours: 8);
const _keelung = (latitude: 25.1276, longitude: 121.7392);
const _taipei = (latitude: 25.0330, longitude: 121.5654);
const _reykjavik = (latitude: 64.1466, longitude: -21.9426);

/// Longyearbyen — inside the Arctic Circle, where the Sun really does stay up.
const _svalbard = (latitude: 78.2232, longitude: 15.6469);

double _deg(double radians) => radians * 180 / math.pi;
double _wrap180(double d) => ((d + 180) % 360 + 360) % 360 - 180;

String _clock(DateTime? utc, Duration offset) {
  if (utc == null) return '--:--';
  final local = utc.add(offset);
  final rounded = local.second >= 30
      ? local.add(const Duration(minutes: 1))
      : local;
  return '${rounded.hour.toString().padLeft(2, '0')}:'
      '${rounded.minute.toString().padLeft(2, '0')}';
}

SunEvents _localDay(
  int year,
  int month,
  int day,
  Duration offset,
  ({double latitude, double longitude}) place,
) => SunEvents.of(
  DateTime.utc(year, month, day).subtract(offset),
  latitude: place.latitude,
  longitude: place.longitude,
);

void main() {
  group('SunEphemeris', () {
    test('tracks JPL Horizons', () {
      // Geocentric, ecliptic of date, from ssd.jpl.nasa.gov/api/horizons.api.
      const rows = <(String, double, double)>[
        ('2024-01-01T00:00', 280.0389812, 0.98331828),
        ('2025-04-12T21:00', 23.1955460, 1.00255629),
        ('2026-08-11T04:00', 138.5283440, 1.01355338),
        ('2026-12-27T17:00', 275.9471970, 0.98343175),
      ];
      for (final (stamp, longitude, distanceAu) in rows) {
        final sun = SunEphemeris.at(DateTime.parse('${stamp}Z'));
        expect(
          _wrap180(_deg(sun.longitude) - longitude).abs() * 3600,
          lessThan(35),
          reason: 'longitude at $stamp',
        );
        expect(
          (sun.distanceKm / astronomicalUnitKm - distanceAu).abs(),
          lessThan(0.0001),
          reason: 'distance at $stamp',
        );
      }
    });

    test('the equation of time has its four known turning points', () {
      // ~-14.2 min in mid-February, +3.7 in mid-May, -6.5 in late July,
      // +16.4 in early November. These are the analemma's corners, and a sign
      // error or a swapped term moves them somewhere else entirely.
      const points = <(int, int, double)>[
        (2, 11, -14.2),
        (5, 14, 3.7),
        (7, 26, -6.5),
        (11, 3, 16.4),
      ];
      for (final (month, day, expected) in points) {
        final minutes =
            SunEphemeris.at(DateTime.utc(2026, month, day, 12))
                .equationOfTime
                .inSeconds /
            60;
        expect(minutes, closeTo(expected, 0.3), reason: '$month/$day');
      }
    });
  });

  group('SunEvents', () {
    test('matches the CWA 2026 timetable for Keelung', () {
      // 中華民國115年日出日沒時刻表.
      const rows = <(int, int, String, String)>[
        (1, 1, '06:38', '17:15'),
        (2, 1, '06:36', '17:37'),
        (3, 1, '06:16', '17:55'),
        (4, 1, '05:45', '18:09'),
        (5, 1, '05:18', '18:23'),
        (6, 1, '05:03', '18:39'),
      ];
      for (final (month, day, rise, set) in rows) {
        final events = _localDay(2026, month, day, _taiwan, _keelung);
        expect(_clock(events.rise, _taiwan), rise, reason: '$month/$day rise');
        expect(_clock(events.set, _taiwan), set, reason: '$month/$day set');
      }
    });

    test('twilight is ordered, and deeper twilights are further out', () {
      final events = _localDay(2026, 8, 15, _taiwan, _taipei);
      final morning = [
        events.astronomicalDawn!,
        events.nauticalDawn!,
        events.civilDawn!,
        events.rise!,
      ];
      for (var i = 1; i < morning.length; i++) {
        expect(morning[i].isAfter(morning[i - 1]), isTrue, reason: 'dawn $i');
      }
      final evening = [
        events.set!,
        events.civilDusk!,
        events.nauticalDusk!,
        events.astronomicalDusk!,
      ];
      for (var i = 1; i < evening.length; i++) {
        expect(evening[i].isAfter(evening[i - 1]), isTrue, reason: 'dusk $i');
      }
    });

    test('golden hour brackets sunrise and sunset', () {
      // The band is -4° to +6°, so it opens before the Sun is up and closes
      // after it. A golden hour entirely after sunrise would mean the
      // thresholds were applied to the wrong side of the horizon.
      final events = _localDay(2026, 8, 15, _taiwan, _taipei);
      expect(events.blueMorningStart!.isBefore(events.rise!), isTrue);
      expect(events.goldenMorningEnd!.isAfter(events.rise!), isTrue);
      expect(events.goldenEveningStart!.isBefore(events.set!), isTrue);
      expect(events.blueEveningEnd!.isAfter(events.set!), isTrue);
    });

    test('day length is longest at the summer solstice', () {
      final june = _localDay(2026, 6, 21, _taiwan, _taipei).dayLength;
      final december = _localDay(2026, 12, 21, _taiwan, _taipei).dayLength;
      final march = _localDay(2026, 3, 20, _taiwan, _taipei).dayLength;
      expect(june.inMinutes, greaterThan(december.inMinutes));
      // At Taipei's latitude the swing is about 3 hours; at the equinox the
      // day is a little over 12 hours, because "sunrise" is the upper limb
      // and refraction lifts it early at both ends.
      expect(march.inMinutes / 60, closeTo(12.14, 0.1));
      expect((june - december).inMinutes / 60, closeTo(2.9, 0.3));
    });

    test('polar day and polar night are answers, not missing ones', () {
      // Longyearbyen at midsummer: the Sun does not set. Null rise and null
      // set is correct, and the day length has to resolve to the full window
      // rather than to zero or to a crash. Midwinter is the mirror.
      final midsummer = _localDay(2026, 6, 21, Duration.zero, _svalbard);
      expect(midsummer.rise, isNull);
      expect(midsummer.set, isNull);
      expect(midsummer.startsAbove, isTrue);
      expect(midsummer.dayLength, const Duration(hours: 24));

      final midwinter = _localDay(2026, 12, 21, Duration.zero, _svalbard);
      expect(midwinter.rise, isNull);
      expect(midwinter.set, isNull);
      expect(midwinter.startsAbove, isFalse);
      expect(midwinter.dayLength, Duration.zero);
    });

    test('a summer night at 64°N never gets astronomically dark', () {
      // Reykjavík is *below* the Arctic Circle, so the Sun sets — but only
      // just, and it never reaches 18° down. An observing window computed from
      // sunset alone would claim a dark night that does not exist.
      final midsummer = _localDay(2026, 6, 21, Duration.zero, _reykjavik);
      expect(midsummer.set, isNotNull);
      expect(midsummer.astronomicalDusk, isNull);
      expect(midsummer.astronomicalNight, isNull);
    });

    test('solar noon is not clock noon', () {
      // Taipei sits 1.5° east of the 120°E timezone meridian, worth about 6
      // minutes, and the equation of time adds up to another 16. If solar noon
      // came out at 12:00 the calculation would be a clock, not the Sun.
      final events = _localDay(2026, 11, 3, _taiwan, _taipei);
      final local = events.noon!.add(_taiwan);
      final offsetMinutes = local.hour * 60 + local.minute - 12 * 60;
      expect(offsetMinutes, lessThan(-15));
      expect(offsetMinutes, greaterThan(-30));
    });
  });

  group('SolarTerms', () {
    test('every 2026 term lands on the date the CWA publishes', () {
      // 中華民國115年日曆資料表, all twenty-four.
      const expected = <(SolarTerm, int, int)>[
        (SolarTerm.minorCold, 1, 5),
        (SolarTerm.majorCold, 1, 20),
        (SolarTerm.startOfSpring, 2, 4),
        (SolarTerm.rainWater, 2, 18),
        (SolarTerm.awakeningOfInsects, 3, 5),
        (SolarTerm.vernalEquinox, 3, 20),
        (SolarTerm.pureBrightness, 4, 5),
        (SolarTerm.grainRain, 4, 20),
        (SolarTerm.startOfSummer, 5, 5),
        (SolarTerm.grainFull, 5, 21),
        (SolarTerm.grainInEar, 6, 5),
        (SolarTerm.summerSolstice, 6, 21),
        (SolarTerm.minorHeat, 7, 7),
        (SolarTerm.majorHeat, 7, 23),
        (SolarTerm.startOfAutumn, 8, 7),
        (SolarTerm.endOfHeat, 8, 23),
        (SolarTerm.whiteDew, 9, 7),
        (SolarTerm.autumnalEquinox, 9, 23),
        (SolarTerm.coldDew, 10, 8),
        (SolarTerm.frostDescent, 10, 23),
        (SolarTerm.startOfWinter, 11, 7),
        (SolarTerm.minorSnow, 11, 22),
        (SolarTerm.majorSnow, 12, 7),
        (SolarTerm.winterSolstice, 12, 22),
      ];
      final found = {
        for (final (term, at) in SolarTerms.ofYear(2026, offset: _taiwan))
          term: at.add(_taiwan),
      };
      expect(found, hasLength(24));
      for (final (term, month, day) in expected) {
        expect(found[term]!.month, month, reason: '${term.name} month');
        expect(found[term]!.day, day, reason: '${term.name} day');
      }
    });

    test('a term is the instant the Sun reaches an exact longitude', () {
      // The definition, and the only way to know the search converged rather
      // than merely returned something plausible.
      for (final term in SolarTerm.values) {
        final at = SolarTerms.next(DateTime.utc(2026), term);
        final error = signedTurn(
          SunEphemeris.at(at).longitude - term.longitudeDegrees * degrees,
        );
        expect(
          _deg(error).abs() * 3600,
          lessThan(1),
          reason: '${term.name} convergence',
        );
      }
    });

    test('the cardinal terms are the solstices and equinoxes', () {
      expect(SolarTerm.values.where((t) => t.isCardinal).toList(), [
        SolarTerm.vernalEquinox,
        SolarTerm.summerSolstice,
        SolarTerm.autumnalEquinox,
        SolarTerm.winterSolstice,
      ]);
      // The equinox is where the Sun crosses the celestial equator, so its
      // declination is zero there — a check independent of the search itself.
      final equinox = SolarTerms.next(
        DateTime.utc(2026),
        SolarTerm.vernalEquinox,
      );
      expect(
        _deg(SunEphemeris.at(equinox).equatorial.declination).abs(),
        lessThan(0.01),
      );
    });

    test(
      'the major terms are the twelve that anchor the lunisolar calendar',
      () {
        final major = SolarTerm.values.where((t) => t.isMajor).toList();
        expect(major, hasLength(12));
        expect(major.every((t) => t.longitudeDegrees % 30 == 0), isTrue);
        expect(major.contains(SolarTerm.winterSolstice), isTrue);
      },
    );

    test('successive occurrences are a tropical year apart', () {
      // Walking the calendar is what a year view does, and a search that
      // quietly returned its own input would stall there.
      var previous = SolarTerms.next(
        DateTime.utc(2026),
        SolarTerm.winterSolstice,
      );
      for (var year = 0; year < 8; year++) {
        final next = SolarTerms.next(
          previous.add(const Duration(days: 1)),
          SolarTerm.winterSolstice,
        );
        expect(next.difference(previous).inHours / 24, closeTo(365.24, 0.6));
        previous = next;
      }
    });

    test('every search result is strictly after its starting point', () {
      for (final term in SolarTerm.values) {
        final at = SolarTerms.next(DateTime.utc(2026), term);
        expect(SolarTerms.next(at, term).isAfter(at), isTrue);
      }
    });
  });
}
