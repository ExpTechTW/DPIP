/// Single-precision arithmetic as onnxruntime does it, for the intensity model.
///
/// The model is evaluated to the bit — the same levels as TREM-Lite and the
/// server for the same quake — so every value is rounded to f32 exactly where
/// onnxruntime rounds it:
///
///  - One add or multiply of two f32 values, done in f64 and rounded to f32, is
///    the f32 result: f64 carries more than twice f32's precision, so the double
///    rounding cannot change it.
///  - A fused multiply-add cannot be done that way, and MLAS's Exp is built of
///    them. [fma32] rounds the f64 sum "to odd" first (TwoSum finds its error;
///    an even result is moved one ulp toward the true sum), after which one
///    rounding to f32 is the correctly rounded fused result.
///  - Exp is MLAS's kernel ([mlasExp]), not the platform's: a correctly rounded
///    exp differs from it by an ulp on about one input in fourteen, and the PGV
///    formula multiplies that difference up.
library;

import 'dart:math' as math;
import 'dart:typed_data';

final Float32List _f32 = Float32List(1);
final Uint32List _u32 = Uint32List.view(_f32.buffer);
final Float64List _f64 = Float64List(1);
final Int64List _i64 = Int64List.view(_f64.buffer);

/// [x] rounded to the nearest f32.
double fround(double x) {
  _f32[0] = x;
  return _f32[0];
}

/// The f32 whose bit pattern is [bits].
double f32FromBits(int bits) {
  _u32[0] = bits;
  return _f32[0];
}

/// The bit pattern of [x] as an f32.
int f32Bits(double x) {
  _f32[0] = x;
  return _u32[0];
}

/// The next f32 toward −∞ from a finite f32 [x].
double f32NextDown(double x) {
  if (x == 0) return -f32FromBits(1);
  final bits = f32Bits(x);
  return f32FromBits(x > 0 ? bits - 1 : bits + 1);
}

/// `a·b + c` for f32 operands, rounded once to f32.
double fma32(double a, double b, double c) {
  final p = a * b; // exact: 24 + 24 significant bits fit in f64's 53
  final s = p + c;
  final bb = s - p;
  final err = (p - (s - bb)) + (c - bb);
  if (err == 0) return fround(s);
  _f64[0] = s;
  final bits = _i64[0];
  if (bits & 1 == 0) {
    // One ulp toward the true sum: away from zero when the error points there.
    _i64[0] = bits + ((err > 0) == (s > 0) ? 1 : -1);
  }
  return fround(_f64[0]);
}

final double _expLower = f32FromBits(0xc2cff1b5);
final double _expUpper = f32FromBits(0x42b18d72);
const double _roundingBias = 12582912; // 1.5 · 2^23
final double _log2Recip = f32FromBits(0x3fb8aa3b);
final double _log2High = f32FromBits(0xbf317200);
final double _log2Low = f32FromBits(0xb5bfbe8e);
final List<double> _poly = [
  for (final bits in const [
    0x3ab4a000,
    0x3c092f6e,
    0x3d2aadad,
    0x3e2aaa28,
    0x3efffffb,
  ])
    f32FromBits(bits),
  1.0,
];
const int _minExponent = -1056964608; // 0xc1000000 as a signed 32-bit int
const int _maxExponent = 0x3f800000;

/// onnxruntime's f32 Exp — MLAS `MlasComputeExpF32Kernel`: its constants, as
/// their exact f32 bits, and its operation order, every multiply-add fused.
double mlasExp(double input) {
  var x = math.min(math.max(input, _expLower), _expUpper);
  final biased = fma32(x, _log2Recip, _roundingBias);
  final m = fround(biased - _roundingBias);
  x = fma32(m, _log2High, x);
  x = fma32(m, _log2Low, x);
  final shifted = (f32Bits(biased) << 23).toSigned(32);
  final normal = shifted.clamp(_minExponent, _maxExponent);
  final overflow = (shifted - normal + _maxExponent).toSigned(32);
  var p = _poly[0];
  for (var k = 1; k < _poly.length; k++) {
    p = fma32(p, x, _poly[k]);
  }
  final of = f32FromBits(overflow & 0xffffffff);
  p = fma32(p, fround(x * of), of);
  return fround(p * f32FromBits((normal + _maxExponent) & 0xffffffff));
}
