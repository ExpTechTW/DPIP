/// `trimTrailingZero` — the number-to-text helper behind every fact row and
/// axis label.
///
/// Pinned directly rather than through a page, because both failure modes look
/// like a data problem rather than a formatting one: a latitude that renders
/// `25.0` where every other row says `24.8`, or a value rounded to a decimal
/// the caller did not ask for. The interesting case is the boundary — a value
/// that lands exactly on `.0` loses the decimal, and anything else keeps the
/// digits `toStringAsFixed` produced.
library;

import 'package:dpip/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a whole number loses its decimal', () {
    expect(trimTrailingZero(25.0), '25');
    expect(trimTrailingZero(0.0), '0');
    expect(trimTrailingZero(-3.0), '-3');
  });

  test('a fraction keeps the digits it was rounded to', () {
    expect(trimTrailingZero(25.4), '25.4');
    expect(trimTrailingZero(25.44, digits: 2), '25.44');
  });

  test('rounding to a whole number drops the decimal too', () {
    // The value is not 25 — it is 25.04 shown at one decimal — and it still has
    // to read as `25` rather than `25.0`, or it is the only row on the card
    // with a decimal on it.
    expect(trimTrailingZero(25.04), '25');
  });

  test('digits is the rounding, not a truncation', () {
    expect(trimTrailingZero(25.44, digits: 1), '25.4');
    expect(trimTrailingZero(25.46, digits: 1), '25.5');
  });
}
