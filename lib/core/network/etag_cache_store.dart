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
/// **Tile storms are the design constraint.** A map viewport asks for dozens of
/// tiles at once, so the batch forms — [readBytesBatch] / [writeBytesBatch] —
/// are the real API: one `IN` query and one transaction per burst, with any
/// gzip work for the whole batch done in a single isolate hop rather than one
/// per row.
///
/// Eviction: byte budget only. Entries live until the store's total body size
/// passes [maxBytes]; then the least-recently-used rows drop, oldest (`time`)
/// first, until the total is back under the ceiling. Nothing expires by age —
/// a 30-day-old map tile that is still being hit keeps its slot. The byte
/// budget is **amortized**, because knowing the total means summing every blob
/// in the table — running that per tile written made a scrub quadratic on the
/// UI isolate. Last-used bumps are likewise **buffered** and flushed in
/// batches (same idea as [NetworkUsageStore]). All ops best-effort.
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
import 'package:sqlite_async/sqlite_async.dart';
import 'package:sqlite_async/native.dart';

/// A cached HTTP response: the server [etag] to revalidate with, the response
/// [body] (the JSON-encoded payload), its [contentType], and [size] — the wire
/// bytes the original download cost (so a `304` can report the traffic saved).
/// A revalidated JSON entry, already decoded — see [EtagCacheStore.readJson].
class CachedJson {
  const CachedJson({
    required this.etag,
    required this.data,
    required this.size,
  });

  final String etag;
  final Object? data;

  /// Wire bytes the original download cost — what a 304 reports as saved.
  final int size;
}

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

/// One pending binary write — the unit [EtagCacheStore.writeBytesBatch] takes.
typedef BinaryWrite = ({
  String url,
  String etag,
  Uint8List bytes,
  String? contentType,
  int size,
});

/// A [BinaryWrite] after compression, ready to insert.
typedef _EncodedWrite = ({
  String url,
  String etag,
  String? contentType,
  int kind,
  Uint8List body,
  int size,
});

/// See library doc.
class EtagCacheStore {
  EtagCacheStore(this._db, {this.maxBytes = defaultMaxBytes, this._usage}) {
    // Seed the monotonic LRU key from what is already stored, so a clock that
    // moved back between runs cannot make this session's writes sort under the
    // last session's. Best-effort: a failure only costs ordering, and the
    // first write re-establishes it.
    unawaited(
      _db
          .get('SELECT MAX(time) AS newest FROM $_table')
          .then((row) {
            final newest = (row['newest'] as num?)?.toInt() ?? 0;
            if (newest > _lastStamp) _lastStamp = newest;
          })
          .catchError((Object _) {}),
    );
  }

  final SqliteDatabase _db;

  /// Optional traffic accounting for binary [readBytes] hits. Callers must not
  /// also [NetworkUsageStore.record] those serves — misses / JSON `304`s stay
  /// at the interceptor / MapLibre put path.
  final NetworkUsageStore? _usage;

  /// Ceiling on `SUM(LENGTH(body))` — least-recently-used rows drop first,
  /// oldest (`time`) first, only once the store is over it. Entries never
  /// expire by age.
  final int maxBytes;

  /// Default size budget (~350 MB of body blobs on disk).
  static const int defaultMaxBytes = 350 * 1024 * 1024;

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

  /// Bound parameters per `IN (…)` — well under SQLite's variable limit.
  static const _readInChunk = 400;

  /// Rows written between byte-budget sweeps (see [_trimToBudget]).
  static const _sweepEvery = 96;

  /// Rows read per pass when picking eviction victims (see [_trimToBudget]).
  static const _trimScanChunk = 512;

  /// Compressed bytes above which a batch inflate is worth an isolate hop.
  static const _isolateThreshold = 64 * 1024;

  /// Running `SUM(LENGTH(body))`, seeded by the first trim. Replacements are
  /// counted as pure additions between sweeps, so this only ever over-estimates
  /// — which triggers a sweep early rather than letting the store overrun.
  int? _trackedBytes;
  int _writesSinceSweep = 0;

  static const _v2Columns = {
    'key',
    'etag',
    'content_type',
    'kind',
    'body',
    'size',
    'time',
  };

  /// Creates the v2 cache table, dropping an incompatible legacy cache first.
  ///
  /// v1 stored one `value` envelope instead of v2's columnar body. There is no
  /// data migration on purpose: every row is re-fetchable, so a clean drop is
  /// both safer and cheaper than decoding and rewriting hundreds of megabytes.
  static Future<void> createSchema(SqliteDatabase db) async {
    final columns = {
      for (final row in await db.getAll('PRAGMA table_info($_table)'))
        if (row['name'] case final String name) name,
    };
    if (columns.isNotEmpty && !columns.containsAll(_v2Columns)) {
      await migrateToV2(db);
      return;
    }
    await _createV2Schema(db);
  }

  static Future<void> _createV2Schema(SqliteDatabase db) async {
    await db.executeMultiple(
      'CREATE TABLE IF NOT EXISTS $_table ('
      'key TEXT PRIMARY KEY, '
      'etag TEXT NOT NULL, '
      'content_type TEXT, '
      'kind INTEGER NOT NULL, '
      'body BLOB NOT NULL, '
      'size INTEGER NOT NULL, '
      'time INTEGER NOT NULL);'
      'CREATE INDEX IF NOT EXISTS ${_table}_time ON $_table(time)',
    );
  }

  /// Connection-level SQLite knobs for hot tile reads.
  ///
  /// sqlite_async opens each pooled connection in its own background isolate,
  /// so per-connection PRAGMAs ride a [NativeSqliteOpenFactory] subclass whose
  /// [NativeSqliteOpenFactory.pragmaStatements] runs inside every opened
  /// connection — not once per database. Call instead of the plain
  /// [SqliteDatabase] constructor when opening this file.
  static SqliteDatabase open({
    required String path,
    int pageCacheKiB = defaultPageCacheKiB,
  }) => SqliteDatabase.withFactory(
    _CacheOpenFactory(
      path: path,
      sqliteOptions: const SqliteOptions(synchronous: SqliteSynchronous.normal),
      pageCacheKiB: pageCacheKiB,
    ),
  );

  /// Migrates v1 (single `value` blob envelope) → v2 columnar schema.
  /// Drops the old table (one-time cold miss) — simpler and safer than parsing
  /// every legacy row on the UI isolate.
  static Future<void> migrateToV2(SqliteDatabase db) async {
    await db.execute('DROP TABLE IF EXISTS $_table');
    await _createV2Schema(db);
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

  /// Returns the cached JSON entry for [url] **decoded to its object**, or
  /// null on a miss or a corrupt body.
  ///
  /// The parse rides the same worker hop the gunzip already pays: the 304
  /// revalidation path is the app's hottest cache path (the station
  /// catalogues are 65–130 KB and almost never change), and `read()` +
  /// `jsonDecode` on the caller's side put exactly that parse on the UI
  /// isolate — the one path Dio's own ≥50 KB isolate offload cannot see,
  /// because a 304 has no body for the transformer to parse.
  Future<CachedJson?> readJson(String url) async {
    try {
      final row = await _queryRow(url);
      if (row == null || (row['kind'] as int) != kindJson) return null;
      _scheduleTouch(url);
      final blob = row['body'] as Uint8List;
      final Object? data;
      if (blob.length >= 2 && blob[0] == 0x1f && blob[1] == 0x8b) {
        data = blob.length > 16 * 1024
            // One hop for gunzip + utf8 + parse. The fused decoder is the
            // same pair Dio uses, so the object shape is identical to a
            // fresh response's.
            ? await Isolate.run(
                () => const Utf8Decoder()
                    .fuse(const JsonDecoder())
                    .convert(gzip.decode(blob)),
              )
            : const Utf8Decoder()
                  .fuse(const JsonDecoder())
                  .convert(gzip.decode(blob));
      } else {
        data = const Utf8Decoder().fuse(const JsonDecoder()).convert(blob);
      }
      return CachedJson(
        etag: row['etag'] as String,
        data: data,
        size: (row['size'] as num).toInt(),
      );
    } catch (_) {
      // A corrupt entry reads as a miss: the interceptor then rejects the
      // 304 as retryable and the retry fetches a full 200 — safer than
      // surfacing a decode throw from inside an interceptor.
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

  /// Reads many binary entries in **one** SQLite round-trip, keyed by URL.
  ///
  /// This is the tile hot path: a map viewport resolves as a single `IN` query
  /// plus at most one isolate hop for the whole batch, instead of N queries and
  /// N isolate spawns. Missing URLs are simply absent from the result. Every
  /// hit is metered once, exactly as [readBytes] does.
  Future<Map<String, CachedBytes>> readBytesBatch(
    List<String> urls, {
    bool touch = true,
  }) async {
    if (urls.isEmpty) return const {};
    try {
      final rows = <Map<String, Object?>>[];
      for (var i = 0; i < urls.length; i += _readInChunk) {
        final end = i + _readInChunk;
        final chunk = end < urls.length
            ? urls.sublist(i, end)
            : urls.sublist(i);
        rows.addAll(
          await _db.getAll(
            'SELECT key, etag, content_type, kind, body, size FROM $_table '
            'WHERE key IN (${List.filled(chunk.length, '?').join(',')})',
            chunk,
          ),
        );
      }
      if (rows.isEmpty) return const {};

      // Collect every compressed body first so the whole batch inflates in one
      // hop — `Isolate.run` per row costs more than the decode it moves off.
      final compressed = <String, Uint8List>{};
      var compressedBytes = 0;
      for (final row in rows) {
        if ((row['kind'] as int) != kindBinaryGzip) continue;
        final blob = row['body'] as Uint8List;
        compressed[row['key'] as String] = blob;
        compressedBytes += blob.length;
      }
      final inflated = await _gunzipAll(compressed, compressedBytes);

      // The batch touches and meters **once** at the end. Doing either per row
      // turned one viewport into a burst of transactions: the touch buffer
      // crossed [_touchFlushEvery] several times mid-loop, and so did the usage
      // store's own flush counter. What lands is identical either way — the
      // touch `time` is stamped at flush, and the usage aggregate is a sum.
      final out = <String, CachedBytes>{};
      final served = <String>[];
      var savedBytes = 0;
      for (final row in rows) {
        final kind = row['kind'] as int;
        if (kind != kindBinary && kind != kindBinaryGzip) continue;
        final key = row['key'] as String;
        final bytes = kind == kindBinaryGzip
            ? inflated[key]
            : Uint8List.fromList(row['body'] as Uint8List);
        if (bytes == null) continue;
        final entry = CachedBytes(
          etag: row['etag'] as String,
          bytes: bytes,
          contentType: row['content_type'] as String?,
          size: (row['size'] as num).toInt(),
        );
        served.add(key);
        savedBytes += entry.size;
        out[key] = entry;
      }
      if (served.isEmpty) return out;
      if (touch) _scheduleTouchAll(served);
      _recordBinaryHits(served.length, savedBytes);
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Returns just the cached etag for [url], or null on a miss.
  Future<String?> readEtag(String url) async {
    try {
      final row = await _db.getOptional(
        'SELECT etag FROM $_table WHERE key = ? LIMIT 1',
        [url],
      );
      if (row == null) return null;
      _scheduleTouch(url);
      return row['etag'] as String?;
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
  }) => writeBytesBatch([
    (url: url, etag: etag, bytes: bytes, contentType: contentType, size: size),
  ]);

  /// Stores many binary entries in **one** transaction. Best-effort.
  ///
  /// The tile write path: a burst of downloaded tiles compresses in a single
  /// isolate hop and lands as one transaction, rather than paying a round-trip
  /// and a maintenance pass per tile.
  Future<void> writeBytesBatch(List<BinaryWrite> writes) async {
    if (writes.isEmpty) return;
    try {
      final encoded = await _encodeBinaryAll(writes);
      final now = _lruStamp();
      await _db.writeTransaction((tx) async {
        for (final row in encoded) {
          await tx.execute(
            'INSERT OR REPLACE INTO $_table '
            '(key, etag, content_type, kind, body, size, time) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              row.url,
              row.etag,
              row.contentType,
              row.kind,
              row.body,
              row.size,
              now,
            ],
          );
        }
      });
      var added = 0;
      for (final row in encoded) {
        added += row.body.length;
      }
      await _noteWrite(added, encoded.length);
    } catch (_) {}
  }

  /// The LRU ordering key: wall time, but never allowed to go backwards.
  ///
  /// `time` is only ever compared with other rows' `time` — it is a sequence
  /// number that happens to be readable as a date. A clock set back (or the
  /// first SNTP sync pulling it back) would stamp fresh writes *older* than
  /// rows already in the table, so eviction would throw away exactly what was
  /// just fetched and keep what nobody has touched in weeks. Monotonicity is
  /// the only property this key actually needs.
  int _lruStamp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > _lastStamp) _lastStamp = now;
    return _lastStamp;
  }

  /// Seeded from the table on open, so the guarantee survives a restart.
  int _lastStamp = 0;

  Future<void> _insert(
    String url, {
    required String etag,
    required String? contentType,
    required int kind,
    required Uint8List body,
    required int size,
  }) async {
    await _db.execute(
      'INSERT OR REPLACE INTO $_table '
      '(key, etag, content_type, kind, body, size, time) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [url, etag, contentType, kind, body, size, _lruStamp()],
    );
    await _noteWrite(body.length, 1);
  }

  /// Post-write maintenance, split by what it actually costs.
  ///
  /// **The byte budget** is the expensive half: knowing the total means summing
  /// every blob in the table. That is amortized over [_sweepEvery] writes, or
  /// forced the moment the running total says the store is over budget. Doing
  /// it per write made a viewport of tiles a full-table scan per tile. Nothing
  /// expires by age — only the budget trims, and only once the store is over
  /// it.
  Future<void> _noteWrite(int addedBytes, int rows) async {
    _writesSinceSweep += rows;
    final tracked = _trackedBytes;
    if (tracked != null) _trackedBytes = tracked + addedBytes;

    if (maxBytes <= 0) {
      await _db.execute('DELETE FROM $_table');
      _trackedBytes = 0;
      _writesSinceSweep = 0;
      return;
    }

    if (tracked != null &&
        _trackedBytes! <= maxBytes &&
        _writesSinceSweep < _sweepEvery) {
      return;
    }
    // Trim orders by `time` (last-used) — land buffered bumps first, or a
    // just-read entry would look untouched and be swept. Only the trim needs
    // that, which is why the flush sits *under* the guard: above it, every
    // tile batch paid an `UPDATE … IN (…)` transaction for a sweep that was
    // not going to run.
    await _flushTouches();
    await _trimToBudget();
  }

  /// Recounts stored bytes and drops least-recently-used rows — oldest
  /// (`time`) first — until the total is within [maxBytes]. A no-op (beyond
  /// the recount) when the store is under the ceiling: the budget trims only
  /// when it is actually over.
  Future<void> _trimToBudget() async {
    _writesSinceSweep = 0;
    var total = await _measureBytes();
    if (total <= maxBytes) {
      _trackedBytes = total;
      return;
    }
    // Only the oldest rows can be victims, and the surplus is normally one
    // sweep's worth of tiles — so page the ordering instead of hauling every
    // key and blob length in the table (tens of thousands of rows at a 350 MB
    // budget) across the platform channel to look at the first few. The `ORDER
    // BY` is unchanged, so the `time` index still serves it without a sort.
    final victims = <String>{};
    for (var offset = 0; total > maxBytes; offset += _trimScanChunk) {
      final rows = await _db.getAll(
        'SELECT key, LENGTH(body) AS b FROM $_table '
        'ORDER BY time ASC LIMIT ? OFFSET ?',
        [_trimScanChunk, offset],
      );
      if (rows.isEmpty) break;
      for (final row in rows) {
        if (total <= maxBytes) break;
        // Rows tie on `time`, so a page boundary may re-show one. Counting a
        // key once keeps the running total exact — an over-count would stop
        // the trim early and leave the store over budget.
        if (!victims.add(row['key'] as String)) continue;
        total -= (row['b'] as num).toInt();
      }
    }
    final keys = victims.toList(growable: false);
    // Chunked for the same bound-parameter ceiling the read path respects: a
    // single `IN (…)` of every victim throws "too many SQL variables" once a
    // trim has to drop more than ~1000 rows, which would abort the sweep.
    for (var i = 0; i < keys.length; i += _readInChunk) {
      final end = i + _readInChunk;
      final chunk = end < keys.length ? keys.sublist(i, end) : keys.sublist(i);
      await _db.execute(
        'DELETE FROM $_table WHERE key IN (${List.filled(chunk.length, '?').join(',')})',
        chunk,
      );
    }
    _trackedBytes = total;
  }

  Future<int> _measureBytes() async {
    final row = await _db.get(
      'SELECT COALESCE(SUM(LENGTH(body)), 0) AS b FROM $_table',
    );
    return (row['b'] as num).toInt();
  }

  /// Brings the store back inside its byte budget.
  ///
  /// The budget is normally enforced on write, amortized over [_sweepEvery]
  /// rows — which is right, because a cache only grows when something writes
  /// to it. What that misses is the *carry-over*: a session that ended over
  /// budget (killed mid-tile-batch, or the ceiling lowered between releases)
  /// stays over until 96 more writes happen to occur. On an app left open with
  /// the map closed, that is never. Cheap when already inside the ceiling —
  /// one `SUM(LENGTH(body))` and no deletes.
  Future<void> prune() async {
    try {
      await _flushTouches();
      await _trimToBudget();
    } catch (_) {
      // A cache that will not trim is a disk cost, not a fault; every other
      // path in this file swallows the same way.
    }
  }

  /// Deletes every cached entry.
  Future<void> clear() async {
    try {
      await _db.execute('DELETE FROM $_table');
      _trackedBytes = 0;
      _writesSinceSweep = 0;
    } catch (_) {}
  }

  /// Shrinks the database file back to its contents (free pages from cleared
  /// rows return to the OS — a body budget of 350 MB does not shrink the file
  /// on its own). Costly: only call after a full [clear], never per-write.
  Future<void> compact() async {
    try {
      await _db.execute('VACUUM');
    } catch (_) {}
  }

  /// Row count and total stored body bytes — for the Debug page.
  Future<EtagCacheStats> stats() async {
    try {
      final row = await _db.get(
        'SELECT COUNT(*) AS c, COALESCE(SUM(LENGTH(body)), 0) AS b FROM $_table',
      );
      return (
        rows: (row['c'] as num).toInt(),
        bytes: (row['b'] as num).toInt(),
      );
    } catch (_) {
      return (rows: 0, bytes: 0);
    }
  }

  Future<Map<String, Object?>?> _queryRow(String url) async {
    final row = await _db.getOptional(
      'SELECT key, etag, content_type, kind, body, size FROM $_table '
      'WHERE key = ? LIMIT 1',
      [url],
    );
    if (row == null) return null;
    return Map<String, Object?>.of(row);
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

  /// Compresses a whole batch, moving the work off the UI isolate **once** when
  /// it is big enough to be worth the hop.
  ///
  /// Kind tells [readBytes] whether to inflate: gzip-1 when the type is
  /// compressible and the result actually shrinks, otherwise raw.
  static Future<List<_EncodedWrite>> _encodeBinaryAll(
    List<BinaryWrite> writes,
  ) async {
    final compressible = <BinaryWrite>[];
    final out = <_EncodedWrite>[];
    var compressibleBytes = 0;
    for (final write in writes) {
      if (shouldGzipBinary(write.bytes, write.contentType)) {
        compressible.add(write);
        compressibleBytes += write.bytes.length;
      } else {
        out.add(_raw(write));
      }
    }
    if (compressible.isEmpty) return out;

    final payload = [for (final write in compressible) write.bytes];
    final packed = compressibleBytes > _isolateThreshold
        ? await Isolate.run(() => _gzipAllSync(payload))
        : _gzipAllSync(payload);
    for (var i = 0; i < compressible.length; i++) {
      final write = compressible[i];
      final body = packed[i];
      out.add(
        body.length >= write.bytes.length
            ? _raw(write)
            : (
                url: write.url,
                etag: write.etag,
                contentType: write.contentType,
                kind: kindBinaryGzip,
                body: body,
                size: write.size > 0 ? write.size : write.bytes.length,
              ),
      );
    }
    return out;
  }

  static _EncodedWrite _raw(BinaryWrite write) => (
    url: write.url,
    etag: write.etag,
    contentType: write.contentType,
    kind: kindBinary,
    body: write.bytes,
    size: write.size > 0 ? write.size : write.bytes.length,
  );

  static List<Uint8List> _gzipAllSync(List<Uint8List> payload) {
    final codec = GZipCodec(level: 1);
    return [
      for (final bytes in payload) Uint8List.fromList(codec.encode(bytes)),
    ];
  }

  /// Inflates a whole batch in at most one isolate hop (keyed by URL).
  static Future<Map<String, Uint8List>> _gunzipAll(
    Map<String, Uint8List> blobs,
    int totalBytes,
  ) async {
    if (blobs.isEmpty) return const {};
    if (totalBytes > _isolateThreshold) {
      return Isolate.run(() => _gunzipAllSync(blobs));
    }
    return _gunzipAllSync(blobs);
  }

  static Map<String, Uint8List> _gunzipAllSync(Map<String, Uint8List> blobs) =>
      {
        for (final entry in blobs.entries)
          entry.key: Uint8List.fromList(gzip.decode(entry.value)),
      };

  static Future<Uint8List> _gunzip(Uint8List blob) async {
    if (blob.length > _isolateThreshold) {
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

  void _recordBinaryHit(CachedBytes entry) => _recordBinaryHits(1, entry.size);

  /// Meters [hits] serves worth [saved] wire bytes as one usage event.
  ///
  /// A batch is one call, not one per row: [NetworkUsageStore] flushes on an
  /// event count, so a metered viewport used to write `net_bucket` (and run its
  /// 7-day sweep) several times while answering a single [readBytesBatch]. The
  /// aggregate is the same sum either way.
  void _recordBinaryHits(int hits, int saved) {
    final usage = _usage;
    if (usage == null) return;
    unawaited(usage.record(down: 0, hit: true, saved: saved, count: hits));
  }

  void _scheduleTouch(String url) {
    _pendingTouch.add(url);
    _armTouchFlush();
  }

  /// Batch form of [_scheduleTouch] — one flush decision per viewport.
  ///
  /// Per-key scheduling re-crossed [_touchFlushEvery] inside the loop, so a
  /// full [readBytesBatch] fired an `UPDATE … IN (…)` transaction every 48
  /// rows while it was still assembling the answer. Coalescing cannot reorder
  /// the LRU: the buffered bump is stamped with the time of the *flush*, so
  /// every key in the batch lands on the same instant either way, and
  /// [_noteWrite] still flushes before a trim reads `time`.
  void _scheduleTouchAll(Iterable<String> urls) {
    _pendingTouch.addAll(urls);
    _armTouchFlush();
  }

  void _armTouchFlush() {
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
    final now = _lruStamp();
    try {
      await _db.writeTransaction((tx) async {
        for (var i = 0; i < urls.length; i += _touchInChunk) {
          final end = i + _touchInChunk;
          final chunk = end < urls.length
              ? urls.sublist(i, end)
              : urls.sublist(i);
          await tx.execute(
            'UPDATE $_table SET time = ? WHERE key IN (${List.filled(chunk.length, '?').join(',')})',
            [now, ...chunk],
          );
        }
      });
    } catch (_) {}
  }
}

/// Pool factory for the cache file — adds the hot-read PRAGMAs to **every**
/// connection sqlite_async opens (one writer plus up to [SqliteOptions.maxReaders]
/// readers), which is where they belong: `cache_size` and `mmap_size` are
/// per-connection settings, and a tile burst reads through whichever pooled
/// reader picks it up.
base class _CacheOpenFactory extends NativeSqliteOpenFactory {
  _CacheOpenFactory({
    required super.path,
    required super.sqliteOptions,
    required this.pageCacheKiB,
  });

  final int pageCacheKiB;

  @override
  List<String> pragmaStatements(covariant SqliteOpenOptions options) => [
    ...super.pragmaStatements(options),
    // Negative cache_size = kibibytes reserved for the pager (~25 MiB).
    'PRAGMA cache_size = -$pageCacheKiB',
    'PRAGMA mmap_size = ${64 * 1024 * 1024}',
  ];
}
