import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
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

  test('point size matches the web (TUNE: zoom lin)', () {
    expect(pointSizeFor(3), closeTo(1.5, 1e-9));
    expect(pointSizeFor(4), closeTo(1.575, 1e-9));
    expect(pointSizeFor(5), closeTo(1.65, 1e-9));
    expect(pointSizeFor(6), closeTo(1.725, 1e-9));
    expect(pointSizeFor(7), closeTo(1.8, 1e-9));
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

  group('fade opacity (TUNE: zoom lin)', () {
    test('matches the web at every stop', () {
      expect(fadeOpacityFor(3), closeTo(0.95, 1e-9));
      expect(fadeOpacityFor(5), closeTo(0.9475, 1e-9));
      expect(fadeOpacityFor(7), closeTo(0.945, 1e-9));
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
