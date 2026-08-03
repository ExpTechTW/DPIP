import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ticks an axis would show for a data range, using the same snapping the
/// chart applies (half a step of headroom, bounds rounded onto the step).
List<double> _ticks(double lo, double hi) {
  final step = niceAxisStep((hi - lo).abs(), 8);
  final head = step / 2;
  final min = ((lo - head) / step).floorToDouble() * step;
  final max = ((hi + head) / step).ceilToDouble() * step;
  final ticks = <double>[];
  for (var v = min; v <= max + 1e-9; v += step) {
    ticks.add(double.parse(v.toStringAsFixed(4)));
  }
  return ticks;
}

void main() {
  group('niceTimeLabelStepSec', () {
    test('24h span → 2h labels (~12 ticks)', () {
      const day = 24 * 3600.0;
      final step = niceTimeLabelStepSec(day, targetTicks: 12);
      expect(step, 2 * 3600);
      expect((day / step).round(), 12);
    });

    test('wind 24h aims for fewer labels (3h)', () {
      const day = 24 * 3600.0;
      final step = niceTimeLabelStepSec(day, targetTicks: 8);
      expect(step, 3 * 3600);
    });

    test('7d span → daily labels', () {
      const week = 7 * 24 * 3600.0;
      final step = niceTimeLabelStepSec(week, targetTicks: 8);
      expect(step, 24 * 3600);
    });

    test('steps are always a nice clock hour', () {
      for (final spanH in [6.0, 12.0, 24.0, 48.0, 168.0]) {
        final stepH = niceTimeLabelStepSec(spanH * 3600) / 3600;
        expect(
          [1, 2, 3, 4, 6, 8, 12, 24, 48, 72],
          contains(stepH.toInt()),
          reason: 'span ${spanH}h → ${stepH}h',
        );
      }
    });
  });

  group('niceAxisStep', () {
    test('picks a 1/2/5 × 10ⁿ step', () {
      for (final span in [0.4, 1.5, 3.0, 7.0, 15.0, 35.0, 90.0, 400.0]) {
        final step = niceAxisStep(span, 8);
        final mantissa = step / _magnitude(step);
        expect(
          [1.0, 2.0, 5.0, 10.0],
          contains(double.parse(mantissa.toStringAsFixed(6))),
          reason: 'span $span gave a non-round step $step',
        );
      }
    });

    test('ticks are evenly spaced — the bug the axis had', () {
      // The live chart showed 35, 34, 32: unequal gaps, which makes the eye
      // misread every slope. Every range must now yield one constant gap.
      for (final (lo, hi) in const [
        (31.5, 34.0), // temperature
        (58.0, 96.0), // humidity %
        (1002.0, 1013.0), // pressure hPa
        (0.0, 0.6), // light rain
      ]) {
        final ticks = _ticks(lo, hi);
        expect(ticks.length, greaterThanOrEqualTo(3));
        final gap = ticks[1] - ticks[0];
        for (var i = 1; i < ticks.length; i++) {
          expect(
            ticks[i] - ticks[i - 1],
            closeTo(gap, 1e-9),
            reason: 'uneven gap in $ticks for $lo–$hi',
          );
        }
      }
    });

    test('the data always sits inside the axis, with headroom', () {
      for (final (lo, hi) in const [(31.5, 34.0), (0.0, 0.6), (58.0, 96.0)]) {
        final ticks = _ticks(lo, hi);
        expect(ticks.first, lessThan(lo));
        expect(ticks.last, greaterThan(hi));
      }
    });

    test('a flat series still yields a usable axis', () {
      // Every reading identical — span 0 must not divide by zero or collapse.
      final step = niceAxisStep(0, 8);
      expect(step, greaterThan(0));
      expect(_ticks(20.0, 20.0).length, greaterThanOrEqualTo(2));
    });

    test('0–100 humidity span yields a 20 step (~5 intervals)', () {
      expect(niceAxisStep(100, 8), 20);
    });
  });
}

double _magnitude(double step) {
  var m = 1.0;
  while (step / m >= 10) {
    m *= 10;
  }
  while (step / m < 1) {
    m /= 10;
  }
  return m;
}
