import 'dart:async';

import 'package:sqflite/sqflite.dart';

/// A snapshot of network usage for the Debug page.
///
/// Every figure is a **trailing window**, never a lifetime total. A cumulative
/// number only ever grows, so beside a 24-hour download figure it says nothing
/// about how the cache is doing now — and once recorded it can't be windowed
/// after the fact.
class NetworkUsage {
  const NetworkUsage({
    required this.last24h,
    required this.last7d,
    required this.saved24h,
    required this.saved7d,
    required this.hits24h,
    required this.misses24h,
    required this.hits7d,
    required this.misses7d,
  });

  const NetworkUsage.empty()
    : last24h = 0,
      last7d = 0,
      saved24h = 0,
      saved7d = 0,
      hits24h = 0,
      misses24h = 0,
      hits7d = 0,
      misses7d = 0;

  /// Download bytes in the trailing 24 hours / 7 days.
  final int last24h;
  final int last7d;

  /// Bytes never re-downloaded thanks to the cache, over the same windows.
  final int saved24h;
  final int saved7d;

  /// Requests answered from cache vs fetched, over the same windows.
  final int hits24h;
  final int misses24h;
  final int hits7d;
  final int misses7d;

  int get total24h => hits24h + misses24h;
  int get total7d => hits7d + misses7d;

  /// Fraction of cacheable requests answered from cache (0 when none yet).
  double get hitRate24h => total24h == 0 ? 0 : hits24h / total24h;
  double get hitRate7d => total7d == 0 ? 0 : hits7d / total7d;
}

/// One hour's pending aggregate, before it reaches SQLite.
class _Pending {
  int down = 0;
  int saved = 0;
  int hits = 0;
  int misses = 0;
}

/// One hour's recorded usage — the granularity the Debug page's trend chart
/// plots.
class HourUsage {
  const HourUsage({
    required this.hour,
    required this.down,
    required this.saved,
    required this.hits,
    required this.misses,
  });

  /// UTC epoch hour — the same key the store buckets by.
  final int hour;
  final int down;
  final int saved;
  final int hits;
  final int misses;
}

/// Persisted network-usage accounting backed by the shared SQLite database.
///
/// Everything — bytes downloaded, bytes saved, and cache hits / misses —
/// accumulates into **hourly buckets**, so the Debug page can sum any trailing
/// window and buckets older than 7 days are swept on each flush (a sliding
/// window: old data ages out on its own, and the table can't grow without
/// bound).
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

  static const int _hourMs = 3600 * 1000;
  static const int _windowHours = 24 * 7;

  /// Every counter the bucket table carries.
  static const List<String> _columns = ['down', 'saved', 'hits', 'misses'];

  /// Aggregates keyed by hour bucket at [record] time (not flush time).
  final Map<int, _Pending> _pendingByHour = {};
  int _pendingEvents = 0;
  Timer? _flushTimer;
  Future<void>? _flushing;

  /// Creates the usage table (idempotent) — call on database open. Uses
  /// `IF NOT EXISTS` so it also adds the table to a pre-existing cache database
  /// without a version bump, then migrates an older shape in place.
  static Future<void> createSchema(Database db) async {
    final defs = _columns
        .map((c) => '$c INTEGER NOT NULL DEFAULT 0')
        .join(', ');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_buckets (hour INTEGER PRIMARY KEY, $defs)',
    );
    await _migrate(db);
  }

  /// Brings a bucket table created by an older build up to date.
  ///
  /// [createSchema] runs on every open with `IF NOT EXISTS`, so an installed
  /// database never picks up new columns on its own.
  static Future<void> _migrate(Database db) async {
    try {
      final existing = {
        for (final row in await db.rawQuery('PRAGMA table_info($_buckets)'))
          row['name'] as String,
      };
      for (final column in _columns) {
        if (existing.contains(column)) continue;
        await db.execute(
          'ALTER TABLE $_buckets ADD COLUMN $column INTEGER NOT NULL DEFAULT 0',
        );
      }
    } catch (_) {
      // Accounting is diagnostic-only; never break the open on it.
    }
  }

  /// Queues [count] cacheable responses for a coalesced flush: [down] bytes
  /// downloaded between them, whether they were cache [hit]s, and the bytes
  /// [saved] by those hits. Completes when the event is buffered (not when
  /// SQLite lands).
  ///
  /// [count] is what lets a tile batch be one call. A viewport served from
  /// cache is dozens of identical hits, and recording them one at a time
  /// re-crossed [flushEvery] mid-batch — a `net_bucket` transaction, plus its
  /// 7-day sweep, per 64 tiles. The aggregate written is the same sum either
  /// way.
  Future<void> record({
    required int down,
    required bool hit,
    required int saved,
    int count = 1,
  }) async {
    final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
    final pending = _pendingByHour.putIfAbsent(hour, _Pending.new);
    pending.down += down;
    pending.saved += saved;
    if (hit) {
      pending.hits += count;
    } else {
      pending.misses += count;
    }
    _pendingEvents += count;
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
        if (_pendingByHour.isEmpty) return;
        continue;
      }
      if (_pendingByHour.isEmpty) return;
      final done = _flushBody();
      _flushing = done.whenComplete(() => _flushing = null);
      await done;
      if (_pendingByHour.isEmpty) return;
    }
  }

  Future<void> _flushBody() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingByHour.isEmpty) return;

    final pending = Map<int, _Pending>.of(_pendingByHour);
    _pendingByHour.clear();
    _pendingEvents = 0;

    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      await _db.transaction((txn) async {
        for (final entry in pending.entries) {
          await _addToBucket(txn, entry.key, entry.value);
        }
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

  /// Drops every recorded bucket and anything still buffered.
  ///
  /// The pending aggregate has to go too: it is what a flush would write next,
  /// so leaving it would let the counters reappear a second or two after the
  /// user watched them reset.
  Future<void> clear() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingByHour.clear();
    _pendingEvents = 0;
    try {
      await _db.delete(_buckets);
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
      final day = await _sumSince(hour - 24);
      final week = await _sumSince(hour - _windowHours);
      return NetworkUsage(
        last24h: day.down,
        last7d: week.down,
        saved24h: day.saved,
        saved7d: week.saved,
        hits24h: day.hits,
        misses24h: day.misses,
        hits7d: week.hits,
        misses7d: week.misses,
      );
    } catch (_) {
      return const NetworkUsage.empty();
    }
  }

  /// Usage over the trailing window, oldest first — the trend series for the
  /// Debug page's chart.
  ///
  /// [hours] is the window length and [bucketHours] how many hours each sample
  /// aggregates, so `history()` gives 24 hourly points and
  /// `history(hours: 24 * 7, bucketHours: 6)` gives 28 six-hour points for the
  /// 7-day view. Every slot in the window is present: a silent bucket is a
  /// zero bar, not a gap, so the chart stays continuous. Best-effort: empty on
  /// error.
  Future<List<HourUsage>> history({int hours = 24, int bucketHours = 1}) async {
    await flush();
    try {
      final hour = _now().millisecondsSinceEpoch ~/ _hourMs;
      final bucket = hour ~/ bucketHours;
      final count = hours ~/ bucketHours;
      final rows = await _db.rawQuery(
        'SELECT hour / ? AS bucket, '
        'COALESCE(SUM(down), 0) AS down, '
        'COALESCE(SUM(saved), 0) AS saved, '
        'COALESCE(SUM(hits), 0) AS hits, '
        'COALESCE(SUM(misses), 0) AS misses '
        'FROM $_buckets WHERE hour >= ? '
        'GROUP BY bucket ORDER BY bucket',
        [bucketHours, (bucket - count + 1) * bucketHours],
      );
      final byBucket = <int, Map<String, Object?>>{
        for (final row in rows) row['bucket'] as int: row,
      };
      return [
        for (var b = bucket - count + 1; b <= bucket; b++)
          HourUsage(
            hour: b * bucketHours,
            down: _counter(byBucket[b]?['down']),
            saved: _counter(byBucket[b]?['saved']),
            hits: _counter(byBucket[b]?['hits']),
            misses: _counter(byBucket[b]?['misses']),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static int _counter(Object? value) => (value as num?)?.toInt() ?? 0;

  // Update-then-insert instead of UPSERT, so it works on any bundled SQLite.
  Future<void> _addToBucket(DatabaseExecutor db, int hour, _Pending add) async {
    final sets = _columns.map((c) => '$c = $c + ?').join(', ');
    final values = [add.down, add.saved, add.hits, add.misses];
    final updated = await db.rawUpdate(
      'UPDATE $_buckets SET $sets WHERE hour = ?',
      [...values, hour],
    );
    if (updated == 0) {
      await db.insert(_buckets, {
        'hour': hour,
        for (var i = 0; i < _columns.length; i++) _columns[i]: values[i],
      });
    }
  }

  /// Sums every counter over one trailing window in a single query.
  Future<_Pending> _sumSince(int sinceHour) async {
    final sums = _columns.map((c) => 'COALESCE(SUM($c), 0) AS $c').join(', ');
    final rows = await _db.rawQuery(
      'SELECT $sums FROM $_buckets WHERE hour >= ?',
      [sinceHour],
    );
    final row = rows.first;
    return _Pending()
      ..down = (row['down'] as num).toInt()
      ..saved = (row['saved'] as num).toInt()
      ..hits = (row['hits'] as num).toInt()
      ..misses = (row['misses'] as num).toInt();
  }
}
