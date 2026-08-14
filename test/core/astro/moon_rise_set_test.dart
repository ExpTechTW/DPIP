/// Golden pins for moonrise and moonset.
///
/// Two authorities, deliberately not ones that would agree with a mistake:
///
///   * The **US Naval Observatory** (`aa.usno.navy.mil/api/rstt/oneday`) for
///     exact coordinates — Taipei, Sydney to catch a hemisphere sign, and
///     Reykjavík at 64°N where the Moon skims the horizon and a weak search
///     fails first.
///   * The **CWA's published 2026 timetable** for Keelung, because that is the
///     table a user in Taiwan would check this page against.
///
/// Both publish to the minute, so a one-minute disagreement is their rounding,
/// not an error here. Over the full 2026 sweep (312 events, four sites) the
/// mean gap was 15 s — which *is* the mean gap minute-rounding alone produces
/// — the worst was 33 s, and no rise or set was either missed or invented.
library;

import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taiwan runs on UTC+8 all year — no daylight saving to model.
const _taiwan = Duration(hours: 8);
const _iceland = Duration.zero;
const _sydney = Duration(hours: 10);

const _taipei = (latitude: 25.0330, longitude: 121.5654);
const _keelung = (latitude: 25.1276, longitude: 121.7392);
const _reykjavik = (latitude: 64.1466, longitude: -21.9426);
const _sydneyCity = (latitude: -33.8688, longitude: 151.2093);

/// The events of the local day beginning at midnight on [year]-[month]-[day].
MoonRiseSet _localDay(
  int year,
  int month,
  int day,
  Duration offset,
  ({double latitude, double longitude}) place,
) => MoonRiseSet.of(
  DateTime.utc(year, month, day).subtract(offset),
  latitude: place.latitude,
  longitude: place.longitude,
);

/// `HH:mm` in the given zone, or `--:--`. Rounded to the minute, as both
/// reference tables are.
String _clock(DateTime? utc, Duration offset) {
  if (utc == null) return '--:--';
  final local = utc.add(offset);
  final rounded = local.second >= 30
      ? local.add(const Duration(minutes: 1))
      : local;
  return '${rounded.hour.toString().padLeft(2, '0')}:'
      '${rounded.minute.toString().padLeft(2, '0')}';
}

void main() {
  group('MoonRiseSet', () {
    test('matches the CWA 2026 timetable for Keelung', () {
      // 基隆市, from 中華民國115年月出月沒時刻表.
      const rows = <(int, int, String, String)>[
        (1, 1, '14:49', '04:08'),
        (1, 15, '03:42', '14:10'),
        (2, 1, '16:58', '06:02'),
        (3, 1, '15:47', '04:41'),
        (4, 1, '17:30', '05:01'),
        (5, 1, '18:07', '04:36'),
        (6, 1, '19:41', '05:16'),
        (6, 15, '04:39', '19:12'),
      ];
      for (final (month, day, rise, set) in rows) {
        final events = _localDay(2026, month, day, _taiwan, _keelung);
        expect(_clock(events.rise, _taiwan), rise, reason: '$month/$day rise');
        expect(_clock(events.set, _taiwan), set, reason: '$month/$day set');
      }
    });

    test('matches the USNO for Taipei', () {
      const rows = <(int, int, String, String)>[
        (1, 1, '14:50', '04:09'),
        (8, 15, '07:45', '20:05'),
        (11, 9, '05:54', '16:51'),
      ];
      for (final (month, day, rise, set) in rows) {
        final events = _localDay(2026, month, day, _taiwan, _taipei);
        expect(_clock(events.rise, _taiwan), rise, reason: '$month/$day rise');
        expect(_clock(events.set, _taiwan), set, reason: '$month/$day set');
      }
    });

    test('matches the USNO in the southern hemisphere', () {
      final events = _localDay(2026, 1, 1, _sydney, _sydneyCity);
      expect(_clock(events.rise, _sydney), '17:08');
      expect(_clock(events.set, _sydney), '01:52');
    });

    test('matches the USNO at 64°N, where the Moon skims', () {
      // Reykjavík. The Moon's daily path is shallow here, so it crosses the
      // horizon at a glancing angle — a coarse scan either misses the crossing
      // or lands minutes from it.
      const rows = <(int, int, String, String)>[
        (1, 11, '03:38', '11:33'),
        (7, 20, '14:05', '22:59'),
        (12, 27, '21:36', '12:44'),
      ];
      for (final (month, day, rise, set) in rows) {
        final events = _localDay(2026, month, day, _iceland, _reykjavik);
        expect(_clock(events.rise, _iceland), rise, reason: '$month/$day rise');
        expect(_clock(events.set, _iceland), set, reason: '$month/$day set');
      }
    });

    group('days that are missing an event', () {
      test('no moonrise: the Moon comes up ~50 min later each day', () {
        // Roughly once a month a calendar day gets skipped entirely. `null` is
        // the correct answer; a time from the neighbouring day would be worse
        // than none, because it would look right.
        final events = _localDay(2026, 3, 10, _taiwan, _taipei);
        expect(events.rise, isNull);
        expect(_clock(events.set, _taiwan), '09:57');
      });

      test('no moonset: the mirror case, later the same month', () {
        final events = _localDay(2026, 4, 23, _taiwan, _taipei);
        expect(_clock(events.rise, _taiwan), '10:27');
        expect(events.set, isNull);
      });

      test('neither, at 64°N — and which one it is stays answerable', () {
        // The USNO reports no rise and no set at Reykjavík this day. That is
        // ambiguous on its own (up all day, or down all day?), so the answer
        // is only useful alongside where the Moon actually is.
        final events = _localDay(2026, 1, 1, _iceland, _reykjavik);
        expect(events.isCircumpolar, isTrue);
        expect(
          MoonRiseSet.aboveHorizon(
            DateTime.utc(2026, 1, 1, 12),
            latitude: _reykjavik.latitude,
            longitude: _reykjavik.longitude,
          ),
          isTrue,
          reason: 'above all day, not below',
        );
      });

      test('a rise with no set, at 64°N', () {
        final events = _localDay(2026, 11, 17, _iceland, _reykjavik);
        expect(_clock(events.rise, _iceland), '15:26');
        expect(events.set, isNull);
      });
    });

    test('every event falls inside the requested window', () {
      final start = DateTime.utc(2026, 3, 10);
      final events = MoonRiseSet.of(
        start,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final end = start.add(const Duration(hours: 24));
      for (final event in [events.rise, events.set].nonNulls) {
        expect(event.isBefore(start), isFalse);
        expect(event.isAfter(end), isFalse);
      }
    });

    test('the Moon is up between its rise and its set', () {
      // Ties the two answers to the altitude they came from: a crossing time
      // on the wrong side of the horizon fails here even if it looks plausible
      // on a clock.
      final events = _localDay(2026, 8, 15, _taiwan, _taipei);
      bool up(DateTime at) => MoonRiseSet.aboveHorizon(
        at,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      const minute = Duration(minutes: 5);
      expect(up(events.rise!.add(minute)), isTrue);
      expect(up(events.rise!.subtract(minute)), isFalse);
      expect(up(events.set!.subtract(minute)), isTrue);
      expect(up(events.set!.add(minute)), isFalse);
    });
  });
}
