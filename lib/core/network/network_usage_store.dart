import 'package:sqflite/sqflite.dart';

/// A snapshot of network usage for the Debug page.
class NetworkUsage {
  const NetworkUsage({
    required this.last24h,
    required this.last7d,
    required this.hits,
    required this.misses,
    required this.savedBytes,
  });

  /// Download bytes in the trailing 24 hours / 7 days.
  final int last24h;
  final int last7d;

  /// ETag revalidations served from cache (`304`) vs full `200` downloads.
  final int hits;
  final int misses;

  /// Cumulative bytes never re-downloaded thanks to `304`s.
  final int savedBytes;

  int get total => hits + misses;

  /// Fraction of cacheable requests answered from cache (0 when none yet).
  double get hitRate => total == 0 ? 0 : hits / total;
}

/// Persisted network-usage accounting backed by the shared SQLite database.
///
/// Download bytes accumulate into **hourly buckets** so the Debug page can sum a
/// trailing 24-hour / 7-day window; buckets older than 7 days are swept on each
/// write (a sliding window — old data ages out on its own). ETag hit/miss counts
/// and the cumulative traffic saved by `304`s are kept as running totals (never
/// swept). All operations are best-effort: any error is swallowed — accounting
/// must never break a request. Fed by [EtagInterceptor].
class NetworkUsageStore {
  NetworkUsageStore(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Database _db;

  /// Injectable clock — the wall time used to bucket and window usage.
  final DateTime Function() _now;

  static const String _buckets = 'net_bucket';
  static const String _totals = 'net_total';
  static const int _hourMs = 3600 * 1000;
  static const int _windowHours = 24 * 7;

  /// Creates the usage tables (idempotent) — call on database open. Uses
  /// `IF NOT EXISTS` so it also adds the tables to a pre-existing cache database
  /// without a version bump.
  static Future<void> createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_buckets ('
      'hour INTEGER PRIMARY KEY, down INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_totals ('
      'k TEXT PRIMARY KEY, v INTEGER NOT NULL DEFAULT 0)',
    );
  }

  /// Records one cacheable response: [down] bytes downloaded, whether it was a
  /// cache [hit] (`304`), and the bytes [saved] by that hit. Best-effort.
  Future<void> record({
    required int down,
    required bool hit,
    required int saved,
  }) async {
    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      if (down > 0) await _addToBucket(hour, down);
      await _bump(hit ? 'hits' : 'misses', 1);
      if (saved > 0) await _bump('saved', saved);
      // Sliding window: drop buckets older than 7 days.
      await _db.delete(
        _buckets,
        where: 'hour < ?',
        whereArgs: [hour - _windowHours],
      );
    } catch (_) {
      // Accounting is diagnostic-only; never surface a failure.
    }
  }

  /// The current usage snapshot. Best-effort: zeros on error.
  Future<NetworkUsage> stats() async {
    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      return NetworkUsage(
        last24h: await _sumSince(hour - 24),
        last7d: await _sumSince(hour - _windowHours),
        hits: await _readTotal('hits'),
        misses: await _readTotal('misses'),
        savedBytes: await _readTotal('saved'),
      );
    } catch (_) {
      return const NetworkUsage(
        last24h: 0,
        last7d: 0,
        hits: 0,
        misses: 0,
        savedBytes: 0,
      );
    }
  }

  // Update-then-insert instead of UPSERT, so it works on any bundled SQLite.
  Future<void> _addToBucket(int hour, int down) async {
    final updated = await _db.rawUpdate(
      'UPDATE $_buckets SET down = down + ? WHERE hour = ?',
      [down, hour],
    );
    if (updated == 0) {
      await _db.insert(_buckets, {'hour': hour, 'down': down});
    }
  }

  Future<void> _bump(String key, int by) async {
    final updated = await _db.rawUpdate(
      'UPDATE $_totals SET v = v + ? WHERE k = ?',
      [by, key],
    );
    if (updated == 0) {
      await _db.insert(_totals, {'k': key, 'v': by});
    }
  }

  Future<int> _sumSince(int sinceHour) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(down), 0) AS b FROM $_buckets WHERE hour >= ?',
      [sinceHour],
    );
    return (rows.first['b'] as num).toInt();
  }

  Future<int> _readTotal(String key) async {
    final rows = await _db.query(
      _totals,
      columns: ['v'],
      where: 'k = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? 0 : (rows.first['v'] as num).toInt();
  }
}
