import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

/// A cached HTTP response: the server [etag] to revalidate with, the response
/// [body] (the JSON-encoded payload), and its [contentType].
class CachedResponse {
  const CachedResponse({
    required this.etag,
    required this.body,
    this.contentType,
  });

  final String etag;
  final String body;
  final String? contentType;
}

/// On-disk ETag response cache backed by **SQLite**, so it stays fast with many
/// entries and evicts by age with a single indexed query.
///
/// One table, three columns — `key` (request URL), `value` (the whole entry
/// gzip level 9 for minimal space), `time` (write instant in ms). A write is a
/// single-row `INSERT OR REPLACE`, so re-fetching a URL updates it in place and
/// body/etag can never diverge (SQLite commits the row atomically — no torn
/// write). Each write also sweeps rows older than [maxAge] (7 days by default),
/// which suits high-churn feeds like the radar frame list. All operations are
/// best-effort: any error is swallowed to a cache miss / no-op — the cache must
/// never break a request.
class EtagCacheStore {
  EtagCacheStore(this._db, {this.maxAge = const Duration(days: 7)});

  final Database _db;

  /// Entries whose [time] is older than this are swept on the next write.
  final Duration maxAge;

  static const String _table = 'http_cache';
  static final GZipCodec _gzip9 = GZipCodec(level: 9);

  /// Creates the cache table and its time index (idempotent) — call from
  /// `openDatabase`'s `onCreate`.
  static Future<void> createSchema(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_table ('
      'key TEXT PRIMARY KEY, value BLOB NOT NULL, time INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ${_table}_time ON $_table(time)',
    );
  }

  /// Returns the cached entry for [url], or null on a miss / corruption.
  Future<CachedResponse?> read(String url) async {
    try {
      final entry = await _decode(url);
      if (entry == null) return null;
      return CachedResponse(
        etag: entry['etag'] as String,
        body: entry['body'] as String,
        contentType: entry['contentType'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns just the cached etag for [url] (for `If-None-Match` on the request
  /// path), or null on a miss.
  Future<String?> readEtag(String url) async {
    try {
      return (await _decode(url))?['etag'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Stores [body] for [url] under [etag], gzip-9, replacing any existing entry;
  /// then sweeps entries older than [maxAge]. Best-effort — errors are swallowed.
  Future<void> write(
    String url, {
    required String etag,
    required String body,
    String? contentType,
  }) async {
    try {
      final payload = utf8.encode(
        jsonEncode({'etag': etag, 'contentType': contentType, 'body': body}),
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db.insert(
        _table,
        {
          'key': url,
          'value': Uint8List.fromList(_gzip9.encode(payload)),
          'time': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // same key → update
      );
      await _db.delete(
        _table,
        where: 'time < ?',
        whereArgs: [now - maxAge.inMilliseconds],
      );
    } catch (_) {
      // Caching is an optimisation; a write failure must not surface.
    }
  }

  /// Deletes every cached entry.
  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } catch (_) {}
  }

  /// Reads and inflates the entry for [url] into its decoded map, or null.
  Future<Map<String, dynamic>?> _decode(String url) async {
    final rows = await _db.query(
      _table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final blob = rows.first['value'] as Uint8List;
    return jsonDecode(utf8.decode(gzip.decode(blob))) as Map<String, dynamic>;
  }
}
