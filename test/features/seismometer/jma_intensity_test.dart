/// Recomputes the generator's signals and compares them with the C++ fixture.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dpip/features/seismometer/domain/jma_intensity.dart';
import 'package:flutter_test/flutter_test.dart';

// LCG, seed 1: state = (1664525 * state + 1013904223) mod 2^32,
// uniform = (state + 0.5) / 2^32, sample = (uniform * 2 - 1) * 2 gal.
// Draws for one sample are h1, then h2, then v.
const int _lcgA = 1664525;
const int _lcgC = 1013904223;
const int _lcgSeed = 1;
const int _lcgMask = 0xFFFFFFFF;
const double _lcgModulus = 4294967296.0;
const double _lcgAmplitudeGal = 2;
const int _burstStartSec = 40;
const int _burstEndSec = 43;
const int _burstHz = 3;
const double _burstGal = 300;

final class _Lcg {
  _Lcg(this.state);

  int state;

  double nextGal() {
    state = (state * _lcgA + _lcgC) & _lcgMask;
    final uniform = (state + 0.5) / _lcgModulus;
    return (uniform * 2.0 - 1.0) * _lcgAmplitudeGal;
  }
}

final class _Stats {
  final problems = <String>[];
  double maxAbsI = 0.0;
  double maxRelA = 0.0;

  void add(_Stats other) {
    problems.addAll(other.problems);
    if (other.maxAbsI > maxAbsI) maxAbsI = other.maxAbsI;
    if (other.maxRelA > maxRelA) maxRelA = other.maxRelA;
  }
}

/// t = index / 50. Sine is amp * sin(2 * pi * hz * t).
({double h1, double h2, double v}) _sample(String id, int index, _Lcg lcg) {
  final t = index / JmaIntensityCalculator.samplingRate;
  switch (id) {
    case 'zeros':
      return (h1: 0.0, h2: 0.0, v: 0.0);
    case 'h1_sine_1hz_10gal':
      return (h1: 10 * math.sin(2 * math.pi * 1 * t), h2: 0.0, v: 0.0);
    case 'axes_sine_2hz_50gal':
      final s = 50 * math.sin(2 * math.pi * 2 * t);
      return (h1: s, h2: s, v: s);
    case 'h2_sine_5hz_200gal':
      return (h1: 0.0, h2: 200 * math.sin(2 * math.pi * 5 * t), v: 0.0);
    case 'lcg_noise_2gal':
      return (h1: lcg.nextGal(), h2: lcg.nextGal(), v: lcg.nextGal());
    case 'lcg_noise_burst_3hz_300gal':
      final burst = (t >= _burstStartSec && t < _burstEndSec)
          ? _burstGal * math.sin(2 * math.pi * _burstHz * t)
          : 0.0;
      return (
        h1: lcg.nextGal() + burst,
        h2: lcg.nextGal() + burst,
        v: lcg.nextGal() + burst,
      );
    default:
      throw StateError(id);
  }
}

void _compare(
  String id,
  int n,
  JmaIntensityResult result,
  Map<String, dynamic> record,
  _Stats stats,
) {
  final raw = record['intensity'];
  if (raw == null) {
    // log10(0) is -infinity; the fixture writes null for that.
    if (result.intensity != double.negativeInfinity) {
      stats.maxAbsI = double.infinity;
      stats.problems.add(
        '$id@$n intensity ${result.intensity} expected -infinity',
      );
    }
  } else {
    final expected = (raw as num).toDouble();
    if (!result.intensity.isFinite) {
      stats.maxAbsI = double.infinity;
      stats.problems.add('$id@$n intensity non-finite, reference $expected');
    } else {
      final delta = (result.intensity - expected).abs();
      if (delta > stats.maxAbsI) stats.maxAbsI = delta;
      if (delta > 0.01) {
        stats.problems.add(
          '$id@$n |dI|=$delta got=${result.intensity} ref=$expected',
        );
      }
    }
  }

  final cls = record['class'] as String;
  if (result.intensityClass != cls) {
    stats.problems.add('$id@$n class ${result.intensityClass} != $cls');
  }

  final refA = (record['a'] as num).toDouble();
  final absA = (result.a - refA).abs();
  final rel = refA == 0
      ? (absA == 0 ? 0.0 : double.infinity)
      : absA / refA.abs();
  if (rel > stats.maxRelA) stats.maxRelA = rel;
  if (rel > 0.01) {
    stats.problems.add('$id@$n rel a=$rel got=${result.a} ref=$refA');
  }
}

_Stats _runSignal(JmaIntensityCalculator calc, Map<String, dynamic> signal) {
  final id = signal['id'] as String;
  final records = signal['records'] as List<dynamic>;
  final lcg = _Lcg(_lcgSeed);
  final stats = _Stats();
  var fed = 0;
  for (final item in records) {
    final record = item as Map<String, dynamic>;
    final n = record['n'] as int;
    while (fed < n) {
      final sample = _sample(id, fed, lcg);
      calc.add(sample.h1, sample.h2, sample.v);
      fed++;
    }
    final result = calc.calculate();
    if (result == null) {
      stats.problems.add('$id@$n calculate() returned null');
      continue;
    }
    _compare(id, n, result, record, stats);
  }
  return stats;
}

void _expectWithin(_Stats stats) {
  if (stats.problems.isNotEmpty) {
    final head = stats.problems.take(12).join('\n');
    fail(
      'max |dI|=${stats.maxAbsI} max rel a=${stats.maxRelA} '
      '(${stats.problems.length} samples)\n$head',
    );
  }
  expect(stats.maxAbsI, lessThanOrEqualTo(0.01));
  expect(stats.maxRelA, lessThanOrEqualTo(0.01));
}

void main() {
  late Map<String, dynamic> fixture;

  setUpAll(() {
    fixture = jsonDecode(
      File('test/fixtures/seismometer/jma_reference.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('fixture metadata matches the signal formulas', () {
    expect(fixture['sample_rate_hz'], JmaIntensityCalculator.samplingRate);
    expect(fixture['window_samples'], JmaIntensityCalculator.maxSamples);
    expect(fixture['duration_sec'], 70);
    expect(fixture['record_every'], 50);
    expect(fixture['sample_count'], 70 * JmaIntensityCalculator.samplingRate);
    expect(fixture['lcg_a'], _lcgA);
    expect(fixture['lcg_c'], _lcgC);
    expect(fixture['lcg_seed'], _lcgSeed);
    expect(fixture['lcg_amplitude_gal'], _lcgAmplitudeGal);
    expect(fixture['burst_start_sec'], _burstStartSec);
    expect(fixture['burst_end_sec'], _burstEndSec);
    expect(fixture['burst_hz'], _burstHz);
    expect(fixture['burst_gal'], _burstGal);

    final signals = fixture['signals'] as List<dynamic>;
    expect(signals.map((s) => (s as Map<String, dynamic>)['id']).toList(), [
      'zeros',
      'h1_sine_1hz_10gal',
      'axes_sine_2hz_50gal',
      'h2_sine_5hz_200gal',
      'lcg_noise_2gal',
      'lcg_noise_burst_3hz_300gal',
    ]);
    final sampleCount = fixture['sample_count'] as int;
    final window = fixture['window_samples'] as int;
    final every = fixture['record_every'] as int;
    final expected = (sampleCount - window) ~/ every + 1;
    for (final item in signals) {
      final signal = item as Map<String, dynamic>;
      final records = signal['records'] as List<dynamic>;
      expect(records.length, expected, reason: signal['id'] as String);
      var previous = window - every;
      for (final rec in records) {
        final n = (rec as Map<String, dynamic>)['n'] as int;
        expect(n, previous + every, reason: signal['id'] as String);
        previous = n;
      }
    }
  });

  test('calculate returns null until the 60 s window is full', () {
    final calc = JmaIntensityCalculator();
    expect(calc.bufferedSamples, 0);
    expect(calc.hasEnoughData, isFalse);
    expect(calc.calculate(), isNull);

    for (var i = 0; i < JmaIntensityCalculator.maxSamples - 1; i++) {
      calc.add(0.0, 0.0, 0.0);
    }
    expect(calc.bufferedSamples, JmaIntensityCalculator.maxSamples - 1);
    expect(calc.hasEnoughData, isFalse);
    expect(calc.calculate(), isNull);

    calc.add(0.0, 0.0, 0.0);
    expect(calc.bufferedSamples, JmaIntensityCalculator.maxSamples);
    expect(calc.hasEnoughData, isTrue);
    expect(calc.calculate(), isNotNull);

    calc.add(0.0, 0.0, 0.0);
    expect(calc.bufferedSamples, JmaIntensityCalculator.maxSamples);
    expect(calc.hasEnoughData, isTrue);
  });

  test('reset drops the window and the next one matches the reference', () {
    final signals = fixture['signals'] as List<dynamic>;
    final h1 = signals.cast<Map<String, dynamic>>().firstWhere(
      (s) => s['id'] == 'h1_sine_1hz_10gal',
    );

    final calc = JmaIntensityCalculator();
    for (var i = 0; i < JmaIntensityCalculator.maxSamples; i++) {
      calc.add(999.0, 999.0, 999.0);
    }
    expect(calc.calculate(), isNotNull);

    calc.reset();
    expect(calc.bufferedSamples, 0);
    expect(calc.hasEnoughData, isFalse);
    expect(calc.calculate(), isNull);

    _expectWithin(_runSignal(calc, h1));
  });

  test('matches the C++ reference on every recorded sample', () {
    final signals = fixture['signals'] as List<dynamic>;
    final stats = _Stats();
    for (final item in signals) {
      final calc = JmaIntensityCalculator();
      stats.add(_runSignal(calc, item as Map<String, dynamic>));
    }
    _expectWithin(stats);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
