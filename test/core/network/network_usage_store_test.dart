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
    expect(s.total, 0);
    expect(s.hitRate, 0);
  });

  test('records downloads, hits, misses, and saved bytes', () async {
    final s = store();
    await s.record(down: 1000, hit: false, saved: 0);
    await s.record(down: 500, hit: false, saved: 0);
    await s.record(down: 0, hit: true, saved: 800);

    final stats = await s.stats();
    expect(stats.last24h, 1500);
    expect(stats.last7d, 1500);
    expect(stats.misses, 2);
    expect(stats.hits, 1);
    expect(stats.savedBytes, 800);
    expect(stats.hitRate, closeTo(1 / 3, 1e-9));
  });

  test('24h and 7d windows exclude older buckets', () async {
    final s = store();
    await s.record(down: 1000, hit: false, saved: 0); // day 0

    now = now.add(const Duration(days: 2)); // day 2
    await s.record(down: 2000, hit: false, saved: 0);

    final stats = await s.stats();
    expect(
      stats.last24h,
      2000,
      reason: 'only the day-2 download is within 24h',
    );
    expect(stats.last7d, 3000, reason: 'both are within 7 days');
    expect(stats.misses, 2, reason: 'cumulative totals ignore the window');
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
      // Cumulative totals persist even after bucket eviction.
      expect(stats.misses, 2);
    },
  );
}
