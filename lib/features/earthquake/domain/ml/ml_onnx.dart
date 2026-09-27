/// Just enough of the ONNX protobuf format to read the intensity model: the
/// graph's nodes with their attributes, its constants, and its input's name.
///
/// Hand-read rather than through a protobuf package because the model is one
/// fixed file, and the reading is the slow part of loading it: its four tree
/// ensembles write every node id, threshold and mode as a field of its own —
/// about four million fields. So each attribute is scanned twice, once to count
/// and once to fill a typed list of exactly that size, and the few distinct
/// strings (the node modes) are interned rather than decoded once per node.
library;

import 'dart:convert';
import 'dart:typed_data';

/// One attribute of a node — whichever of its value kinds was set.
class OnnxAttribute {
  OnnxAttribute({
    required this.i,
    required this.s,
    required this.floats,
    required this.ints,
    required this.strings,
  });

  final int i;
  final String s;
  final Float32List floats;

  /// 32-bit: the model's node ids, tree ids and flags all fit, and a tree
  /// ensemble's seven id lists at 64 bits would double the load's peak memory
  /// on the phones that can least afford it. A value that does not fit is a
  /// [FormatException].
  final Int32List ints;
  final List<String> strings;
}

class OnnxNode {
  OnnxNode({
    required this.opType,
    required this.domain,
    required this.inputs,
    required this.outputs,
    required this.attributes,
  });

  final String opType;
  final String domain;
  final List<String> inputs;
  final List<String> outputs;
  final Map<String, OnnxAttribute> attributes;
}

class OnnxGraph {
  OnnxGraph({
    required this.nodes,
    required this.floats,
    required this.ints,
    required this.inputs,
  });

  final List<OnnxNode> nodes;

  /// f32 initializers by name.
  final Map<String, Float32List> floats;

  /// int64 initializers by name.
  final Map<String, Int64List> ints;

  /// The graph inputs' names.
  final List<String> inputs;
}

/// Reads the graph of an ONNX model. Throws [FormatException] on anything
/// malformed, and on an initializer type the model does not use.
OnnxGraph readOnnx(Uint8List bytes) {
  final model = _Fields(bytes, 0, bytes.length);
  _Fields? graph;
  while (model.next()) {
    if (model.field == 7 && model.wire == 2) graph = model.sub(); // graph
  }
  if (graph == null) throw const FormatException('onnx: model has no graph');
  final nodes = <OnnxNode>[];
  final floats = <String, Float32List>{};
  final ints = <String, Int64List>{};
  final inputs = <String>[];
  final strings = _Strings();
  while (graph.next()) {
    switch (graph.field) {
      case 1:
        nodes.add(_node(graph.sub(), strings));
      case 5:
        _tensor(graph.sub(), floats, ints);
      case 11:
        final info = graph.sub();
        var name = '';
        while (info.next()) {
          if (info.field == 1) name = info.string();
        }
        inputs.add(name);
    }
  }
  return OnnxGraph(nodes: nodes, floats: floats, ints: ints, inputs: inputs);
}

OnnxNode _node(_Fields node, _Strings strings) {
  var opType = '';
  var domain = '';
  final inputs = <String>[];
  final outputs = <String>[];
  final attributes = <String, OnnxAttribute>{};
  while (node.next()) {
    switch (node.field) {
      case 1:
        inputs.add(node.string());
      case 2:
        outputs.add(node.string());
      case 4:
        opType = node.string();
      case 7:
        domain = node.string();
      case 5:
        final (name, attribute) = _attribute(node.sub(), strings);
        attributes[name] = attribute;
    }
  }
  return OnnxNode(
    opType: opType,
    domain: domain,
    inputs: inputs,
    outputs: outputs,
    attributes: attributes,
  );
}

(String, OnnxAttribute) _attribute(_Fields attribute, _Strings strings) {
  // First pass: how many values of each kind, so the lists are sized once.
  final count = attribute.copy();
  var nFloats = 0;
  var nInts = 0;
  var nStrings = 0;
  while (count.next()) {
    switch (count.field) {
      case 7:
        nFloats += count.wire == 5 ? 1 : count.length ~/ 4;
      case 8:
        nInts += count.wire == 0 ? 1 : count.packedVarints();
      case 9:
        nStrings++;
    }
  }
  var name = '';
  var i = 0;
  var s = '';
  final floats = Float32List(nFloats);
  final ints = Int32List(nInts);
  final values = List<String>.filled(nStrings, '');
  var f = 0;
  var n = 0;
  var k = 0;
  while (attribute.next()) {
    switch (attribute.field) {
      case 1:
        name = attribute.string();
      case 3:
        i = attribute.value;
      case 4:
        s = attribute.string();
      case 7:
        if (attribute.wire == 5) {
          floats[f++] = attribute.float32();
        } else {
          f = attribute.packedFloats(floats, f);
        }
      case 8:
        if (attribute.wire == 0) {
          ints[n++] = _int32(attribute.value);
        } else {
          n = attribute.packedInts32(ints, n);
        }
      case 9:
        values[k++] = strings.of(attribute);
    }
  }
  return (
    name,
    OnnxAttribute(i: i, s: s, floats: floats, ints: ints, strings: values),
  );
}

void _tensor(
  _Fields tensor,
  Map<String, Float32List> floats,
  Map<String, Int64List> ints,
) {
  var name = '';
  var type = 0;
  final data = <double>[];
  final intData = <int>[];
  Uint8List raw = Uint8List(0);
  while (tensor.next()) {
    switch (tensor.field) {
      case 2:
        type = tensor.value;
      case 4:
        if (tensor.wire == 5) {
          data.add(tensor.float32());
        } else {
          final values = Float32List(tensor.length ~/ 4);
          tensor.packedFloats(values, 0);
          data.addAll(values);
        }
      case 7:
        if (tensor.wire == 0) {
          intData.add(tensor.value);
        } else {
          final values = Int64List(tensor.packedVarints());
          tensor.packedInts(values, 0);
          intData.addAll(values);
        }
      case 8:
        name = tensor.string();
      case 9:
        raw = tensor.bytes();
    }
  }
  final view = ByteData.sublistView(raw);
  switch (type) {
    case 1: // FLOAT
      floats[name] = Float32List.fromList([
        ...data,
        for (var at = 0; at + 4 <= raw.length; at += 4)
          view.getFloat32(at, Endian.little),
      ]);
    case 7: // INT64
      ints[name] = Int64List.fromList([
        ...intData,
        for (var at = 0; at + 8 <= raw.length; at += 8)
          view.getInt64(at, Endian.little),
      ]);
    default:
      throw FormatException('onnx: initializer "$name" has type $type');
  }
}

int _int32(int value) {
  if (value != value.toSigned(32)) {
    throw FormatException('onnx: attribute value $value exceeds 32 bits');
  }
  return value;
}

/// The distinct strings seen so far, so a repeated one is not decoded again.
class _Strings {
  final List<(Uint8List, String)> _seen = [];

  String of(_Fields field) {
    final bytes = field.buf;
    final start = field.start;
    final length = field.length;
    for (final (key, value) in _seen) {
      if (key.length != length) continue;
      var same = true;
      for (var j = 0; j < length; j++) {
        if (key[j] != bytes[start + j]) {
          same = false;
          break;
        }
      }
      if (same) return value;
    }
    final key = Uint8List.fromList(bytes.sublist(start, start + length));
    final value = utf8.decode(key);
    _seen.add((key, value));
    return value;
  }
}

/// A cursor over one message's fields. [next] reads a field header and its
/// value: a varint or fixed32 into [value], a length-delimited payload as the
/// span [start] … [start] + [length].
class _Fields {
  _Fields(this.buf, this._at, this._end) : _view = ByteData.sublistView(buf);

  final Uint8List buf;
  final ByteData _view;
  int _at;
  final int _end;

  int field = 0;
  int wire = 0;
  int value = 0;
  int start = 0;
  int length = 0;

  _Fields copy() => _Fields(buf, _at, _end);

  _Fields sub() => _Fields(buf, start, start + length);

  bool next() {
    if (_at >= _end) return false;
    final key = _varint();
    field = key >> 3;
    wire = key & 7;
    switch (wire) {
      case 0:
        value = _varint();
      case 1:
        _need(8);
        _at += 8; // fixed64: nothing the model reads
      case 2:
        length = _varint();
        _need(length);
        start = _at;
        _at += length;
      case 5:
        _need(4);
        start = _at;
        value = _view.getUint32(_at, Endian.little);
        _at += 4;
      default:
        throw FormatException('onnx: unsupported wire type $wire');
    }
    return true;
  }

  void _need(int n) {
    if (n < 0 || _at + n > _end) {
      throw const FormatException('onnx: truncated field');
    }
  }

  int _varint() {
    var result = 0;
    for (var shift = 0; shift < 64; shift += 7) {
      if (_at >= _end) throw const FormatException('onnx: truncated varint');
      final byte = buf[_at++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return result;
    }
    throw const FormatException('onnx: varint too long');
  }

  double float32() => _view.getFloat32(start, Endian.little);

  String string() =>
      utf8.decode(Uint8List.sublistView(buf, start, start + length));

  Uint8List bytes() => Uint8List.sublistView(buf, start, start + length);

  /// Values in the current packed varint payload.
  int packedVarints() {
    var n = 0;
    for (var j = start; j < start + length; j++) {
      if (buf[j] & 0x80 == 0) n++;
    }
    return n;
  }

  int packedInts(Int64List into, int at) {
    final inner = sub();
    while (inner._at < inner._end) {
      into[at++] = inner._varint();
    }
    return at;
  }

  int packedInts32(Int32List into, int at) {
    final inner = sub();
    while (inner._at < inner._end) {
      into[at++] = _int32(inner._varint());
    }
    return at;
  }

  int packedFloats(Float32List into, int at) {
    if (length % 4 != 0) {
      throw const FormatException('onnx: malformed float field');
    }
    for (var j = 0; j < length; j += 4) {
      into[at++] = _view.getFloat32(start + j, Endian.little);
    }
    return at;
  }
}
