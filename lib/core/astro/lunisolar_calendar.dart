/// 農曆 — the Chinese lunisolar calendar, computed rather than tabulated.
///
/// Most implementations ship a table of packed month lengths per year, copied
/// from somewhere, valid for a fixed span and unfalsifiable. This derives the
/// calendar from its actual rules, which are astronomical and which this
/// package already computes:
///
///   1. A lunar month begins on the **civil day containing the new moon**.
///   2. **冬至 always falls in month 11.** That fixes the numbering.
///   3. A 歲 runs from one month 11 to the next. If it holds 13 months, one is
///      a leap month: the **first month containing no 中氣** (a major solar
///      term, at a multiple of 30° of solar longitude). It repeats the number
///      of the month before it.
///
/// Everything is evaluated in a fixed civil zone, because "the day containing
/// the new moon" depends on where the day boundary is. Taiwan and China both
/// use UTC+8, which is why the same rules give the same calendar in both.
///
/// **Measured** against the CWA's 中華民國115年日曆資料表 in
/// `test/core/astro/` — every day of 2026, not a sample.
library;

import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/astro/solar_terms.dart';

/// The civil zone the calendar is defined in.
const Duration lunisolarZone = Duration(hours: 8);

/// The ten heavenly stems, 天干.
const List<String> heavenlyStems = [
  '甲',
  '乙',
  '丙',
  '丁',
  '戊',
  '己',
  '庚',
  '辛',
  '壬',
  '癸',
];

/// The twelve earthly branches, 地支.
const List<String> earthlyBranches = [
  '子',
  '丑',
  '寅',
  '卯',
  '辰',
  '巳',
  '午',
  '未',
  '申',
  '酉',
  '戌',
  '亥',
];

/// One date in the lunisolar calendar.
class LunisolarDate {
  const LunisolarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthLength,
  });

  /// The lunar year — the Gregorian year the lunar new year fell in, which is
  /// what 歲次 names.
  final int year;

  /// 1…12. A leap month repeats the previous month's number.
  final int month;

  /// 1…30.
  final int day;

  /// Whether this is the 閏 (intercalary) month.
  final bool isLeapMonth;

  /// 29 (小月) or 30 (大月) days.
  final int monthLength;

  /// Sexagenary index of the year, 0…59.
  int get sexagenaryIndex => ((year - 4) % 60 + 60) % 60;

  /// 歲次, e.g. `丙午`.
  String get sexagenaryYear =>
      heavenlyStems[sexagenaryIndex % 10] +
      earthlyBranches[sexagenaryIndex % 12];

  /// The zodiac animal's branch index, 0 = 鼠 … 11 = 豬.
  int get zodiacIndex => sexagenaryIndex % 12;

  /// Whether this is 正月初一 — lunar new year.
  bool get isNewYearDay => month == 1 && day == 1 && !isLeapMonth;
}

/// Deriving the lunisolar calendar.
abstract final class LunisolarCalendar {
  /// The lunisolar date of the civil day containing [utc].
  static LunisolarDate of(DateTime utc) {
    final day = _civilDay(utc);
    final suiMonths = _suiContaining(day);
    for (var i = 0; i < suiMonths.length; i++) {
      final month = suiMonths[i];
      final next = i + 1 < suiMonths.length
          ? suiMonths[i + 1].start
          : month.start.add(const Duration(days: 31));
      if (!day.isBefore(month.start) && day.isBefore(next)) {
        return LunisolarDate(
          year: _lunarYearOf(month, suiMonths),
          month: month.number,
          day: day.difference(month.start).inDays + 1,
          isLeapMonth: month.isLeap,
          monthLength: next.difference(month.start).inDays,
        );
      }
    }
    // Unreachable: the 歲 by construction spans the day it was built around.
    throw StateError('no lunar month contains $day');
  }

  /// The civil (UTC+8) midnight beginning the day that contains [utc], as a
  /// UTC instant.
  static DateTime _civilDay(DateTime utc) {
    final local = utc.add(lunisolarZone);
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).subtract(lunisolarZone);
  }

  /// The new moon at or before [utc], as the civil day it falls on.
  static DateTime _newMoonDayAtOrBefore(DateTime utc) {
    // Step back far enough to be certain of landing before it, then walk
    // forward one lunation at a time.
    var candidate = MoonPhase.nextNewMoon(
      utc.subtract(const Duration(days: 40)),
    );
    var day = _civilDay(candidate);
    while (true) {
      final nextMoon = MoonPhase.nextNewMoon(candidate);
      final nextDay = _civilDay(nextMoon);
      if (nextDay.isAfter(utc)) return day;
      candidate = nextMoon;
      day = nextDay;
    }
  }

  /// The winter solstice at or before [utc].
  static DateTime _solsticeAtOrBefore(DateTime utc) {
    var candidate = SolarTerms.next(
      utc.subtract(const Duration(days: 400)),
      SolarTerm.winterSolstice,
    );
    while (true) {
      final next = SolarTerms.next(candidate, SolarTerm.winterSolstice);
      if (next.isAfter(utc)) return candidate;
      candidate = next;
    }
  }

  /// The months of the 歲 containing [day], numbered and leap-marked.
  static List<_Month> _suiContaining(DateTime day) {
    // Month 11 of this 歲 begins on the new-moon day at or before the winter
    // solstice that opens it. If the day is before that month started, the
    // relevant 歲 is the previous one.
    var solstice = _solsticeAtOrBefore(day.add(const Duration(days: 1)));
    var start = _newMoonDayAtOrBefore(solstice);
    if (day.isBefore(start)) {
      solstice = _solsticeAtOrBefore(
        solstice.subtract(const Duration(days: 1)),
      );
      start = _newMoonDayAtOrBefore(solstice);
    }
    final nextSolstice = SolarTerms.next(solstice, SolarTerm.winterSolstice);
    final end = _newMoonDayAtOrBefore(nextSolstice);

    // Every new-moon day from this month 11 up to (and including) the next.
    final starts = <DateTime>[start];
    var moon = MoonPhase.nextNewMoon(start.add(const Duration(days: 1)));
    while (true) {
      final moonDay = _civilDay(moon);
      starts.add(moonDay);
      if (!moonDay.isBefore(end)) break;
      moon = MoonPhase.nextNewMoon(moon.add(const Duration(days: 1)));
    }

    // The 歲 is the months from the first up to but not including the last —
    // the last is month 11 of the following 歲.
    final span = starts.length - 1;
    final leapIndex = span == 13 ? _leapIndex(starts) : -1;

    final months = <_Month>[];
    var number = 11;
    for (var i = 0; i < span; i++) {
      final isLeap = i == leapIndex;
      if (!isLeap && i > 0) number = number % 12 + 1;
      months.add(
        _Month(start: starts[i], number: number, isLeap: isLeap),
      );
    }
    // Keep the following month 11 so the caller can measure the last month's
    // length without recomputing the next 歲.
    months.add(_Month(start: starts[span], number: 11, isLeap: false));
    return months;
  }

  /// The first month of a thirteen-month 歲 that contains no 中氣.
  ///
  /// Month 11 itself always contains 冬至, so the search starts after it. If
  /// no month qualifies — which the rules make impossible but floating point
  /// does not — the last candidate is taken, so the calendar stays consistent
  /// rather than throwing.
  static int _leapIndex(List<DateTime> starts) {
    for (var i = 1; i < starts.length - 1; i++) {
      if (!_containsMajorTerm(starts[i], starts[i + 1])) return i;
    }
    return starts.length - 2;
  }

  /// Whether a 中氣 falls in `[from, to)`.
  static bool _containsMajorTerm(DateTime from, DateTime to) {
    for (final term in SolarTerm.values) {
      if (!term.isMajor) continue;
      final at = SolarTerms.next(from.subtract(const Duration(days: 1)), term);
      if (!at.isBefore(from) && at.isBefore(to)) return true;
    }
    return false;
  }

  /// The lunar year a month belongs to: the Gregorian year in which that
  /// year's 正月初一 fell.
  static int _lunarYearOf(_Month month, List<_Month> sui) {
    // Months 11 and 12 of a 歲 belong to the year that began earlier; months
    // 1 onward belong to the year beginning with this 歲's month 1.
    final firstMonth = sui.firstWhere(
      (m) => m.number == 1 && !m.isLeap,
      orElse: () => sui.first,
    );
    final newYear = firstMonth.start.add(lunisolarZone).year;
    return month.start.isBefore(firstMonth.start) ? newYear - 1 : newYear;
  }
}

class _Month {
  const _Month({
    required this.start,
    required this.number,
    required this.isLeap,
  });

  /// UTC instant of the civil midnight the month begins on.
  final DateTime start;
  final int number;
  final bool isLeap;
}
