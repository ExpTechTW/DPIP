/// Golden pins for the lunar phase, distance and libration readouts.
///
/// The anchors are historical facts, not self-generated: the 2024
/// North-America total eclipse new moon (2024-04-08 18:21 UTC), that month's
/// full moon (2024-04-23 23:49 UTC), and Meeus's worked example 51.a for the
/// libration. Since the phase became a difference of two ecliptic longitudes
/// rather than a truncated series of its own, these hold to about a minute of
/// arc — the old tolerances were 0.12 rad (7°) and are now 0.01 rad.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/moon_phase.dart';
import 'package:flutter_test/flutter_test.dart';

/// A total solar eclipse is a new moon observed to the minute.
final _newMoon = DateTime.utc(2024, 4, 8, 18, 21);
final _fullMoon = DateTime.utc(2024, 4, 23, 23, 49);

void main() {
  group('MoonPhase', () {
    test('new moon at the 2024 eclipse', () {
      final angle = MoonPhase.at(_newMoon).angle;
      expect(math.min(angle, 2 * math.pi - angle), lessThan(0.01));
    });

    test('full moon 15.2 days later', () {
      expect((MoonPhase.at(_fullMoon).angle - math.pi).abs(), lessThan(0.01));
    });

    test('brightness is 0 at new and 1 at full', () {
      expect(MoonPhase.at(_newMoon).brightness, lessThan(0.001));
      expect(MoonPhase.at(_fullMoon).brightness, greaterThan(0.999));
    });

    test('first quarter lights the right half (waxing) at ~50%', () {
      final q1 = MoonPhase.at(DateTime.utc(2024, 4, 15, 19, 13));
      expect(q1.waxing, isTrue);
      expect(q1.brightness, closeTo(0.5, 0.01));
      expect(q1.name, MoonPhaseName.firstQuarter);
    });

    test('age in days runs 0..synodic month and resets at new moon', () {
      expect(
        MoonPhase.at(_fullMoon).ageInDays,
        closeTo(synodicMonthDays / 2, 0.1),
      );
      // At new moon the age is *both* ends of the range — the instant is the
      // wrap — so either answer is right and only the distance to it matters.
      final atNew = MoonPhase.at(_newMoon).ageInDays;
      expect(math.min(atNew, synodicMonthDays - atNew), lessThan(0.1));
    });

    test('distance is the ephemeris distance, in the physical range', () {
      final phase = MoonPhase.at(_fullMoon);
      expect(phase.distanceKm, inInclusiveRange(356400, 406800));
      expect(phase.apparentDiameterDegrees, inInclusiveRange(0.49, 0.56));
    });

    group('phase search', () {
      test('finds the April 2024 full moon from the eclipse new moon', () {
        final next = MoonPhase.nextFullMoon(_newMoon);
        expect(next.difference(_fullMoon).inMinutes.abs(), lessThan(30));
      });

      test('finds the next new moon from mid-lunation', () {
        // 2024-05-08 03:22 UTC, seen from the full moon before it.
        final next = MoonPhase.nextNewMoon(_fullMoon);
        expect(
          next.difference(DateTime.utc(2024, 5, 8, 3, 22)).inMinutes.abs(),
          lessThan(30),
        );
      });

      test('lands on the target angle, not merely near it', () {
        // The search is an iteration, not a bracket: what has to hold is that
        // it converged, and it must hold for every lunation, not a lucky one.
        var at = DateTime.utc(2024);
        for (var lunation = 0; lunation < 40; lunation++) {
          final full = MoonPhase.nextFullMoon(at);
          expect(
            (MoonPhase.angleAt(full) - math.pi).abs(),
            lessThan(1e-4),
            reason: 'lunation $lunation',
          );
          at = full;
        }
      });

      test('is always strictly after, including from a full moon', () {
        // Coasting from a zero remainder lands back where it started, so the
        // search has to notice and step on — otherwise a caller walking the
        // phases stops dead.
        for (final from in [
          _newMoon,
          _fullMoon,
          MoonPhase.nextFullMoon(_newMoon),
        ]) {
          expect(MoonPhase.nextFullMoon(from).isAfter(from), isTrue);
          expect(MoonPhase.nextNewMoon(from).isAfter(from), isTrue);
        }
      });

      test('successive full moons are one synodic month apart', () {
        // Walking the calendar is what the page does, and it is where a search
        // that quietly returns its own input would show up as a stall.
        var previous = MoonPhase.nextFullMoon(DateTime.utc(2024));
        for (var lunation = 0; lunation < 24; lunation++) {
          final next = MoonPhase.nextFullMoon(
            previous.add(const Duration(days: 1)),
          );
          // Real lunations vary about ±0.5 d around the mean.
          expect(
            next.difference(previous).inMinutes / (60 * 24),
            closeTo(synodicMonthDays, 0.7),
            reason: 'lunation $lunation',
          );
          previous = next;
        }
      });
    });

    group('libration', () {
      test('reproduces Meeus worked example 51.a', () {
        // 1992 April 12, 0h TD: l' = -1.206°, b' = +4.194°.
        final libration = MoonPhase.librationAt(
          DateTime.utc(1992, 4, 12).subtract(const Duration(seconds: 59)),
        );
        expect(libration.longitude * 180 / math.pi, closeTo(-1.206, 0.01));
        expect(libration.latitude * 180 / math.pi, closeTo(4.194, 0.01));
      });

      test('stays inside the physical rocking range', () {
        // Optical libration is bounded by the orbit: ±7.9° in longitude,
        // ±6.9° in latitude. Outside that the globe would visibly swing.
        var maxLongitude = 0.0;
        var maxLatitude = 0.0;
        for (var hours = 0; hours < 24 * 400; hours += 6) {
          final l = MoonPhase.librationAt(
            DateTime.utc(2026).add(Duration(hours: hours)),
          );
          maxLongitude = math.max(maxLongitude, l.longitude.abs());
          maxLatitude = math.max(maxLatitude, l.latitude.abs());
        }
        expect(maxLongitude * 180 / math.pi, inInclusiveRange(5, 8));
        expect(maxLatitude * 180 / math.pi, inInclusiveRange(5, 7));
      });

      test('does not jump — the wrap is signed, not modular', () {
        // l' is A - F, both of which wrap; taken modulo 2π the result would
        // flip between -7° and +353° and snap the rendered globe around.
        var previous = MoonPhase.librationAt(DateTime.utc(2026)).longitude;
        for (var hours = 1; hours < 24 * 90; hours += 3) {
          final current = MoonPhase.librationAt(
            DateTime.utc(2026).add(Duration(hours: hours)),
          ).longitude;
          expect((current - previous).abs(), lessThan(0.05));
          previous = current;
        }
      });
    });
  });
}
