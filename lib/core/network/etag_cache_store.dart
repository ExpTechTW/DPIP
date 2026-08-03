/// On-disk ETag response cache backed by **SQLite**.
///
/// Schema v2 stores JSON and binary as body blobs (no gzip-of-JSON-of-base64
/// envelope):
/// - **JSON** — always gzip-1.
/// - **Binary** — gzip-1 whenever it shrinks: basemap PBF / MVT / protobuf /
///   PDF / text / SVG / … Already entropy-packed formats (WebP / JPEG / PNG /
///   zip / woff / …) stay raw — outer gzip is a no-op or expands them.
///
/// Hot path:
/// 1. **Memory LRU** (~48 MB *decoded* binary) — zero I/O.
/// 2. **SQLite** row → inflate if [kindBinaryGzip], else raw copy.
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

  /// Binary body stored as gzip-1 of the decoded bytes (PBF / MVT / …).
  static const int kindBinaryGzip = 2;

  /// Content types that are already entropy-packed — never outer-gzip.
  /// (Vector tiles / protobuf are NOT here — raw PBF/MVT typically shrink ~40%.)
  static const _precompressedTypes = <String>{
    'application/gzip',
    'application/x-gzip',
    'application/zip',
    'application/x-zip-compressed',
    'application/wasm', // already LEB + often brotli on wire; leave raw
    'font/woff',
    'font/woff2',
  };

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
      if (row == null) return null;
      final kind = row['kind'] as int;
      if (kind != kindBinary && kind != kindBinaryGzip) return null;
      if (touch) unawaited(_touch(url));
      final blob = row['body'] as Uint8List;
      final bytes = kind == kindBinaryGzip
          ? await _gunzip(blob)
          : Uint8List.fromList(blob);
      final entry = CachedBytes(
        etag: row['etag'] as String,
        bytes: bytes,
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

  /// Stores [bytes] for [url] under [etag]. Best-effort.
  ///
  /// Compressible payloads (PBF / MVT / PDF / text / …) are gzip-1 on disk when
  /// that shrinks them; entropy-packed formats (WebP / JPEG / …) stay raw. The
  /// memory LRU always holds the decoded bytes so the next hit skips both
  /// SQLite and inflate.
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
      final encoded = await _encodeBinary(bytes, contentType);
      await _insert(
        url,
        etag: etag,
        contentType: contentType,
        kind: encoded.kind,
        body: encoded.body,
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

  /// Gzip-1 [bytes] when the type is compressible and the result shrinks;
  /// otherwise leave raw. Kind tells [readBytes] whether to inflate.
  static Future<({int kind, Uint8List body})> _encodeBinary(
    Uint8List bytes,
    String? contentType,
  ) async {
    if (!shouldGzipBinary(bytes, contentType)) {
      return (kind: kindBinary, body: bytes);
    }
    final compressed = bytes.length > 16 * 1024
        ? await Isolate.run(
            () => Uint8List.fromList(GZipCodec(level: 1).encode(bytes)),
          )
        : Uint8List.fromList(GZipCodec(level: 1).encode(bytes));
    if (compressed.length >= bytes.length) {
      return (kind: kindBinary, body: bytes);
    }
    return (kind: kindBinaryGzip, body: compressed);
  }

  static Future<Uint8List> _gunzip(Uint8List blob) async {
    if (blob.length > 16 * 1024) {
      return Isolate.run(() => Uint8List.fromList(gzip.decode(blob)));
    }
    return Uint8List.fromList(gzip.decode(blob));
  }

  /// Whether to *try* an outer gzip for this binary payload.
  ///
  /// Default is **yes** (basemap PBF is `application/octet-stream` and shrinks
  /// ~40%; MVT ~30%). Skip only when the type/magic is already packed (WebP /
  /// JPEG / PNG / zip / gzip / woff / video / audio). [_encodeBinary] still
  /// keeps the raw body if gzip does not shrink.
  static bool shouldGzipBinary(Uint8List bytes, String? contentType) {
    if (_looksPrecompressed(bytes)) return false;
    final ct = (contentType ?? '').split(';').first.trim().toLowerCase();
    if (ct.isEmpty) return true;
    if (_precompressedTypes.contains(ct)) return false;
    if (ct.startsWith('image/') && ct != 'image/svg+xml') return false;
    if (ct.startsWith('video/') || ct.startsWith('audio/')) return false;
    if (ct.startsWith('font/')) return false;
    return true;
  }

  static bool _looksPrecompressed(Uint8List b) {
    if (b.length < 3) return false;
    // gzip / zip / zstd — don't wrap again.
    if (b[0] == 0x1f && b[1] == 0x8b) return true;
    if (b[0] == 0x50 && b[1] == 0x4b) return true; // PK zip
    if (b.length >= 4 &&
        b[0] == 0x28 &&
        b[1] == 0xb5 &&
        b[2] == 0x2f &&
        b[3] == 0xfd) {
      return true; // zstd
    }
    // JPEG / PNG / GIF / WebP
    if (b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return true;
    if (b.length >= 4 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4e &&
        b[3] == 0x47) {
      return true;
    }
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return true; // GIF
    if (b.length >= 12 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return true; // RIFF....WEBP
    }
    return false;
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
