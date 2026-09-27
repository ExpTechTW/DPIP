/// The station dots' colours — rts-image-go's table, as TREM-Lite paints it.
///
/// Two surfaces read this: the MapLibre expression that colours each dot, and
/// the legend and any Flutter swatch through [InstrumentalIntensityColors.of].
/// They must pick the same entry for the same reading, including at the two
/// places a naive port slips: every reading at or below 0 is the darkest blue
/// (not a ramp through negative values), and a reading halfway between two
/// tenths rounds away from zero, as Go's `math.Round` and MapLibre's `round`
/// both do.
library;

import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evaluates the expression's `step` for a table-scale value in tenths.
Object _stepFor(List<Object> expression, int tenth) {
  var output = expression[2];
  for (var k = 3; k + 1 < expression.length; k += 2) {
    if (tenth >= (expression[k] as int)) output = expression[k + 1];
  }
  return output;
}

void main() {
  test('the table scale: ≤0 bottoms out, 0→1 is blue→green, 1→7 the rest', () {
    expect(InstrumentalIntensityColors.tableScale(-2.5), -3);
    expect(InstrumentalIntensityColors.tableScale(0), -3);
    expect(InstrumentalIntensityColors.tableScale(0.5), -1.5);
    expect(InstrumentalIntensityColors.tableScale(1), 0);
    expect(InstrumentalIntensityColors.tableScale(7), 7);
  });

  test('readings land on rts-image-go\'s colours', () {
    expect(InstrumentalIntensityColors.of(-1), const Color(0xFF0000CD));
    expect(InstrumentalIntensityColors.of(0.5), const Color(0xFF008CC2));
    expect(InstrumentalIntensityColors.of(1), const Color(0xFF3FFA36));
    expect(InstrumentalIntensityColors.of(4), const Color(0xFFFFB600));
    expect(InstrumentalIntensityColors.of(7), const Color(0xFFAA0000));
    expect(InstrumentalIntensityColors.of(9), const Color(0xFFAA0000));
  });

  test('the map expression picks the same entry as of() for every tenth', () {
    final expression = InstrumentalIntensityColors.mapLibreExpression;
    expect(expression.first, 'step');
    for (var tenth = -35; tenth <= 75; tenth++) {
      final scale = tenth / 10;
      // Invert the table scale above 1 to get a reading on that tenth.
      final reading = scale <= 0 ? (scale + 3) / 3 : scale * 6 / 7 + 1;
      expect(
        _stepFor(expression, tenth),
        InstrumentalIntensityColors.of(reading).toHexRgb(),
        reason: 'tenth $tenth',
      );
    }
  });
}
