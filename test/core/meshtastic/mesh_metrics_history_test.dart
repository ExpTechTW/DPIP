/// A day of mesh history: the radio's own readings, and the neighbours'.
///
/// The point of keeping any of it is answering "when did this start" after the
/// fact — a coverage collapse, a pack going flat, a repeater that stopped
/// being heard. That only works if the series survives the app restart that
/// usually follows noticing.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _open() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await MeshStore.createSchema(db);
  return db;
}

final _now = DateTime.utc(2026, 8, 15, 12);
DateTime _ago(Duration d) => _now.subtract(d);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  group('the radio', () {
    test('keeps every series it was given', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => _now);

      await store.addMetric(
        MeshMetricSample(
          at: _ago(const Duration(minutes: 5)),
          channelUtilization: 12.5,
          airUtilTx: 3.25,
          batteryPercent: 87,
          voltage: 4.036,
          nodesTotal: 42,
          nodesOnline: 17,
        ),
      );

      final sample = (await store.metrics()).single;
      expect(sample.channelUtilization, 12.5);
      expect(sample.airUtilTx, 3.25);
      expect(sample.batteryPercent, 87);
      // Volts, not just percent: the radio pins percent at 101 on external
      // power, so it is the voltage that shows a cell ageing.
      expect(sample.voltage, closeTo(4.036, 1e-9));
      expect(sample.nodesTotal, 42);
      expect(sample.nodesOnline, 17);
    });

    test(
      'the new columns reach a database created before they existed',
      () async {
        // The durable schema is re-applied on every open as CREATE TABLE IF NOT
        // EXISTS, which does nothing for a table that is already there — so a
        // new column has to arrive by ALTER or it never appears at all.
        final db = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        addTearDown(db.close);
        await db.execute('''
        CREATE TABLE mesh_metrics (
          ts INTEGER PRIMARY KEY,
          channel_util REAL,
          air_util REAL,
          battery INTEGER
        )
      ''');
        await MeshStore.createSchema(db);

        final store = MeshStore(db, now: () => _now);
        await store.addMetric(MeshMetricSample(at: _now, voltage: 3.9));
        expect((await store.metrics()).single.voltage, closeTo(3.9, 1e-9));
      },
    );
  });

  group('the neighbours', () {
    test('are kept per node, not averaged', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => _now);
      await store.addNodeMetrics([
        MeshNodeMetricSample(
          at: _ago(const Duration(minutes: 10)),
          node: 7,
          battery: 80,
          voltage: 3.9,
          snr: -4.5,
        ),
        MeshNodeMetricSample(
          at: _ago(const Duration(minutes: 10)),
          node: 9,
          battery: 55,
        ),
      ]);

      // "The mesh is fine on average" is not actionable; "that repeater is at
      // 55%" is.
      final seven = await store.nodeMetrics(node: 7);
      expect(seven.single.battery, 80);
      expect(seven.single.voltage, closeTo(3.9, 1e-9));
      expect(seven.single.snr, closeTo(-4.5, 1e-9));
      expect(await store.nodeMetrics(), hasLength(2));
    });

    test('a repeated reading overwrites rather than piling up', () async {
      // The radio re-emits a node's telemetry until it changes, so without the
      // composite key a quiet mesh would still fill the day with duplicates.
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => _now);
      final at = _ago(const Duration(minutes: 1));
      await store.addNodeMetrics([
        MeshNodeMetricSample(at: at, node: 7, battery: 80),
      ]);
      await store.addNodeMetrics([
        MeshNodeMetricSample(at: at, node: 7, battery: 81),
      ]);
      final rows = await store.nodeMetrics(node: 7);
      expect(rows, hasLength(1));
      expect(rows.single.battery, 81);
    });

    test('only the last day is returned, whatever is stored', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => _now);
      await store.addNodeMetrics([
        MeshNodeMetricSample(at: _ago(Duration.zero), node: 7),
        MeshNodeMetricSample(at: _ago(const Duration(hours: 25)), node: 7),
      ]);
      // Enforced on read as well as by the sweep: a missed sweep must cost
      // disk, never a wrong chart.
      expect(await store.nodeMetrics(), hasLength(1));
    });

    test('survives the restart that usually follows noticing', () async {
      final db = await _open();
      addTearDown(db.close);
      await MeshStore(db, now: () => _now).addNodeMetrics([
        MeshNodeMetricSample(
          at: _ago(const Duration(hours: 6)),
          node: 7,
          battery: 40,
        ),
      ]);
      // A fresh store over the same file — a new process, nothing in memory.
      final reopened = await MeshStore(db, now: () => _now).nodeMetrics();
      expect(reopened.single.battery, 40);
    });
  });

  group('table stats', () {
    test('name the table, its rows and its file', () async {
      final durable = await _open();
      addTearDown(durable.close);
      final store = MeshStore(durable, now: () => _now);
      await store.addNodeMetrics([
        for (var i = 0; i < 5; i++)
          MeshNodeMetricSample(
            at: _ago(Duration(minutes: i)),
            node: 7,
            battery: 80,
          ),
      ]);

      final stats = await AppDatabase(
        durable: durable,
        cache: null,
      ).tableStats();
      final nodeMetrics = stats.firstWhere(
        (s) => s.table == 'mesh_node_metrics',
      );
      expect(nodeMetrics.rows, 5);
      expect(nodeMetrics.file, 'dpip.db');
      // Which file it is in is the difference between "the OS may delete this"
      // and "only the user can".
      expect(stats.every((s) => s.file == 'dpip.db'), isTrue);
    });

    test(
      'are ordered biggest first — the question is what dominates',
      () async {
        final durable = await _open();
        addTearDown(durable.close);
        final store = MeshStore(durable, now: () => _now);
        for (var i = 0; i < 40; i++) {
          await store.addMessage(
            MeshStoredMessage(
              from: 1,
              channel: 0,
              text: 'a message long enough to weigh something $i',
              timestamp: _ago(Duration(minutes: i)),
              outgoing: false,
            ),
          );
        }
        final stats = await AppDatabase(
          durable: durable,
          cache: null,
        ).tableStats();
        expect(stats.first.table, 'mesh_messages');
        for (var i = 1; i < stats.length; i++) {
          expect(stats[i - 1].bytes, greaterThanOrEqualTo(stats[i].bytes));
        }
      },
    );

    test('a missing database is no tables, not a crash', () async {
      expect(
        await const AppDatabase(durable: null, cache: null).tableStats(),
        isEmpty,
      );
    });
  });

  group('traffic deltas', () {
    test('round-trip through the store', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => _now);
      await store.addMetric(
        MeshMetricSample(
          at: _ago(const Duration(minutes: 5)),
          rxPackets: 42,
          txPackets: 3,
        ),
      );
      final sample = (await store.metrics()).single;
      expect(sample.rxPackets, 42);
      expect(sample.txPackets, 3);
    });
  });
}
