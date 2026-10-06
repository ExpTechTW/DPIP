/// A hand-built ONNX file for the model runtime's tests — the real model is
/// 14.7 MB and downloaded, not committed.
///
/// Two trees on the input, summed with a base of 0.25:
///  - tree 0: `dist < 10` → 1, else 2 (BRANCH_LT on feature 2);
///  - tree 1: `M <= 5` → (`dist <= 50` → 0.125, else 0.0625), else 4.
///
/// PGA = forest + 0.1 (f32); PGV = exp(M).
library;

import 'dart:convert';
import 'dart:typed_data';

List<int> _varint(int v) {
  final out = <int>[];
  var x = v;
  while (true) {
    final byte = x & 0x7f;
    x = x >>> 7;
    if (x == 0) {
      out.add(byte);
      return out;
    }
    out.add(byte | 0x80);
  }
}

List<int> _key(int field, int wire) => _varint(field << 3 | wire);

List<int> _bytes(int field, List<int> payload) => [
  ..._key(field, 2),
  ..._varint(payload.length),
  ...payload,
];

List<int> onnxString(int field, String s) => _bytes(field, utf8.encode(s));

List<int> _int(int field, int v) => [..._key(field, 0), ..._varint(v)];

List<int> _float(int field, double v) {
  final data = ByteData(4)..setFloat32(0, v, Endian.little);
  return [..._key(field, 5), ...data.buffer.asUint8List()];
}

List<int> _attr(
  String name, {
  int? i,
  String? s,
  List<double> floats = const [],
  List<int> ints = const [],
  List<String> strings = const [],
}) => _bytes(5, [
  ...onnxString(1, name),
  if (i != null) ..._int(3, i),
  if (s != null) ...onnxString(4, s),
  for (final f in floats) ..._float(7, f),
  for (final v in ints) ..._int(8, v),
  for (final v in strings) ...onnxString(9, v),
]);

List<int> onnxNode(
  String op,
  List<String> inputs,
  String output, {
  String? secondOutput,
  String domain = '',
  List<List<int>> attrs = const [],
}) => _bytes(1, [
  for (final input in inputs) ...onnxString(1, input),
  ...onnxString(2, output),
  if (secondOutput != null) ...onnxString(2, secondOutput),
  ...onnxString(4, op),
  if (domain.isNotEmpty) ...onnxString(7, domain),
  for (final a in attrs) ...a,
]);

List<int> _floatConst(String name, double v) =>
    _bytes(5, [..._int(2, 1), ..._float(4, v), ...onnxString(8, name)]);

List<int> _intConst(String name, int v) {
  final raw = ByteData(8)..setInt64(0, v, Endian.little);
  return _bytes(5, [
    ..._int(2, 7),
    ...onnxString(8, name),
    ..._bytes(9, raw.buffer.asUint8List()),
  ]);
}

List<int> _trees({String firstMode = 'BRANCH_LT'}) => onnxNode(
  'TreeEnsembleRegressor',
  ['features'],
  'forest',
  domain: 'ai.onnx.ml',
  attrs: [
    _attr('n_targets', i: 1),
    _attr('nodes_treeids', ints: [0, 0, 0, 1, 1, 1, 1, 1]),
    _attr('nodes_nodeids', ints: [0, 1, 2, 0, 1, 2, 3, 4]),
    _attr('nodes_featureids', ints: [2, 0, 0, 0, 2, 0, 0, 0]),
    _attr('nodes_values', floats: [10, 0, 0, 5, 50, 0, 0, 0]),
    _attr(
      'nodes_modes',
      strings: [
        firstMode,
        'LEAF',
        'LEAF',
        'BRANCH_LEQ',
        'BRANCH_LEQ',
        'LEAF',
        'LEAF',
        'LEAF',
      ],
    ),
    _attr('nodes_truenodeids', ints: [1, 0, 0, 1, 3, 0, 0, 0]),
    _attr('nodes_falsenodeids', ints: [2, 0, 0, 2, 4, 0, 0, 0]),
    _attr('target_treeids', ints: [0, 0, 1, 1, 1]),
    _attr('target_nodeids', ints: [1, 2, 2, 3, 4]),
    _attr('target_ids', ints: [0, 0, 0, 0, 0]),
    _attr('target_weights', floats: [1, 2, 4, 0.125, 0.0625]),
    _attr('base_values', floats: [0.25]),
  ],
);

/// The model described above, with [extra] nodes appended to its graph.
Uint8List testModel({List<List<int>>? extra, String firstMode = 'BRANCH_LT'}) =>
    onnxModel([
      _trees(firstMode: firstMode),
      onnxNode('Add', ['forest', 'c'], 'PGA'),
      onnxNode(
        'Gather',
        ['features', 'idx'],
        'M',
        attrs: [_attr('axis', i: 1)],
      ),
      onnxNode('Exp', ['M'], 'PGV'),
      ...?extra,
      _floatConst('c', 0.1),
      _intConst('idx', 0),
      _bytes(11, onnxString(1, 'features')),
    ]);

/// An ONNX ModelProto whose only field is a graph made of [parts].
Uint8List onnxModel(List<List<int>> parts) =>
    Uint8List.fromList(_bytes(7, parts.expand((part) => part).toList()));

List<int> onnxAttr(
  String name, {
  int? i,
  String? s,
  List<double> floats = const [],
  List<int> ints = const [],
  List<String> strings = const [],
}) => _attr(name, i: i, s: s, floats: floats, ints: ints, strings: strings);

List<int> onnxFloatConst(String name, double value) => _floatConst(name, value);

List<int> onnxIntConst(String name, int value) => _intConst(name, value);

List<int> onnxInput(String name) => _bytes(11, onnxString(1, name));

Uint8List _f32(List<double> values) {
  final data = ByteData(values.length * 4);
  for (var i = 0; i < values.length; i++) {
    data.setFloat32(i * 4, values[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Attribute floats as one packed length-delimited field, not repeated fixed32.
List<int> onnxPackedFloatAttr(String name, List<double> values) =>
    _bytes(5, [...onnxString(1, name), ..._bytes(7, _f32(values))]);

/// Attribute ints as one packed varint field.
List<int> onnxPackedIntAttr(String name, List<int> values) => _bytes(5, [
  ...onnxString(1, name),
  ..._bytes(8, values.expand(_varint).toList()),
]);

/// FLOAT initializer stored only in raw_data.
List<int> onnxRawFloatTensor(String name, List<double> values) => _bytes(5, [
  ..._int(2, 1),
  ...onnxString(8, name),
  ..._bytes(9, _f32(values)),
]);

/// INT64 initializer stored as packed varints.
List<int> onnxPackedIntTensor(String name, List<int> values) => _bytes(5, [
  ..._int(2, 7),
  ...onnxString(8, name),
  ..._bytes(7, values.expand(_varint).toList()),
]);

List<int> onnxTypedTensor(String name, int dataType) =>
    _bytes(5, [..._int(2, dataType), ...onnxString(8, name)]);

/// A field with an unsupported protobuf wire type, so the reader must stop.
List<int> onnxBadWire() => _key(99, 3);

/// A fixed64 field. The reader skips it; the model never stores one.
List<int> onnxFixed64() => [..._key(99, 1), 0, 0, 0, 0, 0, 0, 0, 0];
