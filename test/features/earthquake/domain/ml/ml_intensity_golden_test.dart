/// ML v1 against onnxruntime itself: 600 golden cases and three whole-island
/// level maps, recorded from onnxruntime 1.30.0 (TREM-Lite's
/// `ml_intensity_golden.py`).
///
/// The point of porting the model to the bit is that this monitor, TREM-Lite
/// and the server colour the same township the same level for the same quake.
/// A port that is merely close disagrees exactly at the level boundaries —
/// the townships where the colour, and the push, change. So PGA and PGV are
/// held to the bit when fed the recorded features; features worked out here
/// are held to within one f32 ulp (the platform's libm is not Python's) with
/// the level still equal.
///
/// The model is 14.7 MB and is downloaded by the app, not committed. The test
/// reads it from `DPIP_ML_MODEL`, or from a TREM-Lite checkout beside this
/// one, and is skipped — saying so — when neither is there.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/ml/ml_f32.dart';
import 'package:dpip/features/earthquake/domain/ml/ml_intensity_model.dart';
import 'package:flutter_test/flutter_test.dart';

File? _modelFile() {
  for (final path in [
    Platform.environment['DPIP_ML_MODEL'],
    '../TREM-Lite/packages/core/static/models/intensity_ml_v1.onnx',
  ]) {
    if (path != null && File(path).existsSync()) return File(path);
  }
  return null;
}

final Map<String, dynamic> _golden = jsonDecode(
  File('test/features/earthquake/domain/ml/fixtures/ml_intensity_golden.json')
      .readAsStringSync(),
) as Map<String, dynamic>;

List<Map<String, dynamic>> get _cases =>
    (_golden['cases'] as List).cast<Map<String, dynamic>>();

void main() {
  final file = _modelFile();
  final skip = file == null
      ? 'intensity_ml_v1.onnx not found: set DPIP_ML_MODEL to its path'
      : null;
  late final MlIntensityModel model;

  setUpAll(() {
    if (file == null) return;
    final bytes = file.readAsBytesSync();
    final watch = Stopwatch()..start();
    model = MlIntensityModel.parse(bytes);
    // Printed for the record: the worker isolate pays this once per session.
    // ignore: avoid_print
    print(
      'ML v1: parsed and compiled in ${watch.elapsedMilliseconds} ms (JIT)',
    );
  });

  test('PGA and PGV are onnxruntime\'s to the bit, on its own features', () {
    final cases = _cases;
    final rows = Float32List(cases.length * mlFeatureCount);
    for (var c = 0; c < cases.length; c++) {
      final features = (cases[c]['features'] as List).cast<num>();
      for (var f = 0; f < mlFeatureCount; f++) {
        rows[c * mlFeatureCount + f] = features[f].toDouble();
      }
    }
    final prediction = model.predict(rows, cases.length);
    for (var c = 0; c < cases.length; c++) {
      final pga = (cases[c]['pga'] as num).toDouble();
      final pgv = (cases[c]['pgv'] as num).toDouble();
      expect(f32Bits(prediction.pga[c]), f32Bits(pga), reason: 'case $c PGA');
      expect(f32Bits(prediction.pgv[c]), f32Bits(pgv), reason: 'case $c PGV');
      expect(
        mlLevel(prediction.pga[c], prediction.pgv[c]),
        cases[c]['level'],
        reason: 'case $c level',
      );
    }
  }, skip: skip);

  test('each row scores alone exactly as in the batch', () {
    // The batch walk skips tests on columns every row shares; a row on its
    // own shares every column. Both must land on the same leaves.
    final cases = _cases.take(40).toList();
    for (var c = 0; c < cases.length; c++) {
      final row = Float32List.fromList(
        (cases[c]['features'] as List)
            .cast<num>()
            .map((v) => v.toDouble())
            .toList(),
      );
      final prediction = model.predict(row, 1);
      expect(
        f32Bits(prediction.pga[0]),
        f32Bits((cases[c]['pga'] as num).toDouble()),
        reason: 'case $c',
      );
    }
  }, skip: skip);

  test('features worked out here are within an ulp, levels equal', () {
    final cases = _cases;
    final row = Float32List(mlFeatureCount);
    for (var c = 0; c < cases.length; c++) {
      final k = cases[c];
      mlFeatures(
        row,
        0,
        magnitude: (k['mag'] as num).toDouble(),
        depth: (k['depth'] as num).toDouble(),
        evLat: (k['ev_lat'] as num).toDouble(),
        evLon: (k['ev_lon'] as num).toDouble(),
        targetLat: (k['t_lat'] as num).toDouble(),
        targetLon: (k['t_lon'] as num).toDouble(),
      );
      final want = (k['features'] as List).cast<num>();
      for (var f = 0; f < mlFeatureCount; f++) {
        final diff = (f32Bits(row[f]) - f32Bits(want[f].toDouble())).abs();
        expect(diff, lessThanOrEqualTo(1), reason: 'case $c feature $f');
      }
      final prediction = model.predict(row, 1);
      expect(
        mlLevel(prediction.pga[0], prediction.pgv[0]),
        k['level'],
        reason: 'case $c level',
      );
    }
  }, skip: skip);

  test('whole-island level maps match, at the reference points', () {
    final points = jsonDecode(
      File('assets/eew_points.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final codes = points.keys.toList();
    final predictor = MlPointPredictor(
      model,
      Float64List.fromList([
        for (final c in codes) ((points[c] as List)[0] as num).toDouble(),
      ]),
      Float64List.fromList([
        for (final c in codes) ((points[c] as List)[1] as num).toDouble(),
      ]),
    );
    for (final field
        in (_golden['fields'] as List).cast<Map<String, dynamic>>()) {
      final levels = predictor.levels(
        magnitude: (field['mag'] as num).toDouble(),
        depth: (field['depth'] as num).toDouble(),
        latitude: (field['lat'] as num).toDouble(),
        longitude: (field['lon'] as num).toDouble(),
      );
      final want = (field['levels'] as Map).cast<String, int>();
      for (var i = 0; i < codes.length; i++) {
        expect(
          levels[i],
          want[codes[i]],
          reason: 'M${field['mag']} town ${codes[i]}',
        );
      }
    }
  }, skip: skip);

  test('the whole island scores in well under a frame budget per quake', () {
    final points = jsonDecode(
      File('assets/eew_points.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final predictor = MlPointPredictor(
      model,
      Float64List.fromList([
        for (final p in points.values) ((p as List)[0] as num).toDouble(),
      ]),
      Float64List.fromList([
        for (final p in points.values) ((p as List)[1] as num).toDouble(),
      ]),
    );
    for (var warm = 0; warm < 3; warm++) {
      predictor.levels(
        magnitude: 6.5,
        depth: 20,
        latitude: 23.8,
        longitude: 121.6,
      );
    }
    final watch = Stopwatch()..start();
    const runs = 10;
    for (var r = 0; r < runs; r++) {
      predictor.levels(
        magnitude: 5 + r * 0.2,
        depth: 10.0 + r,
        latitude: 23.5 + r * 0.05,
        longitude: 121.2,
      );
    }
    final perQuake = watch.elapsedMicroseconds / runs / 1000;
    // Printed for the record; the bound is loose because a debug-mode test VM
    // is several times slower than the release build a phone runs.
    // ignore: avoid_print
    print('ML v1: ${perQuake.toStringAsFixed(1)} ms per 368-town quake (JIT)');
    expect(perQuake, lessThan(500));
  }, skip: skip);
}
