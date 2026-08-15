/// Records what the mesh looked like over the last day: the radio's own
/// utilization, battery and pack voltage, how many nodes it could see, and each
/// neighbour's battery and signal.
///
/// The radio broadcasts its own telemetry every few minutes and the transport
/// stamps each reading with when it arrived — so this needs no timer of its
/// own. It watches the traffic stream (which fires on every packet, telemetry
/// included) and writes a row whenever the reading's timestamp changes.
/// Sampling on a clock instead would either miss readings or duplicate them,
/// and would keep working — writing the same value forever — after the link
/// died.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';

class MeshMetricsRecorder {
  MeshMetricsRecorder(
    this._service,
    this._nodes,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? (() => AppTime.utc.toLocal());

  final MeshtasticService _service;

  /// The node table, which is where the mesh's population actually lives —
  /// the transport reports nodes as a stream, not as a list.
  final MeshNodeStore _nodes;
  final MeshStore _store;
  final DateTime Function() _now;

  StreamSubscription<MeshTraffic>? _sub;
  DateTime? _lastRecorded;

  /// How often the neighbours' readings are written.
  ///
  /// Their telemetry has no timestamp of its own — only the node table's
  /// current values — so unlike the radio's own reading there is nothing to
  /// deduplicate against. A fixed cadence bounds the day at a known number of
  /// rows per node instead of following whatever the mesh's packet rate
  /// happens to be, which on a busy mesh is several a second.
  static const Duration nodeSampleInterval = Duration(minutes: 2);

  DateTime? _lastNodeSample;

  void start() {
    _sub ??= _service.trafficStream.listen((_) => _sample());
  }

  void _sample() {
    _sampleRadio();
    _sampleNodes();
  }

  void _sampleRadio() {
    final radio = _service.radioInfo;
    final at = radio?.metricsAt;
    if (radio == null || at == null || at == _lastRecorded) return;
    // Nothing to plot: a radio that reports neither figure would otherwise
    // fill the history with empty rows.
    if (radio.channelUtilization == null && radio.airUtilTx == null) return;
    _lastRecorded = at;
    final nodes = _nodes.nodes;
    unawaited(
      _store
          .addMetric(
            MeshMetricSample(
              at: at,
              channelUtilization: radio.channelUtilization,
              airUtilTx: radio.airUtilTx,
              batteryPercent: radio.batteryPercent,
              voltage: radio.voltage,
              nodesTotal: nodes.length,
              nodesOnline: nodes.where((node) => node.isOnline).length,
            ),
          )
          .catchError(
            (Object error, StackTrace stackTrace) =>
                Log.handle(error, stackTrace, 'mesh metrics record'),
          ),
    );
  }

  /// Writes every neighbour that has something to report, on a fixed cadence.
  ///
  /// A node with no battery, voltage *or* signal contributes nothing but a
  /// row, so it is skipped: a mesh where most entries are name-only would
  /// otherwise spend the day's storage on empty samples.
  void _sampleNodes() {
    final at = _now();
    final last = _lastNodeSample;
    if (last != null && at.difference(last) < nodeSampleInterval) return;
    _lastNodeSample = at;

    final samples = <MeshNodeMetricSample>[
      for (final node in _nodes.nodes)
        if (node.batteryLevel != null || node.voltage != null || node.snr != 0)
          MeshNodeMetricSample(
            at: at,
            node: node.num,
            battery: node.batteryLevel,
            voltage: node.voltage,
            snr: node.snr != 0 ? node.snr : null,
          ),
    ];
    if (samples.isEmpty) return;
    unawaited(
      _store
          .addNodeMetrics(samples)
          .catchError(
            (Object error, StackTrace stackTrace) =>
                Log.handle(error, stackTrace, 'mesh node metrics record'),
          ),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
