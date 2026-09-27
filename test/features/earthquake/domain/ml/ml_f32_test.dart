/// The f32 arithmetic the intensity model rests on, held to onnxruntime's bits
/// without needing the 14.7 MB model file.
///
/// Both functions are here because each is wrong in a way that only moves the
/// last bit — which is invisible until a township sits on a level boundary.
/// A multiply-add rounded twice (f64, then f32) lands a result that is just
/// past an f32 halfway point back on the even side; and a platform `exp`, even
/// a correctly rounded one, is not MLAS's kernel. The Exp reference bits come
/// from TREM-Lite's TypeScript port, which is checked against onnxruntime.
library;

import 'dart:math' as math;

import 'package:dpip/features/earthquake/domain/ml/ml_f32.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fma32 rounds once, where rounding in f64 first would not', () {
    // 4097 × 16773121 = 2^36 + 1, so a·b = 2^-24 + 2^-60 exactly and
    // a·b + 1 sits just above the halfway point between 1 and 1 + 2^-23.
    final a = 4097 / math.pow(2, 12);
    final b = 16773121 / math.pow(2, 48);

    expect(f32Bits(fround(a * b + 1)), 0x3f800000, reason: 'double rounding');
    expect(f32Bits(fma32(a, b, 1)), 0x3f800001);
  });

  test('fma32 is exact when the sum is', () {
    expect(fma32(1.5, 2, 0.25), 3.25);
    expect(fma32(-2, 3, 6), 0);
  });

  test('mlasExp matches onnxruntime\'s kernel bit for bit', () {
    const cases = [
      (0xc2c80000, 0x1b),
      (0xc2af0000, 0x6cb2bc),
      (0xc1200000, 0x383e6bce),
      (0xbf800000, 0x3ebc5ab2),
      (0xbf000000, 0x3f1b4598),
      (0xb58637bd, 0x3f7fffef),
      (0x0, 0x3f800000),
      (0x33d6bf95, 0x3f800001),
      (0x3e99999a, 0x3facc82c),
      (0x3f800000, 0x402df854),
      (0x40135d8d, 0x411ffffe),
      (0x40652918, 0x420f95c6),
      (0x409ef869, 0x430fb6b9),
      (0x40b00000, 0x4374b122),
      (0x41200000, 0x46ac14ef),
      (0x42480000, 0x638c881f),
      (0x42b00000, 0x7ef882b7),
      (0x42b20000, 0x7f800000),
      (0x42c80000, 0x7f800000),
    ];
    for (final (input, output) in cases) {
      expect(
        f32Bits(mlasExp(f32FromBits(input))),
        output,
        reason: 'exp(0x${input.toRadixString(16)})',
      );
    }
  });

  test('nextDown steps one f32 toward minus infinity', () {
    expect(f32Bits(f32NextDown(1)), 0x3f7fffff);
    expect(f32Bits(f32NextDown(-1)), 0xbf800001);
    expect(f32NextDown(0), -f32FromBits(1));
  });
}
