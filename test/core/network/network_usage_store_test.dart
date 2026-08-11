import 'package:dpip/core/network/network_usage_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  var now = DateTime.utc(2026, 1, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    now = DateTime.utc(2026, 1, 10, 12);
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await NetworkUsageStore.createSchema(db);
  });

  tearDown(() async => db.close());

  NetworkUsageStore store() => NetworkUsageStore(db, now: () => now);

  test('empty store reports zeros and a zero hit rate', () async {
    final s = await store().stats();
    expect(s.last24h, 0);
    expect(s.last7d, 0);
    expect(s.total24h, 0);
    expect(s.hitRate24h, 0);
    expect(s.hitRate7d, 0);
  });

  test('records downloads, hits, misses, and saved bytes', () async {
    final s = store();
    await s.record(down: 1000, hit: false, saved: 0);
    await s.record(down: 500, hit: false, saved: 0);
    await s.record(down: 0, hit: true, saved: 800);

    final stats = await s.stats();
    expect(stats.last24h, 1500);
    expect(stats.last7d, 1500);
    expect(stats.misses24h, 2);
    expect(stats.hits24h, 1);
    expect(stats.saved24h, 800);
    expect(stats.saved7d, 800);
    expect(stats.hitRate24h, closeTo(1 / 3, 1e-9));
  });

  test('every figure windows, including the hit rate', () async {
    final s = store();
    // Day 0: one hit, one miss → 50%.
    await s.record(down: 1000, hit: true, saved: 400);
    await s.record(down: 0, hit: false, saved: 0);

    now = now.add(const Duration(days: 2)); // day 2
    // Day 2: three hits, one miss → 75%.
    for (var i = 0; i < 3; i++) {
      await s.record(down: 0, hit: true, saved: 100);
    }
    await s.record(down: 2000, hit: false, saved: 0);

    final stats = await s.stats();
    expect(stats.last24h, 2000, reason: 'only day 2 is within 24h');
    expect(stats.last7d, 3000, reason: 'both days are within 7 days');
    expect(stats.saved24h, 300);
    expect(stats.saved7d, 700);
    expect(
      stats.hitRate24h,
      closeTo(0.75, 1e-9),
      reason:
          'the hit rate windows like everything else, so a bad stretch today '
          'is not hidden by a good week',
    );
    expect(stats.hitRate7d, closeTo(4 / 6, 1e-9));
  });

  test('a pre-existing database is migrated on open', () async {
    // Rebuild the shape shipped before anything but downloads was windowed.
    await db.execute('DROP TABLE net_bucket');
    await db.execute(
      'CREATE TABLE net_bucket (hour INTEGER PRIMARY KEY, '
      'down INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE net_total ('
      'k TEXT PRIMARY KEY, v INTEGER NOT NULL DEFAULT 0)',
    );
    await db.insert('net_total', {'k': 'saved', 'v': 999});

    await NetworkUsageStore.createSchema(db);
    final s = store();
    await s.record(down: 10, hit: true, saved: 60);

    final stats = await s.stats();
    expect(stats.saved24h, 60);
    expect(stats.hits24h, 1);
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type='table' AND name='net_total'",
      ),
      isEmpty,
      reason:
          'lifetime totals cannot be windowed after the fact, and leaving them '
          'would be a second contradictory answer',
    );
  });

  test(
    'the sliding window sweeps buckets older than 7 days on write',
    () async {
      final s = store();
      await s.record(down: 1000, hit: false, saved: 0); // day 0

      now = now.add(const Duration(days: 9)); // day 9 → day-0 bucket is >7d old
      await s.record(down: 100, hit: false, saved: 0);

      final stats = await s.stats();
      expect(stats.last7d, 100, reason: 'the day-0 bucket was swept');
      expect(stats.misses7d, 1, reason: 'its counters went with it');
    },
  );

  test('clear drops recorded and still-buffered usage alike', () async {
    final s = store();
    await s.record(down: 1000, hit: true, saved: 400);
    await s.stats(); // force the flush, so this much is on disk
    await s.record(down: 500, hit: false, saved: 0); // still buffered

    await s.clear();

    final stats = await s.stats();
    expect(stats.last24h, 0);
    expect(stats.saved24h, 0);
    expect(
      stats.total24h,
      0,
      reason:
          'a hit rate beside an emptied store would describe a cache that '
          'no longer exists',
    );
    expect(
      await db.query('net_bucket'),
      isEmpty,
      reason:
          'the buffered aggregate must go too, or the counters reappear a '
          'second later when it flushes',
    );
  });

  test('coalesces many records into one SQLite flush', () async {
    final s = NetworkUsageStore(
      db,
      now: () => now,
      flushInterval: const Duration(days: 1), // never timer-flush in this test
      flushEvery: 1000,
    );
    for (var i = 0; i < 50; i++) {
      await s.record(down: 10, hit: true, saved: 5);
    }
    // Still buffered — the table is empty until flush/stats.
    expect(await db.query('net_bucket'), isEmpty);

    final stats = await s.stats();
    expect(stats.hits24h, 50);
    expect(stats.saved24h, 250);
    expect(stats.last24h, 500);
  });

  test('history returns every hour of the window, zero-filled', () async {
    now = DateTime.utc(2026, 1, 10, 12, 30); // current hour bucket = 12
    final s = store();
    await s.record(down: 1000, hit: false, saved: 0); // hour 12
    now = now.subtract(const Duration(hours: 3)); // 09:30 → hour 9
    await s.record(down: 0, hit: true, saved: 800); // hour 9
    now = now.add(const Duration(hours: 3));

    final history = await s.history(hours: 4);
    expect(history, hasLength(4));
    expect(history[0].saved, 800, reason: 'the 09:00 hit lands in its slot');
    expect(history[0].down, 0);
    expect(history[1].down, 0, reason: 'the 10:00 gap hour is a zero bar');
    expect(history[1].saved, 0);
    expect(history[2].down, 0, reason: 'the 11:00 gap hour is a zero bar');
    expect(history[3].down, 1000, reason: 'the 12:00 miss lands in its slot');
    expect(history[3].saved, 0);
    // Oldest first, ascending UTC epoch hours.
    expect(
      [for (final h in history) h.hour],
      List.generate(4, (i) => history.first.hour + i),
    );
  });
}
