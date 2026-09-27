/// ML v1 — the intensity model ExpTech's EEW pipeline uses — evaluated in Dart
/// to the bit of onnxruntime, so a township's level on this monitor is the
/// level TREM-Lite and the server give it for the same quake.
///
/// The model (`intensity_ml_v1.onnx`) is a physics formula plus four
/// gradient-boosted tree ensembles: a 10-value feature row per target gives
/// PGA (gal) and PGV (cm/s), and the target's level is the higher of the two
/// on CWA's bounds. Everything runs in f32 the way single-threaded
/// onnxruntime runs it (see `ml_f32.dart`); trees are summed in tree order
/// with the base value last.
///
/// **Speed.** A quake is scored at every township at once — 368 rows through
/// 2,800 trees and 421,052 nodes. Rather than walking each row down each tree,
/// each tree partitions the whole batch at every split, and a split on a column
/// every row shares — magnitude, depth and the epicentre, a third of all
/// splits — sends the batch one way without testing a single row. Summation
/// order per row is unchanged, so the result is bit-identical.
///
/// Loading is strict: an op, attribute or tree shape this does not implement
/// is rejected, never approximated. Pure Dart, so it runs in a worker isolate.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/ml/ml_f32.dart';
import 'package:dpip/features/earthquake/domain/ml/ml_onnx.dart';

/// Features per row: M, depth, dist, lnR, evLat, evLon, tLat, tLon, sinAz,
/// cosAz.
const int mlFeatureCount = 10;

/// The Earth radius the training features used — not the app's 6371.008: the
/// trees split on distance, so the radius is part of the model.
const double _earthKm = 6371.0;
const double _d2r = math.pi / 180;

/// CWA's bounds; a level is reached *at* its bound.
const List<double> _pgaBounds = [0.8, 2.5, 8, 25, 80, 140, 250, 440, 800];
const List<double> _pgvBounds = [0.2, 0.7, 1.9, 5.7, 15, 30, 50, 80, 140];

/// Writes the feature row for an epicentre and a target point into [rows] at
/// [at]: worked out in f64, then rounded to f32 by the list.
void mlFeatures(
  Float32List rows,
  int at, {
  required double magnitude,
  required double depth,
  required double evLat,
  required double evLon,
  required double targetLat,
  required double targetLon,
}) {
  final p1 = evLat * _d2r;
  final p2 = targetLat * _d2r;
  final dl = (targetLon - evLon) * _d2r;
  final s1 = math.sin((p2 - p1) / 2);
  final s2 = math.sin(dl / 2);
  final a = s1 * s1 + math.cos(p1) * math.cos(p2) * (s2 * s2);
  final dist = 2 * _earthKm * math.asin(math.sqrt(a));
  final lnR = math.log(math.max(math.sqrt(dist * dist + depth * depth), 3));
  final az = math.atan2(
    math.sin(dl) * math.cos(p2),
    math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl),
  );
  rows[at] = magnitude;
  rows[at + 1] = depth;
  rows[at + 2] = dist;
  rows[at + 3] = lnR;
  rows[at + 4] = evLat;
  rows[at + 5] = evLon;
  rows[at + 6] = targetLat;
  rows[at + 7] = targetLon;
  rows[at + 8] = math.sin(az);
  rows[at + 9] = math.cos(az);
}

/// The CWA level (0–9, the same indices as `Intensity.toScale`) for a
/// predicted PGA and PGV: the higher of the two classifications.
int mlLevel(double pga, double pgv) {
  var a = 0;
  for (final bound in _pgaBounds) {
    if (pga >= bound) a++;
  }
  var v = 0;
  for (final bound in _pgvBounds) {
    if (pgv >= bound) v++;
  }
  return math.max(a, v);
}

/// PGA (gal) and PGV (cm/s) per row.
typedef MlPrediction = ({Float32List pga, Float32List pgv});

/// A compiled model.
class MlIntensityModel {
  MlIntensityModel._(this._steps, this._columns, this._pga, this._pgv);

  /// Compiles the ONNX file's bytes. Throws [FormatException] on anything this
  /// does not implement exactly.
  factory MlIntensityModel.parse(Uint8List onnx) => _compile(readOnnx(onnx));

  final List<_Step> _steps;
  final int _columns;
  final int _pga;
  final int _pgv;

  /// PGA and PGV for [n] rows of [mlFeatureCount] features each.
  MlPrediction predict(Float32List rows, int n) {
    final columns = List<Float32List?>.filled(_columns, null);
    // The trees read every feature many times: widened once, not per test.
    final wide = Float64List(n * mlFeatureCount);
    for (var j = 0; j < wide.length; j++) {
      wide[j] = rows[j];
    }
    final walk = _Walk(wide, n);
    double read(_Arg arg, int i) => arg.constant ?? columns[arg.column]![i];
    for (final step in _steps) {
      final out = Float32List(n);
      final op = step.op;
      switch (op) {
        case _Gather(:final feature):
          for (var i = 0; i < n; i++) {
            out[i] = rows[i * mlFeatureCount + feature];
          }
        case _Binary(:final a, :final b, :final multiply):
          for (var i = 0; i < n; i++) {
            out[i] = multiply
                ? read(a, i) * read(b, i)
                : read(a, i) + read(b, i);
          }
        case _Unary(:final a, :final exp):
          for (var i = 0; i < n; i++) {
            out[i] = exp ? mlasExp(read(a, i)) : read(a, i);
          }
        case _Trees(:final forest):
          walk.run(forest, out);
      }
      columns[step.out] = out;
    }
    return (pga: columns[_pga]!, pgv: columns[_pgv]!);
  }
}

/// Scores a quake at a fixed list of points (the townships) — the rows'
/// target halves and every buffer set up once, reused for each quake.
class MlPointPredictor {
  MlPointPredictor(this.model, this.latitudes, this.longitudes)
    : assert(latitudes.length == longitudes.length),
      _rows = Float32List(latitudes.length * mlFeatureCount);

  final MlIntensityModel model;
  final Float64List latitudes;
  final Float64List longitudes;
  final Float32List _rows;

  int get length => latitudes.length;

  /// Each point's level, in point order.
  Uint8List levels({
    required double magnitude,
    required double depth,
    required double latitude,
    required double longitude,
  }) {
    for (final value in [magnitude, depth, latitude, longitude]) {
      if (!value.isFinite) throw ArgumentError('non-finite quake parameter');
    }
    final n = length;
    for (var i = 0; i < n; i++) {
      mlFeatures(
        _rows,
        i * mlFeatureCount,
        magnitude: magnitude,
        depth: depth,
        evLat: latitude,
        evLon: longitude,
        targetLat: latitudes[i],
        targetLon: longitudes[i],
      );
    }
    final prediction = model.predict(_rows, n);
    return Uint8List.fromList([
      for (var i = 0; i < n; i++) mlLevel(prediction.pga[i], prediction.pgv[i]),
    ]);
  }
}

// ─── Compiled graph ──────────────────────────────────────────────────────────

/// Where an op reads a value: a broadcast constant, or a column of the batch.
class _Arg {
  const _Arg.constant(double this.constant) : column = -1;
  const _Arg.column(this.column) : constant = null;

  final double? constant;
  final int column;
}

sealed class _Op {
  const _Op();
}

class _Gather extends _Op {
  const _Gather(this.feature);
  final int feature;
}

class _Binary extends _Op {
  const _Binary(this.a, this.b, {required this.multiply});
  final _Arg a;
  final _Arg b;
  final bool multiply;
}

class _Unary extends _Op {
  const _Unary(this.a, {required this.exp});
  final _Arg a;
  final bool exp;
}

class _Trees extends _Op {
  const _Trees(this.forest);
  final _Forest forest;
}

class _Step {
  const _Step(this.op, this.out);
  final _Op op;
  final int out;
}

MlIntensityModel _compile(OnnxGraph graph) {
  if (graph.inputs.length != 1) {
    throw FormatException(
      'onnx: want 1 graph input, have ${graph.inputs.length}',
    );
  }
  final input = graph.inputs.single;
  final columns = <String, int>{};
  final steps = <_Step>[];
  _Arg arg(String name) {
    final column = columns[name];
    if (column != null) return _Arg.column(column);
    final constant = graph.floats[name];
    if (constant == null) {
      throw FormatException('onnx: "$name" is read before it is produced');
    }
    if (constant.length != 1) {
      throw FormatException(
        'onnx: constant "$name" has ${constant.length} elements, want 1',
      );
    }
    return _Arg.constant(constant.single);
  }

  for (final node in graph.nodes) {
    if (node.outputs.length != 1) {
      throw FormatException(
        'onnx: ${node.opType} has ${node.outputs.length} outputs, want 1',
      );
    }
    String inputAt(int i) {
      if (i >= node.inputs.length) {
        throw FormatException('onnx: ${node.opType} is missing input $i');
      }
      return node.inputs[i];
    }

    final _Op op;
    switch ('${node.domain}/${node.opType}') {
      case '/Gather':
        final axis = node.attributes['axis']?.i ?? 0;
        if (inputAt(0) != input || axis != 1) {
          throw FormatException(
            'onnx: only Gather($input, axis=1) is supported',
          );
        }
        final index = graph.ints[inputAt(1)];
        if (index == null ||
            index.length != 1 ||
            index.single < 0 ||
            index.single >= mlFeatureCount) {
          throw FormatException('onnx: Gather index $index out of range');
        }
        op = _Gather(index.single);
      case '/Add':
        op = _Binary(arg(inputAt(0)), arg(inputAt(1)), multiply: false);
      case '/Mul':
        op = _Binary(arg(inputAt(0)), arg(inputAt(1)), multiply: true);
      case '/Exp':
        op = _Unary(arg(inputAt(0)), exp: true);
      case '/Identity':
        op = _Unary(arg(inputAt(0)), exp: false);
      case 'ai.onnx.ml/TreeEnsembleRegressor':
        if (inputAt(0) != input) {
          throw FormatException(
            'onnx: trees must read the graph input "$input"',
          );
        }
        op = _Trees(_Forest.compile(node.attributes));
      case final kind:
        throw FormatException('onnx: unsupported op $kind');
    }
    final column = columns.length;
    columns[node.outputs.single] = column;
    steps.add(_Step(op, column));
  }
  final pga = columns['PGA'];
  final pgv = columns['PGV'];
  if (pga == null || pgv == null) {
    throw const FormatException('onnx: graph must compute PGA and PGV');
  }
  return MlIntensityModel._(steps, columns.length, pga, pgv);
}

// ─── Tree ensembles ──────────────────────────────────────────────────────────

/// Marks a leaf in [_Forest.feature].
const int _leaf = 255;

/// A compiled `ai.onnx.ml` TreeEnsembleRegressor (one target, SUM, no post
/// transform). A branch's two children sit side by side, true child first, and
/// every test is "true when x ≤ threshold" — a `BRANCH_LT` threshold is moved
/// to the f32 just below it, which is the same test for every finite f32 x.
class _Forest {
  _Forest(
    this.feature,
    this.threshold,
    this.child,
    this.value,
    this.roots,
    this.base,
  );

  final Uint8List feature;
  final Float64List threshold;
  final Int32List child;
  final Float32List value;
  final Int32List roots;
  final double base;

  static _Forest compile(Map<String, OnnxAttribute> attributes) {
    final empty = OnnxAttribute(
      i: 0,
      s: '',
      floats: Float32List(0),
      ints: Int32List(0),
      strings: const [],
    );
    OnnxAttribute get(String name) => attributes[name] ?? empty;
    if (get('n_targets').i != 1) {
      throw FormatException('onnx: trees: n_targets ${get('n_targets').i}');
    }
    for (final (name, ok) in const [
      ('post_transform', 'NONE'),
      ('aggregate_function', 'SUM'),
    ]) {
      final value = get(name).s;
      if (value.isNotEmpty && value != ok) {
        throw FormatException('onnx: trees: $name $value not supported');
      }
    }
    final trees = get('nodes_treeids').ints;
    final nodes = get('nodes_nodeids').ints;
    final features = get('nodes_featureids').ints;
    final modes = get('nodes_modes').strings;
    final thresholds = get('nodes_values').floats;
    final yes = get('nodes_truenodeids').ints;
    final no = get('nodes_falsenodeids').ints;
    final n = trees.length;
    if (n == 0 ||
        [
          nodes.length,
          features.length,
          modes.length,
          thresholds.length,
          yes.length,
          no.length,
        ].any((length) => length != n)) {
      throw const FormatException(
        'onnx: trees: node attribute lengths disagree',
      );
    }

    // Each tree's nodes are one run, in ascending tree id, numbered from 0 —
    // how the converters write them, and required here: a node's position is
    // then its tree's start plus its id, with no half-million-entry map.
    final starts = <int, int>{};
    final lengths = <int, int>{};
    final order = <int>[];
    for (var i = 0; i < n; i++) {
      final tree = trees[i];
      if (i == 0 || tree != trees[i - 1]) {
        if (starts.containsKey(tree) ||
            (order.isNotEmpty && tree < order.last)) {
          throw FormatException(
            'onnx: trees: tree $tree is not one ascending run',
          );
        }
        starts[tree] = i;
        order.add(tree);
      }
      if (nodes[i] != i - starts[tree]!) {
        throw FormatException(
          'onnx: trees: tree $tree is not numbered in order',
        );
      }
      lengths[tree] = nodes[i] + 1;
    }
    int at(int tree, int node) {
      final start = starts[tree];
      if (start == null || node < 0 || node >= lengths[tree]!) {
        throw FormatException('onnx: trees: no node $tree/$node');
      }
      return start + node;
    }

    final targetTrees = get('target_treeids').ints;
    final targetNodes = get('target_nodeids').ints;
    final targetIds = get('target_ids').ints;
    final weights = get('target_weights').floats;
    if (targetNodes.length != targetTrees.length ||
        targetIds.length != targetTrees.length ||
        weights.length != targetTrees.length) {
      throw const FormatException(
        'onnx: trees: target attribute lengths disagree',
      );
    }
    final weight = Float32List(n);
    final weighted = Uint8List(n);
    for (var i = 0; i < targetTrees.length; i++) {
      if (targetIds[i] != 0) {
        throw FormatException('onnx: trees: target id ${targetIds[i]}, want 0');
      }
      final k = at(targetTrees[i], targetNodes[i]);
      if (weighted[k] == 1) {
        throw const FormatException(
          'onnx: trees: a leaf has more than one weight',
        );
      }
      weighted[k] = 1;
      weight[k] = weights[i];
    }

    final feature = Uint8List(n);
    final threshold = Float64List(n);
    final child = Int32List(n);
    final value = Float32List(n);
    final roots = Int32List(order.length);
    var slots = 0;
    // (onnx node, slot, depth), an explicit stack rather than recursion.
    final stack = <(int, int, int)>[];
    for (var t = 0; t < order.length; t++) {
      final root = slots++;
      roots[t] = root;
      stack.add((starts[order[t]]!, root, 0));
      while (stack.isNotEmpty) {
        final (i, slot, depth) = stack.removeLast();
        if (depth > 254) {
          throw FormatException('onnx: trees: tree ${order[t]} too deep');
        }
        switch (modes[i]) {
          case 'LEAF':
            feature[slot] = _leaf;
            value[slot] = weight[i];
            continue;
          case 'BRANCH_LEQ':
            threshold[slot] = thresholds[i];
          case 'BRANCH_LT':
            threshold[slot] = f32NextDown(thresholds[i]);
          case final mode:
            throw FormatException('onnx: trees: node mode $mode not supported');
        }
        if (features[i] < 0 || features[i] >= mlFeatureCount) {
          throw FormatException(
            'onnx: trees: feature ${features[i]} out of range',
          );
        }
        final c = slots;
        slots += 2;
        if (slots > n) {
          throw const FormatException('onnx: trees: malformed tree');
        }
        feature[slot] = features[i];
        child[slot] = c;
        stack
          ..add((at(order[t], no[i]), c + 1, depth + 1))
          ..add((at(order[t], yes[i]), c, depth + 1));
      }
    }
    if (slots != n) {
      throw const FormatException('onnx: trees: unreachable nodes');
    }
    final base = get('base_values').floats;
    return _Forest(
      feature,
      threshold,
      child,
      value,
      roots,
      base.isEmpty ? 0 : base.first,
    );
  }
}

/// One batch's walk through the forests: the rows, a permutation of their
/// indices each split partitions in place, and which columns every row shares.
class _Walk {
  _Walk(this.rows, this.n)
    : _index = Int32List(n),
      _stack = Int32List(3 * 256) {
    for (var i = 0; i < n; i++) {
      _index[i] = i;
    }
    for (var f = 0; f < mlFeatureCount; f++) {
      final first = n == 0 ? 0.0 : rows[f];
      var same = true;
      for (var i = 1; i < n && same; i++) {
        same = rows[i * mlFeatureCount + f] == first;
      }
      _shared[f] = same ? 1 : 0;
      _sharedValue[f] = first;
    }
  }

  final Float64List rows;
  final int n;
  final Int32List _index;
  final Int32List _stack;
  final Uint8List _shared = Uint8List(mlFeatureCount);
  final Float64List _sharedValue = Float64List(mlFeatureCount);

  /// Adds [forest]'s output to each row of [out] — tree by tree, so every row
  /// still sums in tree order — then the base value.
  void run(_Forest forest, Float32List out) {
    final feature = forest.feature;
    final threshold = forest.threshold;
    final child = forest.child;
    final value = forest.value;
    final rows = this.rows;
    final index = _index;
    final stack = _stack;
    final shared = _shared;
    final sharedValue = _sharedValue;
    if (n > 0) {
      for (final root in forest.roots) {
        var sp = 0;
        stack[0] = root;
        stack[1] = 0;
        stack[2] = n;
        sp = 3;
        while (sp > 0) {
          sp -= 3;
          var node = stack[sp];
          var start = stack[sp + 1];
          var end = stack[sp + 2];
          while (true) {
            final f = feature[node];
            if (f == _leaf) {
              final v = value[node];
              for (var k = start; k < end; k++) {
                final r = index[k];
                out[r] = out[r] + v;
              }
              break;
            }
            final t = threshold[node];
            final c = child[node];
            if (shared[f] == 1) {
              node = sharedValue[f] <= t ? c : c + 1;
              continue;
            }
            // Rows at or under the threshold to the front: [start, m).
            var i = start;
            var j = end - 1;
            while (i <= j) {
              final r = index[i];
              if (rows[r * mlFeatureCount + f] <= t) {
                i++;
              } else {
                index[i] = index[j];
                index[j] = r;
                j--;
              }
            }
            if (i == start) {
              node = c + 1;
            } else if (i == end) {
              node = c;
            } else {
              stack[sp] = c + 1;
              stack[sp + 1] = i;
              stack[sp + 2] = end;
              sp += 3;
              node = c;
              end = i;
            }
          }
        }
      }
    }
    final base = forest.base;
    for (var i = 0; i < n; i++) {
      out[i] = out[i] + base;
    }
  }
}
