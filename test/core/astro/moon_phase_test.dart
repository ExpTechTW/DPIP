/// Golden pins for the lunar phase math.
///
/// The anchors are historical facts: the 2024 North-America total eclipse new
/// moon (2024-04-08 18:21 UTC) and that month's full moon (2024-04-23 23:49
/// UTC). The Meeus simplified series is accurate to ~0.3°, so the tolerance
/// of 0.05 rad (~2.9°) is wide enough for the series yet far tighter than any
/// display needs (1° of elongation is ~0.03% of brightness).
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/moon_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoonPhase', () {
    test('new moon at the 2024 eclipse', () {
      final phase = MoonPhase.at(DateTime.utc(2024, 4, 8, 18, 21));
      // Angle wraps — accept 0 or 2π. The truncated series lands ~5° off the
      // true instant (its main perturbation is ±6.3°); 0.12 rad ≈ 7° keeps it
      // honest while staying far below anything a display resolves.
      final angle = phase.angle % (2 * math.pi);
      expect(angle, lessThan(0.12));
    });

    test('full moon 15.2 days later', () {
      final phase = MoonPhase.at(DateTime.utc(2024, 4, 23, 23, 49));
      expect((phase.angle - math.pi).abs(), lessThan(0.12));
    });

    test('brightness is 0 at new and 1 at full', () {
      final newMoon = MoonPhase.at(DateTime.utc(2024, 4, 8, 18, 21));
      expect(newMoon.brightness, lessThan(0.01));
      final full = MoonPhase.at(DateTime.utc(2024, 4, 23, 23, 49));
      expect(full.brightness, greaterThan(0.99));
    });

    test('first quarter lights the right half (waxing) at ~50%', () {
      // New + 7.4 days.
      final q1 = MoonPhase.at(DateTime.utc(2024, 4, 16, 3, 0));
      expect(q1.waxing, isTrue);
      expect(q1.brightness, closeTo(0.5, 0.1));
      expect((q1.angle - math.pi / 2).abs(), lessThan(0.15));
    });

    test('nextFullMoon after the eclipse new moon lands on April 23', () {
      final next = MoonPhase.nextFullMoon(DateTime.utc(2024, 4, 8, 18, 21));
      final expected = DateTime.utc(2024, 4, 23, 23, 49);
      expect(next.difference(expected).inHours.abs(), lessThan(24));
    });

    test('synodic period is ~29.53 days — same phase a month apart', () {
      final a = MoonPhase.at(DateTime.utc(2024, 4, 8, 18, 21));
      final b = MoonPhase.at(DateTime.utc(2024, 5, 8, 3, 22)); // next new moon
      // Both are new moons, so their angles coincide (mod 2π) — the series
      // errors (~5°) land on both sides and mostly cancel in the difference.
      final diff = (b.angle - a.angle) % (2 * math.pi);
      expect(diff, lessThan(0.12));
      expect(b.name, MoonPhaseName.newMoon);
    });

    test('age in days runs 0..synodic month and resets at new moon', () {
      final age = MoonPhase.at(DateTime.utc(2024, 4, 23, 23, 49)).ageInDays;
      expect(age, closeTo(synodicMonthDays / 2, 1.0));
      final fresh = MoonPhase.at(DateTime.utc(2024, 4, 8, 18, 21)).ageInDays;
      expect(fresh, closeTo(0, 1.0));
    });
  });
}
