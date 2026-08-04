import 'dart:async';

import 'package:sqflite/sqflite.dart';

/// A snapshot of network usage for the Debug page.
class NetworkUsage {
  const NetworkUsage({
    required this.last24h,
    required this.last7d,
    required this.saved24h,
    required this.saved7d,
    required this.hits,
    required this.misses,
  });

  /// Download bytes in the trailing 24 hours / 7 days.
  final int last24h;
  final int last7d;

  /// Bytes never re-downloaded thanks to the cache, over the same trailing
  /// windows as [last24h] / [last7d].
  ///
  /// Windowed rather than cumulative so it stays comparable with what was
  /// actually downloaded beside it — a lifetime total only ever grows, and next
  /// to a 24-hour download figure it says nothing about how the cache is doing
  /// now.
  final int saved24h;
  final int saved7d;

  /// ETag revalidations served from cache (`304`) vs full `200` downloads.
  final int hits;
  final int misses;

  int get total => hits + misses;

  /// Fraction of cacheable requests answered from cache (0 when none yet).
  double get hitRate => total == 0 ? 0 : hits / total;
}

/// Persisted network-usage accounting backed by the shared SQLite database.
///
/// Downloaded **and** saved bytes accumulate into **hourly buckets** so the
/// Debug page can sum a trailing 24-hour / 7-day window; buckets older than 7
/// days are swept on each flush (a sliding window — old data ages out on its
/// own). ETag hit/miss counts are kept as running totals (never swept).
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

  /// Downloaded / saved bytes keyed by hour bucket at [record] time (not flush
  /// time).
  final Map<int, int> _pendingDownByHour = {};
  final Map<int, int> _pendingSavedByHour = {};
  int _pendingHits = 0;
  int _pendingMisses = 0;
  int _pendingEvents = 0;
  Timer? _flushTimer;
  Future<void>? _flushing;

  /// Creates the usage tables (idempotent) — call on database open. Uses
  /// `IF NOT EXISTS` so it also adds the tables to a pre-existing cache database
  /// without a version bump.
  static Future<void> createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_buckets ('
      'hour INTEGER PRIMARY KEY, '
      'down INTEGER NOT NULL DEFAULT 0, '
      'saved INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_totals ('
      'k TEXT PRIMARY KEY, v INTEGER NOT NULL DEFAULT 0)',
    );
    await _addSavedColumn(db);
  }

  /// Adds `saved` to a bucket table created before it existed.
  ///
  /// [createSchema] runs on every open with `IF NOT EXISTS`, so an installed
  /// database never picks up a new column on its own. Saved bytes used to be a
  /// lifetime running total in [_totals]; that row is dropped here, because a
  /// number that only grows can't be windowed after the fact and leaving it
  /// would just be a second, contradictory answer.
  static Future<void> _addSavedColumn(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info($_buckets)');
      if (columns.any((c) => c['name'] == 'saved')) return;
      await db.execute(
        'ALTER TABLE $_buckets ADD COLUMN saved INTEGER NOT NULL DEFAULT 0',
      );
      await db.delete(_totals, where: 'k = ?', whereArgs: ['saved']);
    } catch (_) {
      // Accounting is diagnostic-only; never break the open on it.
    }
  }

  /// Queues one cacheable response for a coalesced flush: [down] bytes
  /// downloaded, whether it was a cache [hit] (`304`), and the bytes [saved] by
  /// that hit. Completes when the event is buffered (not when SQLite lands).
  Future<void> record({
    required int down,
    required bool hit,
    required int saved,
  }) async {
    final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
    if (down > 0) {
      _pendingDownByHour[hour] = (_pendingDownByHour[hour] ?? 0) + down;
    }
    if (saved > 0) {
      _pendingSavedByHour[hour] = (_pendingSavedByHour[hour] ?? 0) + saved;
    }
    if (hit) {
      _pendingHits += 1;
    } else {
      _pendingMisses += 1;
    }
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
      _pendingSavedByHour.isNotEmpty ||
      _pendingHits > 0 ||
      _pendingMisses > 0;

  Future<void> _flushBody() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    final downs = Map<int, int>.of(_pendingDownByHour);
    final saves = Map<int, int>.of(_pendingSavedByHour);
    final hits = _pendingHits;
    final misses = _pendingMisses;
    if (downs.isEmpty && saves.isEmpty && hits == 0 && misses == 0) return;

    _pendingDownByHour.clear();
    _pendingSavedByHour.clear();
    _pendingHits = 0;
    _pendingMisses = 0;
    _pendingEvents = 0;

    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      await _db.transaction((txn) async {
        for (final e in downs.entries) {
          await _addToBucket(txn, e.key, down: e.value);
        }
        for (final e in saves.entries) {
          await _addToBucket(txn, e.key, saved: e.value);
        }
        if (hits > 0) await _bump(txn, 'hits', hits);
        if (misses > 0) await _bump(txn, 'misses', misses);
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
        last24h: await _sumSince('down', hour - 24),
        last7d: await _sumSince('down', hour - _windowHours),
        saved24h: await _sumSince('saved', hour - 24),
        saved7d: await _sumSince('saved', hour - _windowHours),
        hits: await _readTotal('hits'),
        misses: await _readTotal('misses'),
      );
    } catch (_) {
      return const NetworkUsage(
        last24h: 0,
        last7d: 0,
        saved24h: 0,
        saved7d: 0,
        hits: 0,
        misses: 0,
      );
    }
  }

  // Update-then-insert instead of UPSERT, so it works on any bundled SQLite.
  Future<void> _addToBucket(
    DatabaseExecutor db,
    int hour, {
    int down = 0,
    int saved = 0,
  }) async {
    final updated = await db.rawUpdate(
      'UPDATE $_buckets SET down = down + ?, saved = saved + ? WHERE hour = ?',
      [down, saved, hour],
    );
    if (updated == 0) {
      await db.insert(_buckets, {'hour': hour, 'down': down, 'saved': saved});
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

  Future<int> _sumSince(String column, int sinceHour) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM($column), 0) AS b FROM $_buckets WHERE hour >= ?',
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
