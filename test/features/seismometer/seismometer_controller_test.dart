/// Controller session: phases, intensity, gaps, and the waveform ring.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/accelerometer.dart';
import 'package:dpip/features/seismometer/domain/jma_intensity.dart';
import 'package:dpip/features/seismometer/domain/seismic_band_pass.dart';
import 'package:dpip/features/seismometer/presentation/seismometer_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const int _hz = 50;
const int _periodNanos = 1000000000 ~/ _hz;
const int _calibrationSamples = 3 * _hz;
const int _millisNanos = 1000000;
const int _gapLimitNanos = 200 * _millisNanos;

/// 2 Hz, 50 gal, the same value on every axis.
///
/// At 50 Hz the period is 25 samples. Calibration consumes 150 samples,
/// an integer number of periods, so the window that follows is the same
/// sequence as the first 60 seconds of this sine.
double _sine(int index) => 50 * math.sin(2 * math.pi * 2 * index / _hz);

double _waveH1(int outputIndex) => (outputIndex % 5) - 2;
double _waveH2(int outputIndex) => (outputIndex % 3) * 0.5;
double _waveV(int outputIndex) => (outputIndex % 4) - 1.5;

void main() {
  late _Harness harness;

  setUp(() {
    harness = _Harness();
    addTearDown(harness.dispose);
  });

  test('phases move idle, calibrating, buffering, measuring', () {
    final controller = harness.controller;
    expect(controller.phase, SeismometerPhase.idle);
    expect(controller.calibrationRemainingSeconds, 3);
    expect(controller.bufferProgress, 0);

    controller.start();
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(controller.calibrationRemainingSeconds, 3);

    harness.addSine(0, 1);
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(controller.calibrationRemainingSeconds, 3);

    harness.addSine(1, 49);
    expect(controller.calibrationRemainingSeconds, 2);

    harness.addSine(50, 50);
    expect(controller.calibrationRemainingSeconds, 1);

    harness.addSine(100, 49);
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(controller.calibrationRemainingSeconds, 1);

    harness.addSine(149, 1);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(controller.calibrationRemainingSeconds, 0);
    expect(controller.bufferProgress, 0);
    expect(controller.sampleRateHz, 50);

    harness.addSine(150, JmaIntensityCalculator.maxSamples ~/ 2);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(controller.bufferProgress, 0.5);

    harness.addSine(
      150 + JmaIntensityCalculator.maxSamples ~/ 2,
      JmaIntensityCalculator.maxSamples ~/ 2,
    );
    expect(controller.phase, SeismometerPhase.measuring);
    expect(controller.bufferProgress, 1);
    expect(controller.latest, isNotNull);
    expect(controller.sessionMax, same(controller.latest));
    expect(controller.sampleRateHz, 50);
    expect(controller.acceleration, greaterThan(0));
    expect(
      controller.peakAcceleration,
      greaterThanOrEqualTo(controller.acceleration),
    );
  });

  test('2 Hz 50 gal sine matches a direct intensity calculation', () {
    harness.controller.start();
    harness.addSine(0, _calibrationSamples + JmaIntensityCalculator.maxSamples);

    final direct = JmaIntensityCalculator();
    for (var i = 0; i < JmaIntensityCalculator.maxSamples; i++) {
      final gal = _sine(i);
      direct.add(gal, gal, gal);
    }
    final expected = direct.calculate();
    final latest = harness.controller.latest;
    expect(expected, isNotNull);
    expect(latest, isNotNull);
    expect(latest!.intensityClass, expected!.intensityClass);
    expect(
      (latest.intensity - expected.intensity).abs(),
      lessThanOrEqualTo(0.01),
    );
    final scale = expected.a.abs();
    final absolute = (latest.a - expected.a).abs();
    final relative = scale == 0 ? absolute : absolute / scale;
    expect(relative, lessThanOrEqualTo(0.01));
  });

  test('a gap over 200 ms returns to buffering and keeps session max', () {
    final controller = harness.controller;
    controller.start();
    harness.addSine(0, _calibrationSamples + JmaIntensityCalculator.maxSamples);
    expect(controller.phase, SeismometerPhase.measuring);

    final max = controller.sessionMax;
    final peak = controller.peakAcceleration;
    expect(max, isNotNull);
    expect(peak, greaterThan(0));

    final last = _calibrationSamples + JmaIntensityCalculator.maxSamples - 1;
    final lastStamp = last * _periodNanos;
    harness.addSample(lastStamp + _gapLimitNanos, 0, 0, 0);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(controller.sessionMax, same(max));

    harness.addSample(lastStamp + _gapLimitNanos + _gapLimitNanos + 1, 0, 0, 0);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(controller.sessionMax, same(max));
    expect(controller.peakAcceleration, peak);
    expect(controller.acceleration, 0);
    expect(controller.latest?.intensityClass, max!.intensityClass);
    expect(controller.bufferProgress, 1 / JmaIntensityCalculator.maxSamples);
  });

  test('an unavailable sensor sets the unavailable phase', () {
    final controller = harness.controller;
    controller.start();
    expect(controller.phase, SeismometerPhase.calibrating);

    final before = Log.talker.history.length;
    harness.input.addError(
      PlatformException(code: 'unavailable', message: 'no sensor'),
    );
    expect(controller.phase, SeismometerPhase.unavailable);
    expect(Log.talker.history.length, before);

    harness.addSine(0, 10);
    expect(controller.phase, SeismometerPhase.unavailable);

    controller.start();
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(controller.calibrationRemainingSeconds, 3);
  });

  test('other stream errors are logged and set unavailable', () {
    harness.controller.start();
    final before = Log.talker.history.length;
    harness.input.addError(StateError('read failed'));
    expect(harness.controller.phase, SeismometerPhase.unavailable);
    final lines = Log.talker.history
        .skip(before)
        .map((entry) => entry.generateTextMessage())
        .join('\n');
    expect(lines, contains('Seismometer accelerometer stream failed'));
  });

  test('a closed stream becomes unavailable', () async {
    final input = StreamController<List<AccelerometerSample>>.broadcast(
      sync: true,
    );
    final controller = SeismometerController(source: () => input.stream);
    addTearDown(controller.dispose);
    controller.start();
    final before = Log.talker.history.length;
    await input.close();
    expect(controller.phase, SeismometerPhase.unavailable);
    final lines = Log.talker.history
        .skip(before)
        .map((entry) => entry.generateTextMessage())
        .join('\n');
    expect(lines, contains('Seismometer accelerometer stream closed'));
  });

  test('stop returns to idle and start calibrates again', () {
    final controller = harness.controller;
    controller.start();
    harness.addSine(0, _calibrationSamples);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(controller.bufferProgress, 0);

    controller.stop();
    expect(controller.phase, SeismometerPhase.idle);
    expect(controller.calibrationRemainingSeconds, 3);
    expect(controller.bufferProgress, 0);
    expect(controller.latest, isNull);
    expect(controller.sessionMax, isNull);
    expect(controller.peakAcceleration, 0);
    expect(controller.acceleration, 0);
    expect(controller.waveform.length, 0);
    expect(controller.sampleRateHz, 0);

    controller.start();
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(controller.calibrationRemainingSeconds, 3);
    harness.addSine(0, _calibrationSamples - 1);
    expect(controller.phase, SeismometerPhase.calibrating);
    harness.addSine(_calibrationSamples - 1, 1);
    expect(controller.phase, SeismometerPhase.buffering);
  });

  test('resetSession clears session max and peak acceleration', () {
    final controller = harness.controller;
    controller.start();
    harness.addSine(0, _calibrationSamples + JmaIntensityCalculator.maxSamples);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(controller.sessionMax, isNotNull);
    expect(controller.peakAcceleration, greaterThan(0));
    final latest = controller.latest;

    controller.resetSession();
    expect(controller.sessionMax, isNull);
    expect(controller.peakAcceleration, 0);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(controller.latest, same(latest));

    final filled = _calibrationSamples + JmaIntensityCalculator.maxSamples;
    harness.addSine(filled, 25);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(controller.sessionMax, isNotNull);
    expect(controller.peakAcceleration, greaterThan(0));
  });

  test('measuring notifies once per half second of samples', () {
    final controller = harness.controller;
    var notifies = 0;
    controller.addListener(() => notifies++);

    controller.start();
    expect(notifies, 1);

    harness.addSine(0, _calibrationSamples - 1);
    expect(controller.phase, SeismometerPhase.calibrating);
    expect(notifies, 1);

    harness.addSine(_calibrationSamples - 1, 1);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(notifies, 2);

    harness.addSine(_calibrationSamples, 25);
    expect(controller.phase, SeismometerPhase.buffering);
    expect(notifies, 3);

    final before = notifies;
    final rest = JmaIntensityCalculator.maxSamples - 25;
    harness.addSine(_calibrationSamples + 25, rest);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(notifies - before, rest ~/ 25);

    final measured = notifies;
    final filled = _calibrationSamples + JmaIntensityCalculator.maxSamples;
    harness.addSine(filled, 100);
    expect(controller.phase, SeismometerPhase.measuring);
    expect(
      notifies - measured,
      4,
      reason: 'one listener call per 25 samples while measuring',
    );
  });

  test('waveform keeps 30 s of band-passed samples', () {
    final controller = harness.controller;
    var revisions = 0;
    controller.waveformRevision.addListener(() => revisions++);
    controller.start();
    expect(revisions, 0);

    harness.add(0, _calibrationSamples, (_) => 0, (_) => 0, (_) => 0);
    expect(revisions, 1);
    expect(controller.waveform.length, 0);
    expect(controller.phase, SeismometerPhase.buffering);

    const total = SeismicWaveform.capacity + 5;
    harness.add(
      _calibrationSamples,
      total,
      (index) => _waveH1(index - _calibrationSamples),
      (index) => _waveH2(index - _calibrationSamples),
      (index) => _waveV(index - _calibrationSamples),
    );
    expect(revisions, 2);

    final wave = controller.waveform;
    expect(wave.length, SeismicWaveform.capacity);
    final h1Band = SeismicBandPass();
    final h2Band = SeismicBandPass();
    final vBand = SeismicBandPass();
    const dropped = total - SeismicWaveform.capacity;
    for (var i = 0; i < dropped; i++) {
      h1Band.apply(_waveH1(i));
      h2Band.apply(_waveH2(i));
      vBand.apply(_waveV(i));
    }
    for (var i = 0; i < wave.length; i++) {
      expect(wave.h1(i), h1Band.apply(_waveH1(dropped + i)));
      expect(wave.h2(i), h2Band.apply(_waveH2(dropped + i)));
      expect(wave.v(i), vBand.apply(_waveV(dropped + i)));
    }
  });

  test('stop during a phase change can start calibration again', () {
    final controller = harness.controller;
    var stopOnBuffering = true;
    controller.addListener(() {
      if (stopOnBuffering && controller.phase == SeismometerPhase.buffering) {
        controller.stop();
      }
    });

    controller.start();
    harness.addSine(0, _calibrationSamples);
    expect(controller.phase, SeismometerPhase.idle);
    expect(controller.calibrationRemainingSeconds, 3);

    stopOnBuffering = false;
    controller.start();
    expect(controller.phase, SeismometerPhase.calibrating);
    harness.addSine(0, _calibrationSamples - 1);
    expect(controller.phase, SeismometerPhase.calibrating);
    harness.addSine(_calibrationSamples - 1, 1);
    expect(controller.phase, SeismometerPhase.buffering);
  });
}

final class _Harness {
  _Harness() {
    controller = SeismometerController(source: () => input.stream);
  }

  final input = StreamController<List<AccelerometerSample>>.broadcast(
    sync: true,
  );
  late final SeismometerController controller;

  void addSine(int from, int count) => add(from, count, _sine, _sine, _sine);

  void add(
    int from,
    int count,
    double Function(int index) x,
    double Function(int index) y,
    double Function(int index) z,
  ) {
    final batch = List<AccelerometerSample>.generate(count, (offset) {
      final index = from + offset;
      return AccelerometerSample(
        timestampNanos: index * _periodNanos,
        x: x(index),
        y: y(index),
        z: z(index),
      );
    }, growable: false);
    input.add(batch);
  }

  void addSample(int timestampNanos, double x, double y, double z) {
    input.add([
      AccelerometerSample(timestampNanos: timestampNanos, x: x, y: y, z: z),
    ]);
  }

  Future<void> dispose() async {
    controller.dispose();
    await input.close();
  }
}
