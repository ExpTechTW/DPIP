/// On-disk ETag response cache backed by **SQLite**.
///
/// Schema v2 stores JSON and binary in separate columns (no gzip-of-JSON-of-
/// base64 envelope). Tile bodies are already compressed (WebP / PBF / MVT), so
/// an outer gzip was pure CPU tax on every hit.
///
/// Hot path:
/// 1. **Memory LRU** (~48 MB decoded binary) — zero I/O.
/// 2. **SQLite** row → body blob (binary = raw bytes; JSON = utf8).
/// 3. Optional **isolate** inflate for any leftover v1 envelopes (migration).
///
/// Eviction: last-used (`time`) older than [maxAge], then LRU trim to
/// [maxBytes]. Touch is async. All ops best-effort.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

/// A cached HTTP response: the server [etag] to revalidate with, the response
/// [body] (the JSON-encoded payload), its [contentType], and [size] — the wire
/// bytes the original download cost (so a `304` can report the traffic saved).
class CachedResponse {
  const CachedResponse({
    required this.etag,
    required this.body,
    this.contentType,
    this.size = 0,
  });

  final String etag;
  final String body;
  final String? contentType;
  final int size;
}

/// A cached binary HTTP response (MVT, WebP, …).
class CachedBytes {
  const CachedBytes({
    required this.etag,
    required this.bytes,
    this.contentType,
    this.size = 0,
  });

  final String etag;
  final Uint8List bytes;
  final String? contentType;
  final int size;
}

/// Row count and stored byte size of the ETag cache (for the Debug page).
typedef EtagCacheStats = ({int rows, int bytes});

/// See library doc.
class EtagCacheStore {
  EtagCacheStore(
    this._db, {
    this.maxAge = const Duration(days: 7),
    this.maxBytes = defaultMaxBytes,
    this.memoryMaxBytes = defaultMemoryMaxBytes,
  });

  final Database _db;

  /// Entries whose **last-used** is older than this are swept on the next write.
  final Duration maxAge;

  /// Soft ceiling on `SUM(LENGTH(body))` — least-recently-used rows drop first.
  final int maxBytes;

  /// In-process decoded-binary ceiling (LRU).
  final int memoryMaxBytes;

  /// Default size budget (~150 MB of body blobs on disk).
  static const int defaultMaxBytes = 150 * 1024 * 1024;

  /// Default memory LRU (~48 MB of decoded tile bytes).
  static const int defaultMemoryMaxBytes = 48 * 1024 * 1024;

  static const String _table = 'http_cache';
  static const int kindJson = 0;
  static const int kindBinary = 1;

  /// Insertion-ordered LRU of decoded binary tiles.
  final LinkedHashMap<String, CachedBytes> _memory = LinkedHashMap();
  int _memoryBytes = 0;

  /// Creates the v2 cache table (idempotent) — call from `onCreate` / migrate.
  static Future<void> createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_table ('
      'key TEXT PRIMARY KEY, '
      'etag TEXT NOT NULL, '
      'content_type TEXT, '
      'kind INTEGER NOT NULL, '
      'body BLOB NOT NULL, '
      'size INTEGER NOT NULL, '
      'time INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ${_table}_time ON $_table(time)',
    );
  }

  /// Migrates v1 (single `value` blob envelope) → v2 columnar schema.
  /// Drops the old table (one-time cold miss) — simpler and safer than parsing
  /// every legacy row on the UI isolate.
  static Future<void> migrateToV2(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $_table');
    await createSchema(db);
  }

  /// Returns the cached **JSON** entry for [url], or null on a miss.
  Future<CachedResponse?> read(String url) async {
    try {
      final row = await _queryRow(url);
      if (row == null || (row['kind'] as int) != kindJson) return null;
      unawaited(_touch(url));
      final bodyBlob = row['body'] as Uint8List;
      final body = await _decodeJsonBody(bodyBlob);
      return CachedResponse(
        etag: row['etag'] as String,
        body: body,
        contentType: row['content_type'] as String?,
        size: (row['size'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached **binary** entry for [url], or null on a miss.
  ///
  /// Hits the memory LRU first. [touch] schedules an async last-used bump.
  Future<CachedBytes?> readBytes(String url, {bool touch = true}) async {
    try {
      final mem = _memoryTake(url);
      if (mem != null) {
        if (touch) unawaited(_touch(url));
        return mem;
      }
      final row = await _queryRow(url);
      if (row == null || (row['kind'] as int) != kindBinary) return null;
      if (touch) unawaited(_touch(url));
      final bytes = row['body'] as Uint8List;
      final entry = CachedBytes(
        etag: row['etag'] as String,
        // SQLite may return a view — copy so callers can retain across awaits.
        bytes: Uint8List.fromList(bytes),
        contentType: row['content_type'] as String?,
        size: (row['size'] as num).toInt(),
      );
      _memoryPut(url, entry);
      return entry;
    } catch (_) {
      return null;
    }
  }

  /// Parallel binary reads — each SQLite fetch then decode/copy can overlap
  /// via [Future.wait] (useful when warming a viewport).
  Future<List<CachedBytes?>> readBytesMany(
    List<String> urls, {
    bool touch = true,
  }) => Future.wait([for (final u in urls) readBytes(u, touch: touch)]);

  /// Returns just the cached etag for [url], or null on a miss.
  Future<String?> readEtag(String url) async {
    try {
      final mem = _memory[url];
      if (mem != null) {
        unawaited(_touch(url));
        return mem.etag;
      }
      final rows = await _db.query(
        _table,
        columns: ['etag'],
        where: 'key = ?',
        whereArgs: [url],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      unawaited(_touch(url));
      return rows.first['etag'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Bumps last-used for [url] without reading the body.
  Future<void> touch(String url) => _touch(url);

  /// Stores a JSON [body] for [url] under [etag]. Best-effort.
  Future<void> write(
    String url, {
    required String etag,
    required String body,
    String? contentType,
    int size = 0,
  }) async {
    try {
      // Light gzip on a worker isolate so large JSON writes don't jank the UI.
      final blob = await Isolate.run(() {
        return Uint8List.fromList(
          GZipCodec(level: 1).encode(utf8.encode(body)),
        );
      });
      await _insert(
        url,
        etag: etag,
        contentType: contentType,
        kind: kindJson,
        body: blob,
        size: size,
      );
    } catch (_) {}
  }

  /// Stores raw [bytes] for [url] under [etag] (no re-compress). Best-effort.
  /// Populates the memory LRU immediately so the next hit skips SQLite.
  Future<void> writeBytes(
    String url, {
    required String etag,
    required Uint8List bytes,
    String? contentType,
    int size = 0,
  }) async {
    final entry = CachedBytes(
      etag: etag,
      bytes: bytes,
      contentType: contentType,
      size: size > 0 ? size : bytes.length,
    );
    _memoryPut(url, entry);
    try {
      await _insert(
        url,
        etag: etag,
        contentType: contentType,
        kind: kindBinary,
        body: bytes,
        size: entry.size,
      );
    } catch (_) {}
  }

  Future<void> _insert(
    String url, {
    required String etag,
    required String? contentType,
    required int kind,
    required Uint8List body,
    required int size,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.insert(_table, {
      'key': url,
      'etag': etag,
      'content_type': contentType,
      'kind': kind,
      'body': body,
      'size': size,
      'time': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _db.delete(
      _table,
      where: 'time < ?',
      whereArgs: [now - maxAge.inMilliseconds],
    );
    await _trimToMaxBytes();
  }

  Future<void> _trimToMaxBytes() async {
    if (maxBytes <= 0) {
      await _db.delete(_table);
      _memory.clear();
      _memoryBytes = 0;
      return;
    }
    final totalRows = await _db.rawQuery(
      'SELECT COALESCE(SUM(LENGTH(body)), 0) AS b FROM $_table',
    );
    var total = (totalRows.first['b'] as num).toInt();
    if (total <= maxBytes) return;

    final rows = await _db.rawQuery(
      'SELECT key, LENGTH(body) AS b FROM $_table ORDER BY time ASC',
    );
    final keys = <String>[];
    for (final row in rows) {
      if (total <= maxBytes) break;
      keys.add(row['key'] as String);
      total -= (row['b'] as num).toInt();
    }
    if (keys.isEmpty) return;
    await _db.delete(
      _table,
      where: 'key IN (${List.filled(keys.length, '?').join(',')})',
      whereArgs: keys,
    );
    for (final k in keys) {
      final evicted = _memory.remove(k);
      if (evicted != null) _memoryBytes -= evicted.bytes.length;
    }
  }

  /// Deletes every cached entry (disk + memory).
  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } catch (_) {}
    _memory.clear();
    _memoryBytes = 0;
  }

  /// Row count and total stored body bytes — for the Debug page.
  Future<EtagCacheStats> stats() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT COUNT(*) AS c, COALESCE(SUM(LENGTH(body)), 0) AS b FROM $_table',
      );
      final row = rows.first;
      return (
        rows: (row['c'] as num).toInt(),
        bytes: (row['b'] as num).toInt(),
      );
    } catch (_) {
      return (rows: 0, bytes: 0);
    }
  }

  Future<Map<String, Object?>?> _queryRow(String url) async {
    final rows = await _db.query(
      _table,
      where: 'key = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// JSON bodies are stored gzip-1; inflate off the UI isolate when large.
  static Future<String> _decodeJsonBody(Uint8List blob) async {
    if (blob.length >= 2 && blob[0] == 0x1f && blob[1] == 0x8b) {
      if (blob.length > 16 * 1024) {
        return Isolate.run(() => utf8.decode(gzip.decode(blob)));
      }
      return utf8.decode(gzip.decode(blob));
    }
    // Uncompressed fallback.
    return utf8.decode(blob);
  }

  CachedBytes? _memoryTake(String url) {
    final hit = _memory.remove(url);
    if (hit == null) return null;
    _memory[url] = hit; // MRU
    return hit;
  }

  void _memoryPut(String url, CachedBytes entry) {
    final existing = _memory.remove(url);
    if (existing != null) _memoryBytes -= existing.bytes.length;
    _memory[url] = entry;
    _memoryBytes += entry.bytes.length;
    while (_memoryBytes > memoryMaxBytes && _memory.isNotEmpty) {
      final evicted = _memory.remove(_memory.keys.first);
      if (evicted != null) _memoryBytes -= evicted.bytes.length;
    }
  }

  Future<void> _touch(String url) async {
    try {
      await _db.update(
        _table,
        {'time': DateTime.now().millisecondsSinceEpoch},
        where: 'key = ?',
        whereArgs: [url],
      );
    } catch (_) {}
  }
}
