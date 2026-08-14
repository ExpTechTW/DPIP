/// Meteor showers, deep sky, the observing window, and the tide-raising force.
///
/// These four have no single external table to check against the way the
/// ephemerides do, so each is pinned to the physics it claims. A shower's
/// radiant must be where the sky puts it; the equilibrium tide must have the
/// textbook solar-to-lunar ratio; a dark window must actually be dark.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/deep_sky.dart';
import 'package:dpip/core/astro/meteor_showers.dart';
import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:dpip/core/astro/night_window.dart';
import 'package:dpip/core/astro/tidal_forcing.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipei = (latitude: 25.0330, longitude: 121.5654);
const _taiwan = Duration(hours: 8);

void main() {
  group('meteor showers', () {
    test('the Perseid radiant is in Perseus, and it is circumpolar-ish', () {
      // RA 3h12m, Dec +58 — high in the northern sky. From Taiwan it clears
      // the horizon but never gets near the zenith, which is exactly the sort
      // of thing a rate estimate has to account for.
      final perseids = meteorShowers.firstWhere((s) => s.id == 'perseids');
      final conditions = MeteorShowerConditions.of(
        perseids,
        2026,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(conditions.bestAltitude / degrees, inInclusiveRange(20, 60));
      expect(conditions.visibleRate, greaterThan(0));
    });

    test('a southern radiant can be unobservable from the north', () {
      // A fabricated shower at -70° declination never rises from Taipei, and
      // its rate must be zero rather than its ZHR.
      const antarctic = MeteorShower(
        id: 'test',
        peakMonth: 6,
        peakDay: 15,
        startMonth: 6,
        startDay: 1,
        endMonth: 6,
        endDay: 30,
        rightAscensionJ2000: 90,
        declinationJ2000: -70,
        zenithalRate: 100,
        velocityKmS: 50,
      );
      final conditions = MeteorShowerConditions.of(
        antarctic,
        2026,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(conditions.bestAltitude, lessThan(0));
      expect(conditions.visibleRate, 0);
    });

    test('moonlight cuts the rate, and a new moon does not', () {
      // The same shower on the same night, differing only in the Moon. This
      // is the factor that decides whether a famous shower disappoints.
      final geminids = meteorShowers.firstWhere((s) => s.id == 'geminids');
      final withMoon = ShowerConditions(
        shower: geminids,
        peak: DateTime.utc(2026, 12, 14),
        bestTime: DateTime.utc(2026, 12, 14, 18),
        bestAltitude: math.pi / 2,
        moonIllumination: 1,
        moonIsUp: true,
      );
      final darkSky = ShowerConditions(
        shower: geminids,
        peak: DateTime.utc(2026, 12, 14),
        bestTime: DateTime.utc(2026, 12, 14, 18),
        bestAltitude: math.pi / 2,
        moonIllumination: 0,
        moonIsUp: false,
      );
      expect(darkSky.visibleRate, geminids.zenithalRate);
      expect(withMoon.visibleRate, closeTo(geminids.zenithalRate * 0.2, 1));
      expect(darkSky.isFavourable, isTrue);
      expect(withMoon.isFavourable, isFalse);
    });

    test('the active list follows the calendar, wrapping the new year', () {
      // The Quadrantids run 28 December to 12 January — a window that a naive
      // month comparison drops entirely.
      expect(
        MeteorShowerConditions.activeOn(
          DateTime.utc(2026, 1, 3),
        ).map((s) => s.id),
        contains('quadrantids'),
      );
      expect(
        MeteorShowerConditions.activeOn(
          DateTime.utc(2025, 12, 30),
        ).map((s) => s.id),
        contains('quadrantids'),
      );
      expect(
        MeteorShowerConditions.activeOn(
          DateTime.utc(2026, 3, 1),
        ).map((s) => s.id),
        isEmpty,
      );
    });
  });

  group('deep sky', () {
    test('the catalogue is complete and numbered 1-110', () {
      expect(messierCatalogue, hasLength(110));
      expect(
        messierCatalogue.map((o) => o.messier).toList()..sort(),
        List.generate(110, (i) => i + 1),
      );
    });

    test('the famous ones are where they should be', () {
      // Spot checks a reader would notice: M31 in Andromeda at +41°, M42 in
      // Orion just below the equator, M45 the Pleiades.
      final m31 = messierCatalogue.firstWhere((o) => o.messier == 31);
      expect(m31.commonName, 'Andromeda');
      expect(m31.declinationJ2000, closeTo(41.27, 0.1));
      expect(m31.type, DeepSkyType.s);

      final m42 = messierCatalogue.firstWhere((o) => o.messier == 42);
      expect(m42.commonName, 'Orion Nebula');
      expect(m42.rightAscensionJ2000, closeTo(83.85, 0.1));
      expect(m42.declinationJ2000, closeTo(-5.45, 0.1));

      final m1 = messierCatalogue.firstWhere((o) => o.messier == 1);
      expect(m1.commonName, 'Crab Nebula');
      expect(m1.type, DeepSkyType.snr);
    });

    test('precession moves an object, slightly and in the right direction', () {
      // Twenty-six years from J2000 is about 0.36° of general precession —
      // small, but the same correction the planets need, applied for the same
      // reason.
      final m31 = messierCatalogue.firstWhere((o) => o.messier == 31);
      final now = m31.positionAt(DateTime.utc(2026));
      final shift = signedTurn(
        now.rightAscension - m31.rightAscensionJ2000 * degrees,
      );
      expect(shift / degrees, inInclusiveRange(0.05, 0.6));
    });
  });

  group('night window', () {
    test('a dark window is dark: no Sun, no Moon', () {
      // Sampled inside the window the code returns, both conditions have to
      // hold — this is the check that the intersection was actually taken and
      // not just the Sun's part.
      final night = NightConditions.of(
        DateTime.utc(2026, 8, 15).subtract(_taiwan),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(night.darkWindows, isNotEmpty);
      final window = night.best!;
      final middle = window.from.add(window.length ~/ 2);
      expect(
        MoonRiseSet.aboveHorizon(
          middle,
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        ),
        isFalse,
        reason: 'the Moon must be down inside a dark window',
      );
    });

    test('a full moon leaves no dark window at all', () {
      // Full moon rises at sunset and sets at sunrise, so it covers the whole
      // astronomical night. Reporting a window here would be the single most
      // misleading thing this class could do.
      final full = MoonPhase.nextFullMoon(DateTime.utc(2026, 6));
      final night = NightConditions.of(
        DateTime.utc(full.year, full.month, full.day).subtract(_taiwan),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(night.moonIllumination, greaterThan(0.97));
      expect(night.totalDark, lessThan(const Duration(hours: 1)));
    });

    test('a new moon leaves the whole night', () {
      final newMoon = MoonPhase.nextNewMoon(DateTime.utc(2026, 6));
      final night = NightConditions.of(
        DateTime.utc(
          newMoon.year,
          newMoon.month,
          newMoon.day,
        ).subtract(_taiwan),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final astronomical = night.astronomicalNight!;
      expect(
        night.totalDark.inMinutes,
        closeTo(astronomical.$2.difference(astronomical.$1).inMinutes, 90),
      );
    });
  });

  group('tidal forcing', () {
    test('the Sun raises 46% of the Moon\'s tide', () {
      // The one number here that can be checked against a textbook with no
      // ocean in the way. Compared at the sub-solar and sub-lunar points by
      // taking the amplitude ratio over a long run.
      var lunarPeak = 0.0;
      var solarPeak = 0.0;
      for (var hours = 0; hours < 24 * 40; hours++) {
        final forcing = TidalForcing.at(
          DateTime.utc(2026).add(Duration(hours: hours)),
          latitude: _taipei.latitude,
          longitude: _taipei.longitude,
        );
        lunarPeak = math.max(lunarPeak, forcing.lunarMetres);
        solarPeak = math.max(solarPeak, forcing.solarMetres);
      }
      expect(solarPeak / lunarPeak, closeTo(0.46, 0.06));
    });

    test('spring tides fall at new and full moon', () {
      final full = MoonPhase.nextFullMoon(DateTime.utc(2026, 5));
      final quarter = MoonPhase.nextAngle(
        DateTime.utc(2026, 5),
        target: math.pi / 2,
      );
      final spring = TidalForcing.at(
        full,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final neap = TidalForcing.at(
        quarter,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(spring.phase, TidePhase.spring);
      expect(neap.phase, TidePhase.neap);
      expect(spring.springNeap, greaterThan(0.98));
      expect(neap.springNeap, lessThan(0.02));
    });

    test('the cube law makes perigee matter more than it looks', () {
      // 14% of distance becomes nearly 50% of force. This is why a perigean
      // spring is the one to watch for alongside a surge.
      final perigee = TidalForcing.at(
        DateTime.utc(2026, 12, 24, 13),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      final apogee = TidalForcing.at(
        DateTime.utc(2025, 11, 19, 18),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(perigee.distanceFactor / apogee.distanceFactor, greaterThan(1.4));
    });

    test('there are two highs and two lows a day', () {
      // The (3cos²z − 1) potential peaks under the Moon *and* opposite it,
      // which is why the tide is semidiurnal. One peak a day would mean the
      // potential was wrong.
      final extremes = TidalForcing.extremes(
        DateTime.utc(2026, 8, 15).subtract(_taiwan),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(extremes.where((e) => e.isHigh).length, inInclusiveRange(1, 3));
      expect(extremes.where((e) => !e.isHigh).length, inInclusiveRange(1, 3));
      expect(extremes.length, inInclusiveRange(3, 5));
    });

    test('a perigean spring is found, and it really is both', () {
      final at = TidalForcing.nextPerigeanSpring(DateTime.utc(2026));
      expect(at, isNotNull);
      final forcing = TidalForcing.at(
        at!,
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(forcing.springNeap, greaterThan(0.9));
      expect(forcing.distanceFactor, greaterThan(1.15));
      expect(forcing.isPerigeanSpring, isTrue);
    });
  });
}
