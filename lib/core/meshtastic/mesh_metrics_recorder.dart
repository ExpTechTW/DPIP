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
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';

class MeshMetricsRecorder {
  MeshMetricsRecorder(
    this._service,
    this._nodes,
    this._store, {
    DateTime Function()? now,
    Elapsed? elapsed,
  }) : _now = now ?? (() => AppTime.utc.toLocal()),
       _elapsed = elapsed ?? SystemElapsed();

  final MeshtasticService _service;

  /// The node table, which is where the mesh's population actually lives —
  /// the transport reports nodes as a stream, not as a list.
  final MeshNodeStore _nodes;
  final MeshStore _store;
  final DateTime Function() _now;

  /// Monotonic, and deliberately not the wall clock.
  ///
  /// The neighbour cadence is an *elapsed* measurement, and the wall clock is
  /// not an instrument for that: the first successful SNTP sync re-anchors it
  /// by the device's full error, routinely mid-session (`RealtimeService`
  /// resyncs every 60 s and on resume) — which is exactly the mesh's own
  /// scenario, launch off-grid and regain connectivity hours later. A backward
  /// step made `now - last` negative, which is "less than the interval", so
  /// the gate returned *before* re-baselining and the baseline never reset:
  /// zero rows for the whole offset, drawn afterwards as a coverage blackout
  /// that never happened. The stored stamp stays [_now] — that is a timestamp,
  /// not a duration.
  final Elapsed _elapsed;

  StreamSubscription<MeshTraffic>? _sub;
  StreamSubscription<MeshLocalStats>? _statsSub;
  DateTime? _lastRecorded;

  /// The transport's cumulative counters as of the last sample, so each
  /// sample stores the *delta* — its own slice of activity. Reset detection:
  /// a counter that went backwards (reconnect zeroes the session counters)
  /// starts a fresh baseline instead of producing a negative spike.
  int _lastRxPackets = 0;
  int _lastTxPackets = 0;
  bool _trafficBaselined = false;

  /// The radio's own counters as of the last sample, for the same reason —
  /// but with a reset test the transport's counters do not need: `LocalStats`
  /// is cumulative *since the radio booted*, so a reboot zeroes all seven at
  /// once. [MeshLocalStats.uptime] going backwards is the tell, and it is
  /// checked before any subtraction, because a wrapped counter here would
  /// paint a cliff on every chart that reads these.
  MeshLocalStats? _lastStats;

  /// How often the neighbours' readings are written.
  ///
  /// Their telemetry has no timestamp of its own — only the node table's
  /// current values — so unlike the radio's own reading there is nothing to
  /// deduplicate against. A fixed cadence bounds the day at a known number of
  /// rows per node instead of following whatever the mesh's packet rate
  /// happens to be, which on a busy mesh is several a second.
  static const Duration nodeSampleInterval = Duration(minutes: 2);

  Duration? _lastNodeSample;

  void start() {
    _sub ??= _service.trafficStream.listen((_) => _sample());
    // A second trigger, because the two feeds are on different clocks and the
    // radio's counters are the slower one. Device telemetry ticks about every
    // minute; `LocalStats` lands every fifteen. Sampling only on the fast feed
    // meant a radio whose device telemetry stalled — or simply a quiet minute
    // straddling the counter report — dropped that block entirely, and the
    // four counter charts had holes where the radio had actually spoken.
    _statsSub ??= _service.localStatsStream.listen((_) => _sample());
  }

  void _sample() {
    _sampleRadio();
    _sampleNodes();
  }

  void _sampleRadio() {
    // Taken first, and unconditionally: the counter block is its own news, and
    // gating it behind the device reading being fresh is what lost it.
    final stats = _localStatsDelta();
    final radio = _service.radioInfo;
    final at = radio?.metricsAt;
    final deviceReadingIsNew =
        radio != null &&
        at != null &&
        at != _lastRecorded &&
        // Nothing to plot: a radio that reports neither figure would otherwise
        // fill the history with empty rows.
        (radio.channelUtilization != null || radio.airUtilTx != null);
    if (!deviceReadingIsNew && stats == null) return;
    if (deviceReadingIsNew) _lastRecorded = at;
    // The reading's own timestamp when there is one; otherwise now, because a
    // counter block is about the window that just ended.
    final rowAt = deviceReadingIsNew ? at : _now();
    final nodes = _nodes.nodes;
    final traffic = _service.traffic;
    int? rxDelta;
    int? txDelta;
    if (_trafficBaselined &&
        traffic.rxPackets >= _lastRxPackets &&
        traffic.txPackets >= _lastTxPackets) {
      rxDelta = traffic.rxPackets - _lastRxPackets;
      txDelta = traffic.txPackets - _lastTxPackets;
    }
    _lastRxPackets = traffic.rxPackets;
    _lastTxPackets = traffic.txPackets;
    _trafficBaselined = true;
    unawaited(
      _store
          .addMetric(
            MeshMetricSample(
              at: rowAt,
              // Null on a counter-only row, and that is the point: the row is
              // about the counters, and a null says "this row has no reading
              // for you" rather than inventing one. The charts skip it and
              // measure the gap between the readings on either side.
              channelUtilization: deviceReadingIsNew
                  ? radio.channelUtilization
                  : null,
              airUtilTx: deviceReadingIsNew ? radio.airUtilTx : null,
              batteryPercent: deviceReadingIsNew ? radio.batteryPercent : null,
              voltage: deviceReadingIsNew ? radio.voltage : null,
              nodesTotal: nodes.length,
              // The store's rule, not the flag on the node: `MeshNode.isOnline` is
              // whatever the transport thought when it built the node, while
              // `MeshNodeStore.isOnline` re-derives it from `lastHeard` against the
              // calibrated clock — the same one this row's timestamp comes from.
              nodesOnline: nodes.where(_nodes.isOnline).length,
              rxPackets: rxDelta,
              txPackets: txDelta,
              lsRx: stats?.rxPackets,
              lsRxBad: stats?.rxBadPackets,
              lsTx: stats?.txPackets,
              lsRxDupe: stats?.rxDupePackets,
              lsTxRelay: stats?.txRelay,
              lsTxRelayCancel: stats?.txRelayCanceled,
              // A level, not a delta: what forecasts a reboot is the slope of
              // free heap across the day, and a difference throws that away.
              heapFree: _service.localStats?.heapFree,
            ),
          )
          .catchError(
            (Object error, StackTrace stackTrace) =>
                Log.handle(error, stackTrace, 'mesh metrics record'),
          ),
    );
  }

  /// The radio's counters since the previous sample, or null when there is no
  /// honest difference to report — no reading yet, no previous baseline, or
  /// the radio rebooted between the two.
  ///
  /// Returned as a [MeshLocalStats] whose fields hold *deltas* rather than
  /// totals; only the caller's field names say which is which, so nothing
  /// downstream may treat this as a live reading.
  MeshLocalStats? _localStatsDelta() {
    final now = _service.localStats;
    if (now == null) return null;
    final last = _lastStats;
    if (last == null) {
      _lastStats = now;
      return null;
    }
    // The same report again. The radio pushes `LocalStats` every ~15 minutes
    // but device metrics arrive every ~1, so most samples see an unchanged
    // block — and subtracting it from itself would write fourteen rows of
    // zeroes for every real one, which is storage spent to say nothing.
    // Uptime always advances between genuine reports.
    if (now.uptime == last.uptime) return null;
    _lastStats = now;
    // Rebooted: every counter restarted from zero, so this window has no
    // meaningful width. Re-baseline and report nothing rather than a spike.
    if (now.uptime < last.uptime) return null;
    if (now.rxPackets < last.rxPackets || now.txPackets < last.txPackets) {
      return null;
    }
    return MeshLocalStats(
      uptime: now.uptime - last.uptime,
      rxPackets: now.rxPackets - last.rxPackets,
      rxBadPackets: now.rxBadPackets - last.rxBadPackets,
      txPackets: now.txPackets - last.txPackets,
      rxDupePackets: now.rxDupePackets - last.rxDupePackets,
      txRelay: now.txRelay - last.txRelay,
      txRelayCanceled: now.txRelayCanceled - last.txRelayCanceled,
      heapFree: now.heapFree,
      heapTotal: now.heapTotal,
    );
  }

  /// Writes every neighbour that has something to report, on a fixed cadence.
  ///
  /// A node with no battery, voltage *or* signal contributes nothing but a
  /// row, so it is skipped: a mesh where most entries are name-only would
  /// otherwise spend the day's storage on empty samples.
  void _sampleNodes() {
    final since = _elapsed.elapsed;
    final last = _lastNodeSample;
    if (last != null && since - last < nodeSampleInterval) return;
    _lastNodeSample = since;
    final at = _now();

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
    await _statsSub?.cancel();
    _sub = null;
    _statsSub = null;
  }
}
