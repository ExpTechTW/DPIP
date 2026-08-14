/// Golden pins for 農曆, against the CWA's own published calendar.
///
/// Two independent things are checked, because the calendar has two halves
/// that fail differently:
///
///   * **Day-to-day mapping** — anchors spanning all twelve months of 2026,
///     taken from 中華民國115年日曆資料表, including every month boundary. A
///     new-moon rounding error moves a boundary by one day and nothing else
///     would notice.
///   * **The leap rule** — the CWA states which years carry a 閏月 and which
///     month it is, for 2015 through 2028. That is the part a packed lookup
///     table would get right by construction and a derived calendar has to
///     actually earn: 2017 閏6, 2020 閏4, 2023 閏2, 2025 閏6, 2028 閏5, and
///     nothing in the other years.
library;

import 'package:dpip/core/astro/lunisolar_calendar.dart';
import 'package:dpip/core/astro/solar_terms.dart';
import 'package:flutter_test/flutter_test.dart';

const _zone = Duration(hours: 8);

LunisolarDate _on(int year, int month, int day) =>
    LunisolarCalendar.of(DateTime.utc(year, month, day, 12).subtract(_zone));

void main() {
  group('LunisolarCalendar', () {
    test('matches the CWA 2026 calendar, month boundaries included', () {
      // (Gregorian month, day, lunar month, lunar day).
      const anchors = <(int, int, int, int)>[
        (1, 1, 11, 13),
        (1, 17, 11, 29),
        (1, 18, 11, 30),
        (1, 19, 12, 1),
        (2, 1, 12, 14),
        (2, 16, 12, 29),
        (2, 17, 1, 1), // 春節
        (3, 1, 1, 13),
        (3, 18, 1, 30),
        (3, 19, 2, 1),
        (4, 1, 2, 14),
        (4, 16, 2, 29),
        (4, 17, 3, 1),
        (5, 1, 3, 15),
        (6, 1, 4, 16),
        (6, 14, 4, 29),
        (6, 15, 5, 1),
        (7, 1, 5, 17),
        (7, 13, 5, 29),
        (7, 14, 6, 1),
        (8, 1, 6, 19),
        (8, 12, 6, 30),
        (8, 13, 7, 1),
        (9, 1, 7, 20),
        (9, 10, 7, 29),
        (9, 11, 8, 1),
        (10, 1, 8, 21),
        (10, 9, 8, 29),
        (10, 10, 9, 1),
        (11, 1, 9, 23),
        (11, 8, 9, 30),
        (11, 9, 10, 1),
        (12, 1, 10, 23),
        (12, 8, 10, 30),
        (12, 9, 11, 1),
        (12, 22, 11, 14),
        (12, 31, 11, 23),
      ];
      for (final (month, day, lunarMonth, lunarDay) in anchors) {
        final lunar = _on(2026, month, day);
        expect(
          (lunar.month, lunar.day),
          (lunarMonth, lunarDay),
          reason: '2026-$month-$day',
        );
        expect(lunar.isLeapMonth, isFalse, reason: '2026 has no leap month');
      }
    });

    test('春節 2026 is 2/17, and it is the only 正月初一 that year', () {
      expect(_on(2026, 2, 17).isNewYearDay, isTrue);
      var newYears = 0;
      for (var day = 0; day < 365; day++) {
        final date = LunisolarCalendar.of(
          DateTime.utc(2026, 1, 1, 12).add(Duration(days: day)).subtract(_zone),
        );
        if (date.isNewYearDay) newYears++;
      }
      expect(newYears, 1);
    });

    test('歲次 and the zodiac follow the sexagenary cycle', () {
      // The CWA names 2026 農曆歲次丙午年 — the year of the horse.
      final year = _on(2026, 6, 1);
      expect(year.year, 2026);
      expect(year.sexagenaryYear, '丙午');
      expect(year.zodiacIndex, 6); // 午, the horse
      // 2025 is 乙巳 (snake), 2027 丁未 (goat).
      expect(_on(2025, 6, 1).sexagenaryYear, '乙巳');
      expect(_on(2027, 6, 1).sexagenaryYear, '丁未');
    });

    test('the leap month is where the CWA says it is, 2015-2028', () {
      // Null means the CWA lists no 閏月 for that lunar year.
      const published = <int, int?>{
        2015: null,
        2016: null,
        2017: 6,
        2018: null,
        2019: null,
        2020: 4,
        2021: null,
        2022: null,
        2023: 2,
        2024: null,
        2025: 6,
        2026: null,
        2027: null,
        2028: 5,
      };
      for (final entry in published.entries) {
        int? leap;
        // Walk the lunar year from its 正月初一 forward; a leap month, if any,
        // shows up as a repeated number flagged 閏.
        for (var day = 0; day < 400; day++) {
          final date = LunisolarCalendar.of(
            DateTime.utc(
              entry.key,
              1,
              20,
              12,
            ).add(Duration(days: day)).subtract(_zone),
          );
          if (date.year != entry.key) continue;
          if (date.isLeapMonth) {
            leap = date.month;
            break;
          }
        }
        expect(leap, entry.value, reason: '${entry.key} leap month');
      }
    });

    test('a leap year runs 383-385 days and a common year 353-355', () {
      // The CWA gives 384 days for 2017/2020/2023/2025/2028 and 354-355 for
      // the rest, which is the same statement as the leap rule seen from the
      // other end.
      int lengthOf(int lunarYear) {
        var start = DateTime.utc(lunarYear, 1, 1, 12).subtract(_zone);
        while (!LunisolarCalendar.of(start).isNewYearDay) {
          start = start.add(const Duration(days: 1));
        }
        var end = start.add(const Duration(days: 300));
        while (!LunisolarCalendar.of(end).isNewYearDay) {
          end = end.add(const Duration(days: 1));
        }
        return end.difference(start).inDays;
      }

      expect(lengthOf(2026), inInclusiveRange(353, 355));
      expect(lengthOf(2025), inInclusiveRange(383, 385));
      expect(lengthOf(2017), inInclusiveRange(383, 385));
    });

    test('冬至 always falls in month 11 — the rule the numbering rests on', () {
      // Checked over twenty years, because this is the invariant that decides
      // every other month number. If it ever slips, the whole year is wrong
      // and nothing else in the calendar would flag it.
      for (var year = 2015; year <= 2035; year++) {
        final solstice = SolarTerms.next(
          DateTime.utc(year, 11, 1),
          SolarTerm.winterSolstice,
        );
        final lunar = LunisolarCalendar.of(solstice);
        expect(lunar.month, 11, reason: 'winter solstice $year');
        expect(lunar.isLeapMonth, isFalse);
      }
    });

    test('months are 29 or 30 days, and days never leave that range', () {
      var seen29 = false;
      var seen30 = false;
      for (var day = 0; day < 800; day++) {
        final date = LunisolarCalendar.of(
          DateTime.utc(2025, 1, 1, 12).add(Duration(days: day)).subtract(_zone),
        );
        expect(date.monthLength, anyOf(29, 30));
        expect(date.day, inInclusiveRange(1, date.monthLength));
        expect(date.month, inInclusiveRange(1, 12));
        seen29 |= date.monthLength == 29;
        seen30 |= date.monthLength == 30;
      }
      expect(seen29 && seen30, isTrue);
    });

    test('every day maps to exactly one lunar date, with no gaps', () {
      // Walking a year, the lunar day must advance by one or reset to 1 —
      // never jump. A boundary computed from the wrong new moon shows up as a
      // repeat or a skip.
      var previous = LunisolarCalendar.of(
        DateTime.utc(2025, 6, 1, 12).subtract(_zone),
      );
      for (var day = 1; day < 500; day++) {
        final date = LunisolarCalendar.of(
          DateTime.utc(2025, 6, 1, 12).add(Duration(days: day)).subtract(_zone),
        );
        final continued = date.day == previous.day + 1;
        final rolled = date.day == 1 && previous.day == previous.monthLength;
        expect(continued || rolled, isTrue, reason: 'day $day: $date');
        previous = date;
      }
    });
  });
}
