import 'dart:async';

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
/// flush (a sliding window — old data ages out on its own). ETag hit/miss counts
/// and the cumulative traffic saved by `304`s are kept as running totals (never
/// swept).
///
/// Hot-path [record] only mutates an in-memory pending aggregate and schedules a
/// coalesced [flush] (timer and/or event count) so tile storms don't hammer
/// SQLite. [stats] always flushes first. All operations are best-effort: any
/// error is swallowed — accounting must never break a request. Binary cache hits
/// are fed by [EtagCacheStore]; misses and JSON `304`s by [EtagInterceptor] /
/// MapLibre put.
class NetworkUsageStore {
  NetworkUsageStore(
    this._db, {
    DateTime Function()? now,
    this.flushInterval = const Duration(seconds: 2),
    this.flushEvery = 64,
  }) : _now = now ?? DateTime.now;

  final Database _db;

  /// Injectable clock — the wall time used to bucket and window usage.
  final DateTime Function() _now;

  /// Max delay before a non-empty pending aggregate is written.
  final Duration flushInterval;

  /// Force a flush once this many [record] events are pending.
  final int flushEvery;

  static const String _buckets = 'net_bucket';
  static const String _totals = 'net_total';
  static const int _hourMs = 3600 * 1000;
  static const int _windowHours = 24 * 7;

  /// Download bytes keyed by hour bucket at [record] time (not flush time).
  final Map<int, int> _pendingDownByHour = {};
  int _pendingHits = 0;
  int _pendingMisses = 0;
  int _pendingSaved = 0;
  int _pendingEvents = 0;
  Timer? _flushTimer;
  Future<void>? _flushing;

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

  /// Queues one cacheable response for a coalesced flush: [down] bytes
  /// downloaded, whether it was a cache [hit] (`304`), and the bytes [saved] by
  /// that hit. Completes when the event is buffered (not when SQLite lands).
  Future<void> record({
    required int down,
    required bool hit,
    required int saved,
  }) async {
    if (down > 0) {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      _pendingDownByHour[hour] = (_pendingDownByHour[hour] ?? 0) + down;
    }
    if (hit) {
      _pendingHits += 1;
    } else {
      _pendingMisses += 1;
    }
    _pendingSaved += saved;
    _pendingEvents += 1;
    if (_pendingEvents >= flushEvery) {
      unawaited(flush());
    } else {
      _flushTimer ??= Timer(flushInterval, () {
        _flushTimer = null;
        unawaited(flush());
      });
    }
  }

  /// Writes any pending aggregate into SQLite (one transaction). Idempotent.
  /// Drains again if [record] raced the flush.
  Future<void> flush() async {
    while (true) {
      final inFlight = _flushing;
      if (inFlight != null) {
        await inFlight;
        if (!_hasPending) return;
        continue;
      }
      if (!_hasPending) return;
      final done = _flushBody();
      _flushing = done.whenComplete(() => _flushing = null);
      await done;
      if (!_hasPending) return;
    }
  }

  bool get _hasPending =>
      _pendingDownByHour.isNotEmpty ||
      _pendingHits > 0 ||
      _pendingMisses > 0 ||
      _pendingSaved > 0;

  Future<void> _flushBody() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    final downs = Map<int, int>.of(_pendingDownByHour);
    final hits = _pendingHits;
    final misses = _pendingMisses;
    final saved = _pendingSaved;
    if (downs.isEmpty && hits == 0 && misses == 0 && saved == 0) return;

    _pendingDownByHour.clear();
    _pendingHits = 0;
    _pendingMisses = 0;
    _pendingSaved = 0;
    _pendingEvents = 0;

    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      await _db.transaction((txn) async {
        for (final e in downs.entries) {
          await _addToBucket(txn, e.key, e.value);
        }
        if (hits > 0) await _bump(txn, 'hits', hits);
        if (misses > 0) await _bump(txn, 'misses', misses);
        if (saved > 0) await _bump(txn, 'saved', saved);
        await txn.delete(
          _buckets,
          where: 'hour < ?',
          whereArgs: [hour - _windowHours],
        );
      });
    } catch (_) {
      // Accounting is diagnostic-only; never surface a failure.
    }
  }

  /// The current usage snapshot (flushes pending first). Best-effort: zeros on
  /// error.
  Future<NetworkUsage> stats() async {
    await flush();
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
  Future<void> _addToBucket(DatabaseExecutor db, int hour, int down) async {
    final updated = await db.rawUpdate(
      'UPDATE $_buckets SET down = down + ? WHERE hour = ?',
      [down, hour],
    );
    if (updated == 0) {
      await db.insert(_buckets, {'hour': hour, 'down': down});
    }
  }

  Future<void> _bump(DatabaseExecutor db, String key, int by) async {
    final updated = await db.rawUpdate(
      'UPDATE $_totals SET v = v + ? WHERE k = ?',
      [by, key],
    );
    if (updated == 0) {
      await db.insert(_totals, {'k': key, 'v': by});
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
