/// Records the radio's utilization readings so they can be plotted over time.
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
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';

class MeshMetricsRecorder {
  MeshMetricsRecorder(this._service, this._store);

  final MeshtasticService _service;
  final MeshStore _store;

  StreamSubscription<MeshTraffic>? _sub;
  DateTime? _lastRecorded;

  void start() {
    _sub ??= _service.trafficStream.listen((_) => _sample());
  }

  void _sample() {
    final radio = _service.radioInfo;
    final at = radio?.metricsAt;
    if (radio == null || at == null || at == _lastRecorded) return;
    // Nothing to plot: a radio that reports neither figure would otherwise
    // fill the history with empty rows.
    if (radio.channelUtilization == null && radio.airUtilTx == null) return;
    _lastRecorded = at;
    unawaited(
      _store
          .addMetric(
            MeshMetricSample(
              at: at,
              channelUtilization: radio.channelUtilization,
              airUtilTx: radio.airUtilTx,
              batteryPercent: radio.batteryPercent,
            ),
          )
          .catchError(
            (Object error, StackTrace stackTrace) =>
                Log.handle(error, stackTrace, 'mesh metrics record'),
          ),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
