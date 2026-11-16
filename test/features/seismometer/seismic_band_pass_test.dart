/// Compares the band-pass with the C++ fixture on signal c's h1.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dpip/features/seismometer/domain/seismic_band_pass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first 300 outputs match the reference on the 2 Hz, 50 gal h1 sine', () {
    final fixture = jsonDecode(
      File('test/fixtures/seismometer/jma_reference.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final reference = (fixture['bpf_h1_first_300'] as List<dynamic>)
        .map((v) => (v as num).toDouble())
        .toList();
    expect(reference, hasLength(300));

    // Signal c, axis h1: 50 * sin(2 * pi * 2 * t), t = index / 50.
    final filter = SeismicBandPass();
    var maxAbs = 0.0;
    var maxRel = 0.0;
    final problems = <String>[];
    for (var i = 0; i < reference.length; i++) {
      final t = i / 50.0;
      final got = filter.apply(50 * math.sin(2 * math.pi * 2 * t));
      final ref = reference[i];
      final absErr = (got - ref).abs();
      if (absErr > maxAbs) maxAbs = absErr;
      if (ref != 0) {
        final rel = absErr / ref.abs();
        if (rel > maxRel) maxRel = rel;
      }
      final ok = absErr <= 1e-4 || (ref != 0 && absErr / ref.abs() <= 1e-3);
      if (!ok) {
        problems.add('i=$i got=$got ref=$ref abs=$absErr');
      }
    }

    if (problems.isNotEmpty) {
      fail(
        'max abs=$maxAbs max rel=$maxRel (${problems.length})\n'
        '${problems.take(12).join('\n')}',
      );
    }
  });
}
