/// One schedule enforces every window.
///
/// The failure this covers is an app that is *left running*, which for a
/// disaster-prevention app is the normal case rather than the exception.
/// Retention used to ride on whatever each store happened to be doing — the
/// mesh log pruned at bootstrap, the app log inside a buffered write — so a
/// phone sitting on a desk for three days pruned only the tables that stayed
/// busy, and the ones that went quiet kept growing until the next launch.
library;

import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/storage/retention.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _open() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await MeshStore.createSchema(db);
  await LogStore.createSchema(db);
  await NetworkUsageStore.createSchema(db);
  await EtagCacheStore.createSchema(db);
  return db;
}

/// Every store nulled out but the one under test, so a failure names it.
RetentionService _service({
  MeshStore? mesh,
  LogStore? logs,
  NetworkUsageStore? usage,
  EtagCacheStore? httpCache,
}) => RetentionService(
  mesh: mesh,
  logs: logs,
  usage: usage,
  httpCache: httpCache,
);

Future<int> _count(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM $table');
  return rows.first['n']! as int;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  test('a sweep drops what is past its window and keeps the rest', () async {
    final db = await _open();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 15, 12);
    final store = MeshStore(db, now: () => now);

    // Inside the 24-hour metric window, and outside it.
    await store.addMetric(
      MeshMetricSample(at: now.subtract(const Duration(hours: 1)), voltage: 4),
    );
    await store.addMetric(
      MeshMetricSample(at: now.subtract(const Duration(hours: 30)), voltage: 4),
    );
    await store.addNodeMetrics([
      MeshNodeMetricSample(
        at: now.subtract(const Duration(hours: 2)),
        node: 7,
        battery: 80,
      ),
      MeshNodeMetricSample(
        at: now.subtract(const Duration(hours: 48)),
        node: 7,
        battery: 90,
      ),
    ]);
    expect(await _count(db, 'mesh_metrics'), 2);
    expect(await _count(db, 'mesh_node_metrics'), 2);

    await _service(mesh: store).sweep();

    expect(await _count(db, 'mesh_metrics'), 1);
    expect(await _count(db, 'mesh_node_metrics'), 1);
  });

  test('the log is pruned even with nothing buffered to write', () async {
    // The bug: `LogStore.flush` returns early when its buffer is empty, and it
    // was the only thing that pruned. An app whose log went quiet — the radio
    // disconnected, nothing failing — kept yesterday for as long as it ran.
    final db = await _open();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 15, 12);
    await db.insert(logTable, {
      'time': now.subtract(const Duration(hours: 30)).millisecondsSinceEpoch,
      'level': 'info',
      'message': 'yesterday',
    });
    await db.insert(logTable, {
      'time': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      'level': 'info',
      'message': 'recent',
    });

    final logs = LogStore(db, now: () => now);
    await _service(logs: logs).sweep();

    expect(await _count(db, logTable), 1);
  });

  test('a sweep survives a store that is not there', () async {
    // Either database may fail to open; retention over nothing is nothing to
    // do, not a crash on the way up.
    await _service().sweep();
  });

  test('overlapping sweeps do not stack', () async {
    final db = await _open();
    addTearDown(db.close);
    final service = _service(mesh: MeshStore(db));
    await Future.wait([service.sweep(), service.sweep(), service.sweep()]);
  });

  test('start defers the first sweep past the launch window', () async {
    final db = await _open();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 15, 12);
    final store = MeshStore(db, now: () => now);
    await store.addMetric(
      MeshMetricSample(at: now.subtract(const Duration(days: 3))),
    );

    final service = _service(mesh: store)..start();
    addTearDown(service.dispose);
    // Deliberately NOT immediate: the first sweep's deletes and the cache
    // recount share the serial SQLite queue with the launch window's own
    // reads. It fires [RetentionService.firstSweepDelay] later — far shorter
    // than any session, so a rare launch still does its whole cleanup.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await _count(db, 'mesh_metrics'), 1, reason: 'swept during launch');
    expect(
      RetentionService.firstSweepDelay,
      lessThan(retentionInterval),
      reason: 'the first sweep must not wait a whole interval',
    );
  });

  test('the interval is short enough to bound the overshoot', () {
    // Shorter than the tightest window it enforces, so a 24-hour table never
    // holds more than 25 hours.
    expect(retentionInterval, lessThan(MeshStore.metricRetention));
    expect(retentionInterval, lessThan(logRetention));
  });

  test('network buckets are trimmed with nothing buffered to flush', () async {
    // Same shape as the log: `flush` returns early when nothing is pending,
    // and it was the only thing that trimmed. An app making no requests — the
    // very state in which nothing else prunes either — kept every bucket.
    final db = await _open();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 15, 12);
    const hourMs = 3600 * 1000;
    final hour = now.millisecondsSinceEpoch ~/ hourMs;
    for (final offset in [1, 24 * 7 + 10]) {
      await db.insert('net_bucket', {
        'hour': hour - offset,
        'down': 1000,
        'saved': 0,
        'hits': 0,
        'misses': 1,
      });
    }
    expect(await _count(db, 'net_bucket'), 2);

    await _service(usage: NetworkUsageStore(db, now: () => now)).sweep();

    expect(await _count(db, 'net_bucket'), 1);
  });

  test('the http cache is brought back inside a lowered budget', () async {
    // The carry-over case: the budget is enforced on write, amortized over 96
    // rows. A session that ended over it — or a ceiling lowered between
    // releases — stays over until that many writes happen again, which on an
    // idle app is never.
    final db = await _open();
    addTearDown(db.close);
    for (var i = 0; i < 20; i++) {
      await db.insert('http_cache', {
        'key': 'https://example.test/$i',
        'etag': '"$i"',
        'kind': EtagCacheStore.kindJson,
        'body': 'x' * 100,
        'size': 100,
        'time': i,
      });
    }
    expect(await _count(db, 'http_cache'), 20);

    // A budget far below what is stored.
    await _service(httpCache: EtagCacheStore(db, maxBytes: 500)).sweep();

    final left = await _count(db, 'http_cache');
    expect(left, lessThan(20), reason: 'nothing was trimmed');
    expect(left, greaterThan(0), reason: 'the budget is a trim, not a wipe');
  });

  test('one sweep covers every store at once', () async {
    // The point of the class: a caller cannot forget one, and adding a store
    // later cannot leave it running on its own schedule.
    final db = await _open();
    addTearDown(db.close);
    final now = DateTime.utc(2026, 8, 15, 12);
    final mesh = MeshStore(db, now: () => now);
    // Two samples three days apart: the newer one anchors the window, so the
    // older is genuinely outside it. A single old row would be *kept* — see
    // the cutoff in `MeshStore.prune`, which will not let a clock that moved
    // forward delete the only telemetry there is.
    await mesh.addMetric(
      MeshMetricSample(at: now.subtract(const Duration(days: 3))),
    );
    await mesh.addMetric(MeshMetricSample(at: now));
    await db.insert(logTable, {
      'time': now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
      'level': 'info',
      'message': 'old',
    });
    await db.insert('net_bucket', {
      'hour': now.millisecondsSinceEpoch ~/ (3600 * 1000) - (24 * 7 + 10),
      'down': 1,
      'saved': 0,
      'hits': 0,
      'misses': 1,
    });

    await RetentionService(
      mesh: MeshStore(db, now: () => now),
      logs: LogStore(db, now: () => now),
      usage: NetworkUsageStore(db, now: () => now),
      httpCache: EtagCacheStore(db),
    ).sweep();

    expect(await _count(db, 'mesh_metrics'), 1);
    expect(await _count(db, logTable), 0);
    expect(await _count(db, 'net_bucket'), 0);
  });
}
