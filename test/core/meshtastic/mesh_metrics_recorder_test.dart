/// The mesh's daily utilization history: what triggers a write, what does
/// not, and the two kinds of counter reset a live radio and a live BLE link
/// both produce on their own, independently of each other.
///
/// Three invariants carry real cost if they silently regress:
///
///  * The radio's traffic counters and its `LocalStats` counters are both
///    cumulative, so a sample stores a *delta*. A delta computed straight
///    across a reconnect (the transport's session counters reset) or a
///    reboot (`LocalStats.uptime` goes backwards) is a spike large enough to
///    make every other point on the chart unreadable — both cases must
///    re-baseline and report nothing for that one sample instead of a huge
///    or negative number.
///  * A neighbour's telemetry carries no timestamp of its own, so it is
///    sampled on a fixed cadence measured against an injected `Elapsed` — a
///    monotonic source — rather than the wall clock. The wall clock steps on
///    the first SNTP sync; measuring the cadence against it means a backward
///    step makes "now − last" negative, which reads as "under the interval"
///    forever, silently freezing the neighbour history for the rest of the
///    session.
///  * The device-telemetry stream and the `LocalStats` stream are two
///    independent triggers for the same sampling pass, because they arrive
///    on different clocks (roughly every minute vs. every fifteen) —
///    sampling only off one would silently drop whichever counters ride the
///    other.
///
/// Coverage gap, stated rather than worked around: `MeshStore.addMetric` and
/// `MeshStore.addNodeMetrics` both swallow every error internally (their own
/// try/catch logs and does not rethrow) and so their returned `Future` can
/// never actually complete with an error against the real store. The
/// `.catchError(...)` wrapped around each fire-and-forget call in
/// `mesh_metrics_recorder.dart` therefore has no reachable path from a test
/// that exercises the real `MeshStore`, and forcing one would mean
/// hand-rolling a counting subclass of a *concrete* store class, which the
/// task's no-mocking rule reserves for interfaces/abstract classes. Left
/// unexercised rather than forced.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_metrics_recorder.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';
import 'fake_mesh_service.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;

  @override
  Duration get elapsed => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late FakeMeshService service;
  late MeshNodeStore nodeStore;
  late SqliteDatabase db;
  late MeshStore store;
  late _FakeElapsed elapsed;
  late MeshMetricsRecorder recorder;

  MeshNode node(
    int num, {
    int? battery,
    double? voltage,
    double snr = 0,
    DateTime? heard,
  }) => MeshNode(
    num: num,
    displayName: 'n$num',
    batteryLevel: battery,
    voltage: voltage,
    lastHeard: heard ?? now,
    snr: snr,
  );

  Future<void> addNode(MeshNode n) async {
    service.nodes.add(n);
    await Future<void>.delayed(Duration.zero);
  }

  /// Lets a synchronous stream-listener callback (e.g. an early return inside
  /// `_sample()`) run to completion. Broadcast-stream listeners fire on the
  /// microtask queue, which fully drains before a zero-duration `Timer`, so
  /// this is enough to observe "nothing was written" for a path that decides
  /// that synchronously and never reaches the store at all.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  /// The store write itself is fire-and-forget (`unawaited`), so a test that
  /// expects a row has to poll for it rather than assume one `pump()` is
  /// enough.
  Future<List<MeshMetricSample>> pollMetrics({int atLeast = 1}) async {
    for (var i = 0; i < 50; i++) {
      final rows = await store.metrics();
      if (rows.length >= atLeast) return rows;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return store.metrics();
  }

  Future<List<MeshNodeMetricSample>> pollNodeMetrics({int atLeast = 1}) async {
    for (var i = 0; i < 50; i++) {
      final rows = await store.nodeMetrics();
      if (rows.length >= atLeast) return rows;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return store.nodeMetrics();
  }

  setUp(() async {
    // Deliberately a local (not `.utc`) literal: `MeshStore` round-trips `at`
    // through `millisecondsSinceEpoch` and reconstructs it via
    // `DateTime.fromMillisecondsSinceEpoch`, which always yields a local
    // `DateTime`. That preserves the instant but not the UTC flag, and
    // `DateTime.==` (unlike `isAtSameMomentAs`) considers that flag — so a
    // `.utc` `now` here would make every round-tripped `at` compare unequal
    // despite naming the same moment.
    now = DateTime(2026, 1, 1, 12);
    service = FakeMeshService();
    nodeStore = MeshNodeStore(
      service,
      SettingsStore.inMemory({}),
      now: () => now,
    )..start();
    await nodeStore.whenRestored;
    db = openMemoryDb();
    await MeshStore.createSchema(db);
    store = MeshStore(db, now: () => now);
    elapsed = _FakeElapsed();
    recorder = MeshMetricsRecorder(
      service,
      nodeStore,
      store,
      now: () => now,
      elapsed: elapsed,
    );
  });

  tearDown(() async {
    await recorder.dispose();
    await db.close();
  });

  group('the radio reading', () {
    test('the first sample has no traffic baseline yet, so packet deltas are '
        'null, and it counts nodes online vs. total', () async {
      await addNode(node(1, battery: 90)); // heard "now": online
      await addNode(
        node(2, battery: 10, heard: now.subtract(const Duration(hours: 2))),
      ); // stale: offline
      service.traffic = const MeshTraffic(rxPackets: 100, txPackets: 40);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: now,
        channelUtilization: 12.5,
        airUtilTx: 3.0,
        batteryPercent: 80,
        voltage: 4.0,
      );
      recorder.start();

      service.traffics.add(service.traffic);
      final rows = await pollMetrics();

      expect(rows, hasLength(1));
      expect(rows.single.rxPackets, isNull);
      expect(rows.single.txPackets, isNull);
      expect(rows.single.channelUtilization, 12.5);
      expect(rows.single.airUtilTx, 3.0);
      expect(rows.single.batteryPercent, 80);
      expect(rows.single.voltage, 4.0);
      expect(rows.single.at, now);
      expect(rows.single.nodesTotal, 2);
      expect(rows.single.nodesOnline, 1);
    });

    test('a later sample reports the delta since the previous one', () async {
      service.traffic = const MeshTraffic(rxPackets: 100, txPackets: 40);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: now,
        channelUtilization: 12.5,
      );
      recorder.start();
      service.traffics.add(service.traffic);
      await pollMetrics();

      final later = now.add(const Duration(minutes: 1));
      service.traffic = const MeshTraffic(rxPackets: 130, txPackets: 44);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: later,
        channelUtilization: 15.0,
      );
      service.traffics.add(service.traffic);
      final rows = await pollMetrics(atLeast: 2);

      expect(rows, hasLength(2));
      expect(rows.last.rxPackets, 30);
      expect(rows.last.txPackets, 4);
    });

    test('a counter that goes backwards re-baselines instead of a negative '
        'spike', () async {
      service.traffic = const MeshTraffic(rxPackets: 100, txPackets: 40);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: now,
        channelUtilization: 12.5,
      );
      recorder.start();
      service.traffics.add(service.traffic);
      await pollMetrics();

      // A reconnect zeroed the transport's session counters.
      final later = now.add(const Duration(minutes: 1));
      service.traffic = const MeshTraffic(rxPackets: 5, txPackets: 2);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: later,
        channelUtilization: 20.0,
      );
      service.traffics.add(service.traffic);
      final afterReset = await pollMetrics(atLeast: 2);

      expect(afterReset.last.rxPackets, isNull);
      expect(afterReset.last.txPackets, isNull);

      // The lower reading is now the baseline: the next delta is measured
      // from 5/2, never from the pre-reset 100/40.
      final third = later.add(const Duration(minutes: 1));
      service.traffic = const MeshTraffic(rxPackets: 8, txPackets: 3);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: third,
        channelUtilization: 22.0,
      );
      service.traffics.add(service.traffic);
      final all = await pollMetrics(atLeast: 3);

      expect(all.last.rxPackets, 3);
      expect(all.last.txPackets, 1);
    });

    test('a device reading with neither channelUtilization nor airUtilTx does '
        'not count as new, and writes nothing on its own', () async {
      service.radioInfo = MeshRadioInfo(nodeNum: 1, metricsAt: now);
      recorder.start();

      service.traffics.add(const MeshTraffic());
      await pump();

      expect(await store.metrics(), isEmpty);
    });

    test('the same metricsAt is not sampled twice', () async {
      service.traffic = const MeshTraffic(rxPackets: 1, txPackets: 1);
      service.radioInfo = MeshRadioInfo(
        nodeNum: 1,
        metricsAt: now,
        channelUtilization: 1.0,
      );
      recorder.start();
      service.traffics.add(service.traffic);
      await pollMetrics();

      // Same radioInfo, same metricsAt: firing the stream again must not
      // write a second row.
      service.traffics.add(service.traffic);
      await pump();

      expect(await store.metrics(), hasLength(1));
    });
  });

  group("the radio's own counters (LocalStats)", () {
    test('a first LocalStats reading writes no row, only a baseline', () async {
      service.localStatsValue = const MeshLocalStats(
        uptime: Duration(minutes: 5),
        rxPackets: 10,
        rxBadPackets: 0,
        txPackets: 5,
        rxDupePackets: 0,
        txRelay: 0,
        txRelayCanceled: 0,
        heapFree: 1000,
        heapTotal: 2000,
      );
      recorder.start();

      service.localStatsUpdates.add(service.localStatsValue!);
      await pump();

      expect(await store.metrics(), isEmpty);
    });

    test(
      'a genuine second reading writes a counter-only row at "now"',
      () async {
        service.localStatsValue = const MeshLocalStats(
          uptime: Duration(minutes: 5),
          rxPackets: 10,
          rxBadPackets: 0,
          txPackets: 5,
          rxDupePackets: 1,
          txRelay: 2,
          txRelayCanceled: 0,
          heapFree: 1000,
          heapTotal: 2000,
        );
        recorder.start();
        service.localStatsUpdates.add(service.localStatsValue!);
        await pump();
        expect(await store.metrics(), isEmpty);

        service.localStatsValue = const MeshLocalStats(
          uptime: Duration(minutes: 6),
          rxPackets: 25,
          rxBadPackets: 1,
          txPackets: 9,
          rxDupePackets: 2,
          txRelay: 3,
          txRelayCanceled: 1,
          heapFree: 900,
          heapTotal: 2000,
        );
        service.localStatsUpdates.add(service.localStatsValue!);
        final rows = await pollMetrics();

        final row = rows.single;
        expect(row.at, now);
        expect(row.lsRx, 15);
        expect(row.lsRxBad, 1);
        expect(row.lsTx, 4);
        expect(row.lsRxDupe, 1);
        expect(row.lsTxRelay, 1);
        expect(row.lsTxRelayCancel, 1);
        expect(row.heapFree, 900); // a level, not a delta
        // A counter-only row: nothing to plot for the device reading itself.
        expect(row.channelUtilization, isNull);
        expect(row.airUtilTx, isNull);
        expect(row.batteryPercent, isNull);
        expect(row.voltage, isNull);
      },
    );

    test('uptime going backwards (a reboot) re-baselines instead of a huge '
        'spike, and writes nothing for that sample', () async {
      service.localStatsValue = const MeshLocalStats(
        uptime: Duration(minutes: 30),
        rxPackets: 1000,
        rxBadPackets: 10,
        txPackets: 500,
        rxDupePackets: 5,
        txRelay: 20,
        txRelayCanceled: 2,
        heapFree: 800,
        heapTotal: 2000,
      );
      recorder.start();
      service.localStatsUpdates.add(service.localStatsValue!);
      await pump();

      // The radio rebooted: uptime and every counter restarted from zero.
      service.localStatsValue = const MeshLocalStats(
        uptime: Duration(minutes: 1),
        rxPackets: 3,
        rxBadPackets: 0,
        txPackets: 1,
        rxDupePackets: 0,
        txRelay: 0,
        txRelayCanceled: 0,
        heapFree: 2000,
        heapTotal: 2000,
      );
      service.localStatsUpdates.add(service.localStatsValue!);
      await pump();
      expect(await store.metrics(), isEmpty);

      // The next reading is a genuine delta from the post-reboot baseline,
      // not from the pre-reboot totals.
      service.localStatsValue = const MeshLocalStats(
        uptime: Duration(minutes: 2),
        rxPackets: 9,
        rxBadPackets: 0,
        txPackets: 3,
        rxDupePackets: 0,
        txRelay: 0,
        txRelayCanceled: 0,
        heapFree: 1950,
        heapTotal: 2000,
      );
      service.localStatsUpdates.add(service.localStatsValue!);
      final rows = await pollMetrics();

      expect(rows.single.lsRx, 6);
      expect(rows.single.lsTx, 2);
    });

    test(
      'a repeated LocalStats report (unchanged uptime) writes nothing',
      () async {
        service.localStatsValue = const MeshLocalStats(
          uptime: Duration(minutes: 5),
          rxPackets: 10,
          rxBadPackets: 0,
          txPackets: 5,
          rxDupePackets: 0,
          txRelay: 0,
          txRelayCanceled: 0,
          heapFree: 1000,
          heapTotal: 2000,
        );
        recorder.start();
        service.localStatsUpdates.add(service.localStatsValue!);
        await pump();

        // The radio reports LocalStats roughly every 15 minutes but device
        // telemetry every ~1; most samples see the exact same block again.
        service.localStatsUpdates.add(service.localStatsValue!);
        await pump();

        expect(await store.metrics(), isEmpty);
      },
    );

    test(
      'packet counters decreasing without an uptime drop also re-baselines',
      () async {
        service.localStatsValue = const MeshLocalStats(
          uptime: Duration(minutes: 5),
          rxPackets: 100,
          rxBadPackets: 0,
          txPackets: 50,
          rxDupePackets: 0,
          txRelay: 0,
          txRelayCanceled: 0,
          heapFree: 1000,
          heapTotal: 2000,
        );
        recorder.start();
        service.localStatsUpdates.add(service.localStatsValue!);
        await pump();

        // Uptime advanced normally, but the packet counters read lower than
        // last time — a defensive re-baseline even without the uptime tell.
        service.localStatsValue = const MeshLocalStats(
          uptime: Duration(minutes: 6),
          rxPackets: 10,
          rxBadPackets: 0,
          txPackets: 4,
          rxDupePackets: 0,
          txRelay: 0,
          txRelayCanceled: 0,
          heapFree: 1000,
          heapTotal: 2000,
        );
        service.localStatsUpdates.add(service.localStatsValue!);
        await pump();

        expect(await store.metrics(), isEmpty);
      },
    );
  });

  group('neighbour samples', () {
    test(
      'only nodes with a battery, a voltage or a nonzero SNR are written',
      () async {
        await addNode(node(1, battery: 80));
        await addNode(node(2, voltage: 3.9));
        await addNode(node(3, snr: -5.0));
        await addNode(node(4)); // nothing to report: excluded
        recorder.start();

        service.traffics.add(const MeshTraffic());
        final rows = await pollNodeMetrics(atLeast: 3);

        expect(rows.map((r) => r.node), containsAll(<int>[1, 2, 3]));
        expect(rows.map((r) => r.node), isNot(contains(4)));
        expect(rows.firstWhere((r) => r.node == 3).snr, -5.0);
      },
    );

    test('samples with nothing to report write nothing at all', () async {
      await addNode(node(4));
      recorder.start();

      service.traffics.add(const MeshTraffic());
      await pump();

      expect(await store.nodeMetrics(), isEmpty);
    });

    test(
      'node samples are gated by the elapsed interval, not by wall time',
      () async {
        await addNode(node(1, battery: 80));
        recorder.start();

        elapsed.value = Duration.zero;
        service.traffics.add(const MeshTraffic());
        await pollNodeMetrics();

        // Under the two-minute cadence since the last sample: skipped, even
        // though wall time (`now`) has moved on.
        elapsed.value = const Duration(seconds: 30);
        now = now.add(const Duration(minutes: 1));
        service.traffics.add(const MeshTraffic());
        await pump();
        expect(await store.nodeMetrics(), hasLength(1));

        // Past the cadence: samples again, at the new "now".
        elapsed.value = const Duration(minutes: 3);
        now = now.add(const Duration(minutes: 1));
        service.traffics.add(const MeshTraffic());
        final rows = await pollNodeMetrics(atLeast: 2);

        expect(rows, hasLength(2));
      },
    );
  });

  test('dispose cancels both subscriptions', () async {
    service.traffic = const MeshTraffic(rxPackets: 1, txPackets: 1);
    service.radioInfo = MeshRadioInfo(
      nodeNum: 1,
      metricsAt: now,
      channelUtilization: 1.0,
    );
    recorder.start();
    service.traffics.add(service.traffic);
    await pollMetrics();

    await recorder.dispose();

    final later = now.add(const Duration(minutes: 1));
    service.radioInfo = MeshRadioInfo(
      nodeNum: 1,
      metricsAt: later,
      channelUtilization: 2.0,
    );
    service.traffics.add(service.traffic);
    await pump();

    // Unchanged: the subscriptions were cancelled, so nothing samples again.
    expect(await store.metrics(), hasLength(1));
  });
}
