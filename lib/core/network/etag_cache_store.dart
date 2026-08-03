/// On-disk ETag response cache backed by **SQLite**.
///
/// Schema v2 stores JSON and binary as body blobs (no gzip-of-JSON-of-base64
/// envelope):
/// - **JSON** — always gzip-1.
/// - **Binary** — gzip-1 whenever it shrinks: basemap PBF / MVT / protobuf /
///   PDF / text / SVG / … Already entropy-packed formats (WebP / JPEG / PNG /
///   zip / woff / …) stay raw — outer gzip is a no-op or expands them.
///
/// Hot path is SQLite only — no Dart-side decoded LRU. Repeated reads rely on
/// SQLite's pager / page cache (see [configureConnection], ~25 MiB).
///
/// Eviction: last-used (`time`) older than [maxAge], then LRU trim to
/// [maxBytes]. Last-used bumps are **buffered** and flushed in batches (same
/// idea as [NetworkUsageStore]) so tile storms don't UPDATE one row per hit.
/// All ops best-effort.
///
/// When a [NetworkUsageStore] is wired, every successful [readBytes] serve
/// records one hit + saved wire bytes — callers must not also meter those
/// serves.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dpip/core/network/network_usage_store.dart';
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
    this._usage,
  });

  final Database _db;

  /// Optional traffic accounting for binary [readBytes] hits. Callers must not
  /// also [NetworkUsageStore.record] those serves — misses / JSON `304`s stay
  /// at the interceptor / MapLibre put path.
  final NetworkUsageStore? _usage;

  /// Entries whose **last-used** is older than this are swept on the next write.
  final Duration maxAge;

  /// Soft ceiling on `SUM(LENGTH(body))` — least-recently-used rows drop first.
  final int maxBytes;

  /// Default size budget (~150 MB of body blobs on disk).
  static const int defaultMaxBytes = 150 * 1024 * 1024;

  /// SQLite page-cache size in kibibytes (negative PRAGMA = KiB, not pages).
  static const int defaultPageCacheKiB = 25 * 1024;

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

  /// Pending last-used bumps — coalesced into batched `UPDATE … IN (…)`.
  final Set<String> _pendingTouch = {};
  Timer? _touchTimer;
  Future<void>? _touchFlushing;

  static const _touchFlushInterval = Duration(milliseconds: 500);
  static const _touchFlushEvery = 48;
  static const _touchInChunk = 64;

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

  /// Connection-level SQLite knobs for hot tile reads (page cache + mmap).
  /// Call once after [openDatabase].
  static Future<void> configureConnection(
    Database db, {
    int pageCacheKiB = defaultPageCacheKiB,
  }) async {
    // PRAGMAs that return a row must use [rawQuery] — on Darwin, [execute]
    // treats the result as an error ("not an error") and would abort bootstrap
    // into "ETag cache unavailable".
    // Negative cache_size = kibibytes reserved for the pager (~25 MiB default).
    await db.rawQuery('PRAGMA cache_size = -$pageCacheKiB');
    await db.rawQuery('PRAGMA mmap_size = ${64 * 1024 * 1024}');
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
      _scheduleTouch(url);
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
  /// Reads SQLite (inflate when [kindBinaryGzip]). Every successful serve is
  /// metered once via [_usage] when wired. [touch] schedules an async last-used
  /// bump.
  Future<CachedBytes?> readBytes(String url, {bool touch = true}) async {
    try {
      final row = await _queryRow(url);
      if (row == null) return null;
      final kind = row['kind'] as int;
      if (kind != kindBinary && kind != kindBinaryGzip) return null;
      if (touch) _scheduleTouch(url);
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
      _recordBinaryHit(entry);
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
      final rows = await _db.query(
        _table,
        columns: ['etag'],
        where: 'key = ?',
        whereArgs: [url],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      _scheduleTouch(url);
      return rows.first['etag'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Bumps last-used for [url] without reading the body (awaits the flush so
  /// callers that trim by LRU see the updated `time`).
  Future<void> touch(String url) {
    _pendingTouch.add(url);
    return _flushTouches();
  }

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
  /// that shrinks them; entropy-packed formats (WebP / JPEG / …) stay raw.
  Future<void> writeBytes(
    String url, {
    required String etag,
    required Uint8List bytes,
    String? contentType,
    int size = 0,
  }) async {
    final entrySize = size > 0 ? size : bytes.length;
    try {
      final encoded = await _encodeBinary(bytes, contentType);
      await _insert(
        url,
        etag: etag,
        contentType: contentType,
        kind: encoded.kind,
        body: encoded.body,
        size: entrySize,
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
    // LRU / age sweeps read `time` — land buffered touches first.
    await _flushTouches();
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
  }

  /// Deletes every cached entry.
  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } catch (_) {}
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

  void _recordBinaryHit(CachedBytes entry) {
    final usage = _usage;
    if (usage == null) return;
    unawaited(usage.record(down: 0, hit: true, saved: entry.size));
  }

  void _scheduleTouch(String url) {
    _pendingTouch.add(url);
    if (_pendingTouch.length >= _touchFlushEvery) {
      unawaited(_flushTouches());
      return;
    }
    _touchTimer ??= Timer(_touchFlushInterval, () {
      _touchTimer = null;
      unawaited(_flushTouches());
    });
  }

  Future<void> _flushTouches() async {
    while (true) {
      final inFlight = _touchFlushing;
      if (inFlight != null) {
        await inFlight;
        if (_pendingTouch.isEmpty) return;
        continue;
      }
      if (_pendingTouch.isEmpty) return;
      final done = _flushTouchesBody();
      _touchFlushing = done.whenComplete(() => _touchFlushing = null);
      await done;
      if (_pendingTouch.isEmpty) return;
    }
  }

  Future<void> _flushTouchesBody() async {
    _touchTimer?.cancel();
    _touchTimer = null;
    if (_pendingTouch.isEmpty) return;

    final urls = _pendingTouch.toList(growable: false);
    _pendingTouch.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _db.transaction((txn) async {
        for (var i = 0; i < urls.length; i += _touchInChunk) {
          final end = i + _touchInChunk;
          final chunk = end < urls.length
              ? urls.sublist(i, end)
              : urls.sublist(i);
          final placeholders = List.filled(chunk.length, '?').join(',');
          await txn.rawUpdate(
            'UPDATE $_table SET time = ? WHERE key IN ($placeholders)',
            [now, ...chunk],
          );
        }
      });
    } catch (_) {}
  }
}
