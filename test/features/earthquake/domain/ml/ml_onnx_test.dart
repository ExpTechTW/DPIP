/// The ONNX reader has to reject a file it cannot evaluate exactly.
///
/// A packed float, a raw initializer, or an int that does not fit 32 bits is
/// how a retrained model would arrive. Guessing past any of those would score
/// townships at the wrong level with nothing visible on the card.
library;

import 'package:dpip/features/earthquake/domain/ml/ml_intensity_model.dart';
import 'package:dpip/features/earthquake/domain/ml/ml_onnx.dart';
import 'package:flutter_test/flutter_test.dart';

import 'onnx_fixture.dart';

void main() {
  test('packed attribute values and raw initializers round-trip', () {
    final graph = readOnnx(
      onnxModel([
        onnxFixed64(),
        onnxNode(
          'Identity',
          ['features'],
          'out',
          attrs: [
            onnxPackedFloatAttr('w', [1.5, 2.5]),
            onnxPackedIntAttr('ids', [3, 4]),
          ],
        ),
        onnxRawFloatTensor('bias', [0.25]),
        onnxPackedIntTensor('idx', [1]),
        onnxInput('features'),
      ]),
    );

    expect(graph.nodes.single.attributes['w']!.floats, [1.5, 2.5]);
    expect(graph.nodes.single.attributes['ids']!.ints, [3, 4]);
    expect(graph.floats['bias'], [0.25]);
    expect(graph.ints['idx'], [1]);
    expect(graph.inputs, ['features']);
  });

  test('a wire type, dtype, or int this runtime does not store is refused', () {
    expect(() => readOnnx(onnxModel([onnxBadWire()])), throwsFormatException);
    expect(
      () => readOnnx(onnxModel([onnxTypedTensor('x', 2)])),
      throwsFormatException,
    );
    expect(
      () => readOnnx(
        onnxModel([
          onnxNode(
            'Identity',
            ['features'],
            'out',
            attrs: [
              onnxPackedIntAttr('ids', [1 << 40]),
            ],
          ),
        ]),
      ),
      throwsFormatException,
    );
  });

  test('a graph this compiler does not implement is refused', () {
    final refused = <List<List<int>>>[
      [onnxInput('a'), onnxInput('b')],
      [
        onnxNode('Add', ['missing', 'c'], 'PGA'),
        onnxFloatConst('c', 0.1),
        onnxInput('features'),
      ],
      [
        onnxNode('Add', ['wide', 'c'], 'PGA'),
        onnxRawFloatTensor('wide', [1, 2]),
        onnxFloatConst('c', 0.1),
        onnxInput('features'),
      ],
      [
        onnxNode('Identity', ['features'], 'PGA', secondOutput: 'extra'),
        onnxInput('features'),
      ],
      [
        onnxNode('Add', ['c'], 'PGA'),
        onnxFloatConst('c', 0.1),
        onnxInput('features'),
      ],
      [
        onnxNode(
          'Gather',
          ['features', 'idx'],
          'M',
          attrs: [onnxAttr('axis', i: 0)],
        ),
        onnxIntConst('idx', 0),
        onnxInput('features'),
      ],
      [
        onnxNode(
          'Gather',
          ['features', 'idx'],
          'M',
          attrs: [onnxAttr('axis', i: 1)],
        ),
        onnxIntConst('idx', 99),
        onnxInput('features'),
      ],
      [
        onnxNode(
          'TreeEnsembleRegressor',
          ['other'],
          'forest',
          domain: 'ai.onnx.ml',
          attrs: _leafAttrs(),
        ),
        onnxInput('features'),
      ],
      [
        onnxNode('Exp', ['M'], 'only'),
        onnxInput('features'),
      ],
    ];

    for (final parts in refused) {
      expect(
        () => MlIntensityModel.parse(onnxModel(parts)),
        throwsFormatException,
      );
    }
  });

  test('a tree ensemble with the wrong shape is refused', () {
    expect(() => _parseForest(nTargets: 2), throwsFormatException);
    expect(() => _parseForest(postTransform: 'SOFTMAX'), throwsFormatException);
    expect(() => _parseForest(treeIds: [1, 0]), throwsFormatException);
    expect(() => _parseForest(nodeIds: [0, 2]), throwsFormatException);
    expect(() => _parseForest(trueIds: [9, 0]), throwsFormatException);
    expect(() => _parseForest(targetIds: [1]), throwsFormatException);
    expect(() => _parseForest(featureIds: [99, 0]), throwsFormatException);
  });
}

void _parseForest({
  int nTargets = 1,
  String postTransform = 'NONE',
  List<int>? treeIds,
  List<int>? nodeIds,
  List<int>? trueIds,
  List<int>? featureIds,
  List<int>? targetIds,
}) {
  final trees = treeIds ?? [0, 0];
  final nodes = nodeIds ?? [0, 1];
  MlIntensityModel.parse(
    onnxModel([
      onnxNode(
        'TreeEnsembleRegressor',
        ['features'],
        'PGA',
        domain: 'ai.onnx.ml',
        attrs: _leafAttrs(
          nTargets: nTargets,
          postTransform: postTransform,
          treeIds: trees,
          nodeIds: nodes,
          trueIds: trueIds ?? [1, 0],
          featureIds: featureIds ?? [0, 0],
          targetIds: targetIds ?? [0],
        ),
      ),
      onnxNode('Identity', ['PGA'], 'PGV'),
      onnxInput('features'),
    ]),
  );
}

List<List<int>> _leafAttrs({
  int nTargets = 1,
  String postTransform = 'NONE',
  List<int> treeIds = const [0, 0],
  List<int> nodeIds = const [0, 1],
  List<int> trueIds = const [1, 0],
  List<int> featureIds = const [0, 0],
  List<int> targetIds = const [0],
}) {
  final n = treeIds.length;
  return [
    onnxAttr('n_targets', i: nTargets),
    onnxAttr('post_transform', s: postTransform),
    onnxAttr('aggregate_function', s: 'SUM'),
    onnxAttr('nodes_treeids', ints: treeIds),
    onnxAttr('nodes_nodeids', ints: nodeIds),
    onnxAttr('nodes_featureids', ints: featureIds),
    onnxAttr('nodes_values', floats: List<double>.filled(n, 0)),
    onnxAttr(
      'nodes_modes',
      strings: [for (var i = 0; i < n; i++) i == 0 ? 'BRANCH_LEQ' : 'LEAF'],
    ),
    onnxAttr('nodes_truenodeids', ints: trueIds),
    onnxAttr('nodes_falsenodeids', ints: List<int>.filled(n, 1)),
    onnxAttr('target_treeids', ints: [0]),
    onnxAttr('target_nodeids', ints: [1]),
    onnxAttr('target_ids', ints: targetIds),
    onnxAttr('target_weights', floats: [1]),
  ];
}
