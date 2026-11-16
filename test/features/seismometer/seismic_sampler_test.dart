import 'package:dpip/features/seismometer/domain/seismic_sampler.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Sample = ({double h1, double h2, double v});

const _nanosPerMillisecond = 1000000;
const _periodNanos = 20 * _nanosPerMillisecond;
const _perSecond = 50;

/// 1 s discarded plus 2 s averaged.
const _calibrationSamples = _perSecond + _perSecond * 2;

const _tol = 1e-9;

/// 60 LSB at ±2 g: `(9.80665 * 100) / 16384` gal per LSB.
const _quietThresholdGal = 60 * (9.80665 * 100 / 16384);

void main() {
  group('SeismicSampler', () {
    test('evenly spaced samples match the input after the offset', () {
      final run = _Run();
      _feed(run.sampler, 0, _calibrationSamples, 0, 0, 0);
      expect(run.samples, isEmpty);

      const count = 25;
      for (var i = 0; i < count; i++) {
        final step = (i + 1).toDouble();
        run.sampler.addRaw(
          (_calibrationSamples + i) * _periodNanos,
          step,
          step * 10,
          -step,
        );
      }

      expect(run.samples, hasLength(count));
      for (var i = 0; i < count; i++) {
        final step = (i + 1).toDouble();
        _expectSample(run.samples[i], step, step * 10, -step);
      }

      final before = run.samples.length;
      final last = _calibrationSamples + count - 1;
      run.sampler.addRaw(last * _periodNanos, 999, 999, 999);
      run.sampler.addRaw((last - 1) * _periodNanos, 999, 999, 999);
      expect(run.samples, hasLength(before));
      expect(run.events, isNot(contains('gap')));
      expect(run.sampler.calibrating, isFalse);
      expect(run.sampler.calibrationRemainingSamples, 0);
    });

    test('jittered timestamps interpolate between raw samples', () {
      final run = _Run();
      _feed(run.sampler, 0, _calibrationSamples, 0, 0, 0);

      // Grid anchor is the last calibration sample, value 0.
      // +40 ms, value (40, 80, -20): points at 1/2 and at the sample.
      // +120 ms, value (80, 160, -40): points at 1/4, 1/2, 3/4, and 1.
      // +130 ms, value (90, 180, -45): still before the next grid point.
      // +150 ms, value (110, 220, -55), sits between grid points. The
      // output 10 ms earlier is the midpoint of that pair.
      final origin = (_calibrationSamples - 1) * _periodNanos;
      run.sampler.addRaw(origin + 40 * _nanosPerMillisecond, 40, 80, -20);
      run.sampler.addRaw(origin + 120 * _nanosPerMillisecond, 80, 160, -40);
      run.sampler.addRaw(origin + 130 * _nanosPerMillisecond, 90, 180, -45);
      run.sampler.addRaw(origin + 150 * _nanosPerMillisecond, 110, 220, -55);

      expect(run.events, isNot(contains('gap')));
      expect(run.samples, hasLength(7));
      const expected = <(double, double, double)>[
        (20, 40, -10),
        (40, 80, -20),
        (50, 100, -25),
        (60, 120, -30),
        (70, 140, -35),
        (80, 160, -40),
        (100, 200, -50),
      ];
      for (var i = 0; i < expected.length; i++) {
        final point = expected[i];
        _expectSample(run.samples[i], point.$1, point.$2, point.$3);
      }
    });

    test('a gap over 200 ms restarts the grid', () {
      final run = _Run();
      _feed(run.sampler, 0, _calibrationSamples, 0, 0, 0);

      // Exactly 200 ms stays one segment: ten grid points, tenths of the
      // raw span from (0, 0, 0) to (100, 50, -100).
      final end = (_calibrationSamples - 1 + 10) * _periodNanos;
      run.sampler.addRaw(end, 100, 50, -100);
      expect(run.events, isNot(contains('gap')));
      expect(run.samples, hasLength(10));
      for (var k = 1; k <= 10; k++) {
        _expectSample(
          run.samples[k - 1],
          100 * k / 10,
          50 * k / 10,
          -100 * k / 10,
        );
      }

      final gapAt = end + 200 * _nanosPerMillisecond + 1;
      run.sampler.addRaw(gapAt, 0, 10, 20);
      expect(run.events.indexOf('gap'), 10);
      _expectSample(run.samples[10], 0, 10, 20);
      expect(run.sampler.calibrating, isFalse);
      expect(run.sampler.calibrationRemainingSamples, 0);

      // New grid: 20 ms is the midpoint of the 40 ms span, then the sample.
      run.sampler.addRaw(gapAt + 40 * _nanosPerMillisecond, 40, 50, 60);
      _expectSample(run.samples[11], 20, 30, 40);
      _expectSample(run.samples[12], 40, 50, 60);
      expect(run.samples, hasLength(13));
      expect(run.events.where((event) => event == 'gap').length, 1);
    });

    test('calibration counts interpolated points', () {
      final run = _Run();
      expect(run.sampler.calibrating, isTrue);
      expect(run.sampler.calibrationRemainingSamples, _calibrationSamples);

      run.sampler.addRaw(0, 0, 0, 0);
      expect(run.sampler.calibrationRemainingSamples, _calibrationSamples - 1);

      run.sampler.addRaw(40 * _nanosPerMillisecond, 0, 0, 0);
      // Points at 0, 20 ms, and 40 ms.
      expect(run.sampler.calibrationRemainingSamples, _calibrationSamples - 3);
      expect(run.samples, isEmpty);
    });

    test('the first second is discarded and the next two set the offset', () {
      final run = _Run();
      _feed(run.sampler, 0, _perSecond, 100, -50, 7);
      expect(run.samples, isEmpty);
      expect(run.sampler.calibrating, isTrue);
      expect(run.sampler.calibrationRemainingSamples, _perSecond * 2);

      _feed(run.sampler, _perSecond, _perSecond * 2, 4, 8, 980);
      expect(run.samples, isEmpty);
      expect(run.sampler.calibrating, isFalse);
      expect(run.sampler.calibrationRemainingSamples, 0);

      _feed(run.sampler, _calibrationSamples, 1, 9, 5, 983);
      _expectSample(run.samples.single, 5, -3, 3);

      _feed(run.sampler, _calibrationSamples + 1, 1, 4, 8, 980);
      _expectSample(run.samples[1], 0, 0, 0);
    });

    test('a steady gravity offset comes out near zero', () {
      final run = _Run();
      for (var i = 0; i < _calibrationSamples; i++) {
        final noise = i.isEven ? 0.25 : -0.25;
        run.sampler.addRaw(i * _periodNanos, noise, noise * 2, 980 + noise);
      }
      expect(run.samples, isEmpty);

      for (var i = 0; i < 10; i++) {
        final index = _calibrationSamples + i;
        final noise = index.isEven ? 0.25 : -0.25;
        run.sampler.addRaw(index * _periodNanos, noise, noise * 2, 980 + noise);
        _expectSample(run.samples[i], noise, noise * 2, noise);
      }
      expect(run.samples, hasLength(10));
    });

    test('ninety quiet seconds replace the offset', () {
      final run = _Run();
      _feed(run.sampler, 0, _perSecond, 0, 0, 0);
      _feed(run.sampler, _perSecond, _perSecond * 2, 5, -2, 980);
      expect(run.samples, isEmpty);

      const level = (8.0, 1.0, 975.0);
      _feed(run.sampler, _calibrationSamples, 89 * _perSecond, 8, 1, 975);
      _expectSample(run.samples.last, 3, 3, -5);

      final beforeUpdate = run.samples.length;
      _feed(
        run.sampler,
        _calibrationSamples + 89 * _perSecond,
        _perSecond,
        level.$1,
        level.$2,
        level.$3,
      );
      _expectSample(run.samples[beforeUpdate + 48], 3, 3, -5);
      _expectSample(run.samples.last, 0, 0, 0);

      // The quiet count is back at zero, so the next second keeps the offset
      // that the ninetieth second just stored.
      _feed(
        run.sampler,
        _calibrationSamples + 90 * _perSecond,
        _perSecond,
        10,
        4,
        970,
      );
      _expectSample(run.samples.last, 2, 3, -5);
    });

    test('a peak-to-peak of the quiet threshold stays quiet', () {
      final run = _Run();
      _feed(run.sampler, 0, _calibrationSamples, 0, 0, 0);

      for (var i = 0; i < 90 * _perSecond; i++) {
        final x = i.isOdd ? _quietThresholdGal : 0.0;
        run.sampler.addRaw((_calibrationSamples + i) * _periodNanos, x, 0, 0);
      }

      expect(run.samples, hasLength(90 * _perSecond));
      _expectSample(run.samples[89 * _perSecond - 1], _quietThresholdGal, 0, 0);
      _expectSample(run.samples[90 * _perSecond - 2], 0, 0, 0);
      _expectSample(
        run.samples[90 * _perSecond - 1],
        _quietThresholdGal / 2,
        0,
        0,
      );
    });

    test('one non-quiet second clears the quiet count', () {
      final run = _Run();
      _feed(run.sampler, 0, _calibrationSamples, 0, 0, 0);

      const biasX = 2.0;
      const biasY = -4.0;
      const biasZ = 6.0;
      final spikeX = biasX + _quietThresholdGal + 1e-6;

      _feed(
        run.sampler,
        _calibrationSamples,
        89 * _perSecond,
        biasX,
        biasY,
        biasZ,
      );
      _expectSample(run.samples.last, biasX, biasY, biasZ);

      final noisyAt = _calibrationSamples + 89 * _perSecond;
      run.sampler.addRaw(noisyAt * _periodNanos, spikeX, biasY, biasZ);
      _expectSample(run.samples.last, spikeX, biasY, biasZ);
      _feed(run.sampler, noisyAt + 1, _perSecond - 1, biasX, biasY, biasZ);
      _expectSample(run.samples.last, biasX, biasY, biasZ);

      final afterNoise = noisyAt + _perSecond;
      _feed(run.sampler, afterNoise, 89 * _perSecond, biasX, biasY, biasZ);
      _expectSample(run.samples.last, biasX, biasY, biasZ);

      final lastRun = afterNoise + 89 * _perSecond;
      _feed(run.sampler, lastRun, _perSecond - 1, biasX, biasY, biasZ);
      _expectSample(run.samples.last, biasX, biasY, biasZ);
      _feed(run.sampler, lastRun + _perSecond - 1, 1, biasX, biasY, biasZ);
      _expectSample(run.samples.last, 0, 0, 0);
    });

    test('reset clears calibration and the raw timeline', () {
      final run = _Run();
      _feed(run.sampler, 0, 80, 50, 50, 50);
      expect(run.sampler.calibrating, isTrue);
      expect(run.sampler.calibrationRemainingSamples, _calibrationSamples - 80);

      run.sampler.reset();
      expect(run.sampler.calibrating, isTrue);
      expect(run.sampler.calibrationRemainingSamples, _calibrationSamples);
      expect(run.samples, isEmpty);

      _feed(run.sampler, 10000, _perSecond, 9, 9, 9);
      _feed(run.sampler, 10000 + _perSecond, _perSecond * 2, 3, 4, 5);
      expect(run.events, isNot(contains('gap')));
      expect(run.sampler.calibrating, isFalse);

      _feed(run.sampler, 10000 + _calibrationSamples, 1, 6, 4, 5);
      _expectSample(run.samples.single, 3, 0, 0);
    });
  });
}

class _Run {
  _Run() {
    sampler = SeismicSampler(
      onSample: (h1, h2, v) {
        samples.add((h1: h1, h2: h2, v: v));
        events.add('sample');
      },
      onGap: () => events.add('gap'),
    );
  }

  final samples = <_Sample>[];
  final events = <String>[];
  late final SeismicSampler sampler;
}

void _feed(
  SeismicSampler sampler,
  int from,
  int count,
  double x,
  double y,
  double z,
) {
  for (var i = 0; i < count; i++) {
    sampler.addRaw((from + i) * _periodNanos, x, y, z);
  }
}

void _expectSample(_Sample sample, double h1, double h2, double v) {
  expect(sample.h1, closeTo(h1, _tol));
  expect(sample.h2, closeTo(h2, _tol));
  expect(sample.v, closeTo(v, _tol));
}
