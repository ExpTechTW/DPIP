/// The colour-vision transform is applied at ~270 colour definitions across the
/// app, so it has to be right before any of them route through it.
library;

import 'dart:ui' show Color;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:flutter_test/flutter_test.dart';

/// How far apart two colours are, roughly, in sRGB. Enough to say "these two
/// stopped being the same colour" without pulling in a CIE library.
double _separation(Color a, Color b) {
  final dr = a.r - b.r, dg = a.g - b.g, db = a.b - b.b;
  return dr * dr + dg * dg + db * db;
}

void main() {
  group('identity', () {
    test('none is the identity for every input shape', () {
      const red = Color(0xFFFF0000);
      expect(ColorVisionFilter.transform(red, ColorVision.none), red);
      expect(
        ColorVisionFilter.transformHex('#FF0000', ColorVision.none),
        '#FF0000',
      );
    });

    test('greys survive every mode', () {
      // A daltonisation that tints neutral surfaces would recolour the entire
      // app chrome, which is not what a colour-vision setting is for.
      for (final vision in ColorVision.values) {
        for (final grey in [0xFF000000, 0xFF808080, 0xFFFFFFFF]) {
          final out = ColorVisionFilter.transform(Color(grey), vision);
          expect(
            (out.r - out.g).abs() + (out.g - out.b).abs(),
            lessThan(0.02),
            reason: '${vision.name} tinted ${grey.toRadixString(16)}',
          );
        }
      }
    });

    test('alpha is untouched', () {
      // Compared against the input's own alpha, not against 0.5: 0x80 is
      // 128/255, which is not exactly half and never was.
      const half = Color(0x80FF0000);
      for (final vision in ColorVision.values) {
        expect(ColorVisionFilter.transform(half, vision).a, half.a);
      }
      expect(
        ColorVisionFilter.transformHex('#FF000080', ColorVision.deutan),
        endsWith('80'),
      );
    });
  });

  group('it actually separates confusable pairs', () {
    // The point of the feature. Red and green are the pair a deutan/protan eye
    // collapses; the transform has to push them further apart than they start.
    test('red and green move apart for protan and deutan', () {
      const red = Color(0xFFD32F2F);
      const green = Color(0xFF388E3C);
      final before = _separation(red, green);
      for (final vision in [ColorVision.protan, ColorVision.deutan]) {
        final after = _separation(
          ColorVisionFilter.transform(red, vision),
          ColorVisionFilter.transform(green, vision),
        );
        expect(
          after,
          greaterThan(before),
          reason: '${vision.name} did not separate red from green',
        );
      }
    });

    test('blue and green move apart for tritan', () {
      const blue = Color(0xFF1976D2);
      const green = Color(0xFF388E3C);
      final before = _separation(blue, green);
      final after = _separation(
        ColorVisionFilter.transform(blue, ColorVision.tritan),
        ColorVisionFilter.transform(green, ColorVision.tritan),
      );
      expect(after, greaterThan(before));
    });
  });

  group('hex parsing keeps the shape it was given', () {
    test('#rrggbb stays six digits', () {
      final out = ColorVisionFilter.transformHex('#3F4045', ColorVision.deutan);
      expect(out, matches(RegExp(r'^#[0-9a-f]{6}$')));
    });

    test('rgba() stays functional', () {
      final out = ColorVisionFilter.transformHex(
        'rgba(255, 59, 48, 0.16)',
        ColorVision.protan,
      );
      expect(out, startsWith('rgba('));
      expect(out, endsWith('0.160)'));
    });

    test('#rgb shorthand expands rather than corrupting', () {
      final out = ColorVisionFilter.transformHex('#f00', ColorVision.deutan);
      expect(out, matches(RegExp(r'^#[0-9a-f]{6}$')));
    });

    /// A MapLibre paint value can be an expression, not a colour. Mangling one
    /// takes the whole layer off the map, so anything unrecognised must pass
    /// through untouched.
    test('a non-colour paint value passes through untouched', () {
      for (final value in [
        'transparent',
        r'{fill-color}',
        '["interpolate", ["linear"], ["zoom"], 0, "#fff"]',
        '#12345',
        '#zzzzzz',
      ]) {
        expect(
          ColorVisionFilter.transformHex(value, ColorVision.deutan),
          value,
          reason: 'mangled $value',
        );
      }
    });
  });

  test('the raster exemption is the identity, and says so', () {
    // Server-rendered radar/satellite pixels cannot be transformed, so their
    // legends must not be either — this marker is how a reader can tell an
    // untransformed colour is deliberate rather than missed.
    const dbz = Color(0xFF00FF00);
    expect(ColorVisionFilter.rasterExempt(dbz), dbz);
    expect(ColorVisionFilter.rasterExemptHex('#00FF00'), '#00FF00');
  });

  test('tokens round-trip, and anything unknown is none', () {
    for (final vision in ColorVision.values) {
      expect(ColorVision.fromToken(vision.token), vision);
    }
    expect(ColorVision.fromToken(null), ColorVision.none);
    expect(ColorVision.fromToken('nonsense'), ColorVision.none);
  });
}
