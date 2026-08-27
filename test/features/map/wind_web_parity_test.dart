import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Every number here was computed by running `effective()` from
/// `satellite-tiles-go/web/index.html` over its own `DEFAULTS` and `TUNE`.
///
/// The two renderers only agree because one copies the other, and values tuned
/// by dragging a slider cannot be re-derived from anything. So the agreement is
/// pinned rather than trusted: if the web's tuning moves, these fail and say
/// which way to move with it.
void main() {
  group('particle count (TUNE: zoom log, rounded to a square)', () {
    test('matches the web at every stop', () {
      expect(particleCountFor(3), 6400);
      expect(particleCountFor(4), 4096);
      expect(particleCountFor(5), 2601);
      expect(particleCountFor(6), 1600);
      expect(particleCountFor(7), 1024);
    });

    test('is held flat outside the stops, not extrapolated', () {
      expect(particleCountFor(1), 6400);
      expect(particleCountFor(12), 1024);
    });

    test('is always a perfect square', () {
      for (var z = 3.0; z <= 7.0; z += 0.25) {
        final n = particleCountFor(z);
        final edge = _isqrt(n);
        expect(edge * edge, n, reason: 'z$z gave $n');
      }
    });
  });

  test('line width matches the reference integer-zoom table', () {
    expect(lineWidthFor(3), closeTo(1, 1e-9));
    expect(lineWidthFor(4), closeTo(1.2, 1e-9));
    expect(lineWidthFor(5), closeTo(1.6, 1e-9));
    expect(lineWidthFor(6), closeTo(1.8, 1e-9));
    expect(lineWidthFor(7), closeTo(2, 1e-9));
    expect(lineWidthFor(4.5), closeTo(1.4, 1e-9));
  });

  test('rendered stroke includes the reference physical-pixel fringe', () {
    // z6: max(1, 1.8 × 1.3 × 2.625) + one physical AA pixel.
    expect(pointSizeFor(6, pixelRatio: 2.625), closeTo(7.1425 / 2.625, 1e-9));
    expect(pointSizeFor(3), closeTo(2.3, 1e-9));
  });

  test('field step matches the web (TUNE: zoom log)', () {
    // Relative, because the reference values were printed to eight figures.
    void expectStep(double zoom, double speedFactor) {
      final want = 0.0001 * speedFactor;
      expect(fieldStepFor(zoom), closeTo(want, want * 1e-7));
    }

    expectStep(3, 0.2);
    expectStep(4, 0.10483752);
    expectStep(5, 0.05495453);
    expectStep(6, 0.02880648);
    expectStep(7, 0.0151);
  });

  group('fade opacity', () {
    // Deliberately NOT the reference's 0.97. DPIP renders the short dash the
    // old Flutter overlay drew — 14 frames of history — rather than Windy's
    // second-long streak, and 0.85 is where the exponential lands the same
    // window (`0.85^14 = 0.10`). See kWindFadeOpacity for the reasoning.
    test('is constant across the zoom range', () {
      expect(fadeOpacityFor(3), closeTo(0.85, 1e-9));
      expect(fadeOpacityFor(5), closeTo(0.85, 1e-9));
      expect(fadeOpacityFor(7), closeTo(0.85, 1e-9));
    });

    test('keeps a stroke visible for roughly the intended window', () {
      // The look this replaced showed 14 frames of history and nothing older.
      final f = fadeOpacityFor(5);
      expect(
        math.pow(f, 14),
        lessThan(0.15),
        reason: 'the tail should be gone',
      );
      expect(math.pow(f, 5), greaterThan(0.3), reason: 'but not immediately');
    });

    test('never reaches 1, at any zoom', () {
      // A fade that does not fade accumulates every frame and the screen
      // saturates to white — the web says so in TUNE and means it.
      for (var z = 0.0; z <= 14.0; z += 0.5) {
        expect(fadeOpacityFor(z), lessThan(1.0));
        expect(fadeOpacityFor(z), greaterThan(0.5));
      }
    });
  });

  group('density weighting', () {
    test('matches the web ramp', () {
      expect(densityWeight(0), closeTo(0.5, 1e-9));
      expect(densityWeight(4), closeTo(1.060619, 1e-6));
      expect(densityWeight(9.6), closeTo(3.0, 1e-9));
      expect(densityWeight(16), closeTo(5.129630, 1e-6));
      expect(densityWeight(19.2), closeTo(5.5, 1e-9));
    });

    test('saturates rather than running away past the ramp', () {
      expect(densityWeight(32), closeTo(5.5, 1e-9));
      expect(densityWeight(200), closeTo(5.5, 1e-9));
    });

    test('favours strong wind by eleven to one', () {
      // The direction matters and it is the opposite of what it once was: the
      // Dart port still had the older ratio, six to one the other way.
      expect(densityWeight(19.2) / densityWeight(0), closeTo(11, 1e-9));
    });
  });
}

int _isqrt(int n) {
  var r = 0;
  while ((r + 1) * (r + 1) <= n) {
    r++;
  }
  return r;
}
