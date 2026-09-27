/// The model runtime's semantics on a hand-built ONNX file, so they are held
/// in CI without the real 14.7 MB model (the golden test holds that one).
///
/// What is pinned is what a port gets subtly wrong:
/// - `BRANCH_LT` and `BRANCH_LEQ` differ exactly at the threshold;
/// - a tree ensemble adds its base value after the trees, in f32;
/// - a batch that shares a column (every township shares the quake) lands on
///   the same leaves as rows scored one at a time;
/// - a graph this runtime does not implement exactly is refused, not guessed.
library;

import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/ml/ml_f32.dart';
import 'package:dpip/features/earthquake/domain/ml/ml_intensity_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onnx_fixture.dart';

Float32List _rows(List<(double m, double dist)> rows) {
  final out = Float32List(rows.length * mlFeatureCount);
  for (var r = 0; r < rows.length; r++) {
    out[r * mlFeatureCount] = rows[r].$1;
    out[r * mlFeatureCount + 2] = rows[r].$2;
  }
  return out;
}

void main() {
  test('BRANCH_LT and BRANCH_LEQ split differently at the threshold', () {
    final model = MlIntensityModel.parse(testModel());
    // dist exactly 10: `< 10` is false → 2; M exactly 5: `<= 5` is true, and
    // dist 10 <= 50 → 0.125. Sum 2.125, base last → 2.375, + 0.1 in f32.
    final prediction = model.predict(_rows([(5, 10)]), 1);

    expect(prediction.pga[0], fround(fround(2.125 + 0.25) + fround(0.1)));
  });

  test('a batch sharing a column lands where each row does alone', () {
    final model = MlIntensityModel.parse(testModel());
    final rows = [(5.0, 3.0), (5.0, 10.0), (5.0, 60.0), (5.0, 9.99)];
    final batch = model.predict(_rows(rows), rows.length);

    for (var r = 0; r < rows.length; r++) {
      final alone = model.predict(_rows([rows[r]]), 1);
      expect(batch.pga[r], alone.pga[0], reason: 'row $r');
    }
    expect(batch.pga[0], isNot(batch.pga[2]), reason: 'the rows do differ');
  });

  test('rows that differ in a shared-looking column still split', () {
    final model = MlIntensityModel.parse(testModel());
    final batch = model.predict(_rows([(4, 3), (6, 3)]), 2);

    // M 4 → 1 + 0.125; M 6 → 1 + 4.
    expect(batch.pga[0], fround(fround(1.125 + 0.25) + fround(0.1)));
    expect(batch.pga[1], fround(fround(5 + 0.25) + fround(0.1)));
  });

  test('Gather and Exp read the feature column through MLAS exp', () {
    final model = MlIntensityModel.parse(testModel());
    final prediction = model.predict(_rows([(2, 0)]), 1);

    expect(prediction.pgv[0], mlasExp(2));
  });

  test('levels are reached at the bound, the higher of PGA and PGV', () {
    expect(mlLevel(0.79, 0), 0);
    expect(mlLevel(0.8, 0), 1);
    expect(mlLevel(80, 0), 5);
    expect(mlLevel(80, 30), 6, reason: 'PGV reaches 5強 first');
    expect(mlLevel(1000, 200), 9);
  });

  test('a mode, op or tree shape it does not implement is refused', () {
    expect(
      () => MlIntensityModel.parse(testModel(firstMode: 'BRANCH_GT')),
      throwsFormatException,
    );
    expect(
      () => MlIntensityModel.parse(
        testModel(
          extra: [
            onnxNode('Sigmoid', ['PGA'], 'S'),
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(
      () =>
          MlIntensityModel.parse(Uint8List.fromList(onnxString(1, 'no graph'))),
      throwsFormatException,
    );
  });
}
