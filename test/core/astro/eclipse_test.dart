/// Golden pins for eclipses, against NASA's five-millennium canon.
///
/// Two very different things are being checked. The **lunar** side is a global
/// event, so the published greatest-eclipse instant and umbral magnitude are
/// directly comparable. The **solar** side is local, and the test that matters
/// most is not a magnitude at all — it is that an eclipse crossing Iceland is
/// *not* reported for Taiwan. The geometry alone will happily produce a small
/// formal separation for an observer on the night side of the Earth; only
/// requiring the Sun to be above the horizon turns that into an answer.
library;

import 'package:dpip/core/astro/eclipse.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipei = (latitude: 25.0330, longitude: 121.5654);
const _reykjavik = (latitude: 64.1466, longitude: -21.9426);
const _luxor = (latitude: 25.6872, longitude: 32.6396);

void main() {
  group('lunar eclipses', () {
    test('finds the right events, at the right times, 2025-2028', () {
      // NASA's greatest-eclipse instants and umbral magnitudes. Magnitudes
      // agree to about 0.015, which is the truncated ephemeris plus the
      // convention for enlarging the shadow; the timings agree to a minute.
      const published = <(String, EclipseKind, double)>[
        ('2025-03-14T06:58', EclipseKind.total, 1.178),
        ('2025-09-07T18:11', EclipseKind.total, 1.362),
        ('2026-03-03T11:33', EclipseKind.total, 1.151),
        ('2026-08-28T04:12', EclipseKind.partial, 0.928),
        ('2028-01-12T04:13', EclipseKind.partial, 0.066),
      ];
      for (final (stamp, kind, magnitude) in published) {
        final expected = DateTime.parse('${stamp}Z');
        final eclipse = Eclipses.lunarAt(expected);
        expect(eclipse.kind, kind, reason: stamp);
        expect(
          eclipse.peak.difference(expected).inMinutes.abs(),
          lessThan(2),
          reason: '$stamp timing',
        );
        expect(
          eclipse.magnitude,
          closeTo(magnitude, 0.02),
          reason: '$stamp magnitude',
        );
      }
    });

    test('a penumbral eclipse is reported as penumbral, not missed', () {
      // 2027-02-20 is penumbral only: the Moon never touches the umbra. An
      // implementation that only tests the umbra reports nothing at all.
      final eclipse = Eclipses.lunarAt(DateTime.utc(2027, 2, 20, 23, 13));
      expect(eclipse.kind, EclipseKind.penumbral);
      expect(eclipse.penumbralMagnitude, greaterThan(0.8));
    });

    test('most full moons are not eclipses', () {
      // The Moon's orbit is tilted 5°, so it usually misses the shadow
      // entirely. A finder that returns something every month is broken.
      var eclipses = 0;
      var at = DateTime.utc(2026);
      for (var i = 0; i < 12; i++) {
        final found = Eclipses.nextLunar(at, withinDays: 40);
        if (found != null) {
          eclipses++;
          at = found.peak.add(const Duration(days: 20));
        } else {
          at = at.add(const Duration(days: 30));
        }
      }
      expect(eclipses, inInclusiveRange(1, 4));
    });

    test('contacts bracket the peak', () {
      final eclipse = Eclipses.lunarAt(DateTime.utc(2026, 3, 3, 11, 33));
      expect(eclipse.begins!.isBefore(eclipse.peak), isTrue);
      expect(eclipse.ends!.isAfter(eclipse.peak), isTrue);
      // A total lunar eclipse's umbral phase runs a few hours.
      expect(
        eclipse.ends!.difference(eclipse.begins!).inMinutes,
        inInclusiveRange(120, 260),
      );
    });
  });

  group('solar eclipses', () {
    test('2026-08-12 is total from Iceland', () {
      final eclipse = Eclipses.solarAt(
        DateTime.utc(2026, 8, 12, 17),
        latitude: _reykjavik.latitude,
        longitude: _reykjavik.longitude,
      );
      expect(eclipse.kind, EclipseKind.total);
      expect(eclipse.magnitude, greaterThan(0.99));
    });

    test('2027-08-02 is total from Luxor', () {
      final eclipse = Eclipses.solarAt(
        DateTime.utc(2027, 8, 2, 10),
        latitude: _luxor.latitude,
        longitude: _luxor.longitude,
      );
      expect(eclipse.kind, EclipseKind.total);
      expect(eclipse.magnitude, greaterThan(1.02));
    });

    test('the same eclipse is not visible from Taiwan', () {
      // The single most important check here. Taiwan is on the night side at
      // the time; the parallax-corrected geometry still yields a small formal
      // separation, and without the horizon test this reports a partial
      // eclipse that nobody on the island could see.
      final eclipse = Eclipses.solarAt(
        DateTime.utc(2026, 8, 12, 17),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
      );
      expect(eclipse.isVisible, isFalse);
    });

    test('Taiwan\'s next visible solar eclipse is the 2030 one', () {
      // 2030-06-01 is annular across Asia; Taiwan catches a solid partial.
      // Nothing before it is visible from the island, which is a strong check
      // on the horizon filter over a five-year search.
      final eclipse = Eclipses.nextSolar(
        DateTime.utc(2026),
        latitude: _taipei.latitude,
        longitude: _taipei.longitude,
        withinDays: 2000,
      );
      expect(eclipse, isNotNull);
      expect(eclipse!.peak.year, 2030);
      expect(eclipse.peak.month, 6);
      expect(eclipse.kind, EclipseKind.partial);
      expect(eclipse.magnitude, inInclusiveRange(0.2, 0.6));
    });

    test('contacts bracket the peak and last a couple of hours', () {
      final eclipse = Eclipses.solarAt(
        DateTime.utc(2027, 8, 2, 10),
        latitude: _luxor.latitude,
        longitude: _luxor.longitude,
      );
      expect(eclipse.begins!.isBefore(eclipse.peak), isTrue);
      expect(eclipse.ends!.isAfter(eclipse.peak), isTrue);
      expect(
        eclipse.ends!.difference(eclipse.begins!).inMinutes,
        inInclusiveRange(90, 200),
      );
    });
  });
}
