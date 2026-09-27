/// The bundled sky: the binary star/constellation assets actually decode into
/// sane J2000 coordinates, the decode is cached rather than repeated on every
/// open, and precessing a catalogue position to the equinox of date matches
/// the textbook (Meeus) annual precession constants rather than some
/// transcription slip in the RA/Dec formula.
///
/// The decode is exercised against the real shipped assets
/// (`assets/astro/stars.bin.gz`, `assets/astro/constellations.bin.gz`) —
/// `flutter_test`'s asset bundle serves the project's actual files, so this
/// is the real gzip-decode-plus-binary-unpack pipeline, not a synthetic
/// stand-in. `StarCatalog._cached` is a static, process-lifetime memo with no
/// reset hook, so within this file `load()` is only ever asserted to decode
/// *something* sane and then to reuse it — never called in a way that
/// depends on a fresh decode happening twice.
///
/// Coverage gap, stated rather than worked around: the `catch (_) { _cached =
/// null; rethrow; }` eviction branch in [StarCatalog.load] only runs when
/// [StarCatalog._load] throws, which on this test host would mean making the
/// real bundled asset files unreadable — corrupting or moving shipped assets
/// on disk from a test is out of scope here, so that branch is not exercised.
library;

import 'dart:math' as math;

import 'package:dpip/core/astro/astro_time.dart';
import 'package:dpip/core/astro/star_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('load()', () {
    test('decodes the bundled catalogue into stars and figures with sane '
        'J2000 coordinates', () async {
      final catalog = await StarCatalog.load();

      // "5,044 stars to magnitude 6" per the library doc — a floor rather
      // than the exact figure, so a future re-generation of the asset with
      // a few more/fewer stars does not make this test the obstacle.
      expect(catalog.stars.length, greaterThan(1000));
      expect(catalog.figures, isNotEmpty);

      for (final star in catalog.stars) {
        expect(star.rightAscension, inInclusiveRange(0, 360));
        expect(star.declination, inInclusiveRange(-90, 90));
        // 8 bits over -2..8 mag, per the packing note in the library doc.
        expect(star.magnitude, inInclusiveRange(-2.0, 8.0));
      }

      for (final figure in catalog.figures) {
        expect(figure.points, isNotEmpty);
        for (final (ra, dec) in figure.points) {
          expect(ra, inInclusiveRange(0, 360));
          expect(dec, inInclusiveRange(-90, 90));
        }
      }
    });

    test('a second call reuses the cached decode', () async {
      final first = await StarCatalog.load();
      final second = await StarCatalog.load();

      expect(identical(first, second), isTrue);
    });
  });

  group('precess()', () {
    test('at dec = 0 the drift reduces to the textbook mean annual precession '
        'in RA and Dec', () {
      // At declination 0, `sin(a) * tan(d)` is 0 regardless of `a`, and
      // `cos(a)` at ra = 0 is 1 — so the general two-term formula collapses
      // to Meeus's mean annual precession constants alone: M = 3.07496 s/yr
      // in RA, N = 20.0431 "/yr in Dec. Computed here independently of
      // `precess`'s own expression, from the same public time/angle
      // primitives it is built on.
      final utc = DateTime.utc(2050, 6, 15);
      final years = julianCenturies(utc) * 100;

      final result = StarCatalog.precess(0, 0, utc);

      final expectedRa = turn(years * 3.07496 * 15 / 3600 * degrees);
      final expectedDec = years * 20.0431 / 3600 * degrees;
      expect(result.rightAscension, closeTo(expectedRa, 1e-9));
      expect(result.declination, closeTo(expectedDec, 1e-9));
    });

    test('right ascension always comes back wrapped into [0, 2*pi)', () {
      // Tens of thousands of years of drift push the raw sum well past a
      // full turn; `turn()` must still land it in range rather than the
      // caller ever seeing a negative or multi-turn angle.
      final result = StarCatalog.precess(10, 20, DateTime.utc(100000));

      expect(result.rightAscension, greaterThanOrEqualTo(0));
      expect(result.rightAscension, lessThan(2 * math.pi));
    });

    test('at ra = dec = 0 and years = 0 the position is unchanged', () {
      // 2000-01-01T12:00 UTC is JD 2451545.0 on the UT scale by construction
      // of `julianDay` — the J2000.0 TT epoch to within deltaT's ~63 seconds,
      // small enough that `julianCenturies` (and so `years`) is effectively
      // zero and the whole precession correction vanishes.
      final utc = DateTime.utc(2000, 1, 1, 12);
      expect(julianCenturies(utc) * 100, closeTo(0, 1e-4));

      final result = StarCatalog.precess(0, 0, utc);

      expect(result.rightAscension, closeTo(0, 1e-6));
      expect(result.declination, closeTo(0, 1e-6));
    });
  });
}
