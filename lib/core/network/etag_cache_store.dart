import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

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

/// On-disk ETag response cache: bodies are stored **gzip level 9** and keyed by
/// request URL, so revalidation costs one `If-None-Match` round trip and a 304
/// serves from disk instead of re-downloading.
///
/// Each entry is **one file** `<sha256(url)>.entry` = a single-line JSON header
/// (the original URL for a collision guard, the etag, content-type, save time)
/// followed by a `\n` and the gzipped body. Writing the whole entry with one
/// temp-file-plus-rename is the load-bearing invariant: the body and its etag
/// can never be persisted out of step, so two concurrent writers or a partial
/// write can never leave a body paired with the wrong etag (which would make a
/// later 304 serve a stale payload). The cache is bounded by [maxBytes] with
/// oldest-first eviction. All operations are best-effort: any I/O or corruption
/// error is swallowed to a cache miss — the cache must never break a request.
class EtagCacheStore {
  EtagCacheStore(this._dir, {this._maxBytes = 8 * 1024 * 1024});

  final Directory _dir;
  final int _maxBytes;

  static final GZipCodec _gzip9 = GZipCodec(level: 9);

  /// Separates the JSON header from the gzip body within an entry file.
  static const int _separator = 0x0A; // '\n'

  /// Header bytes read from the front of an entry before falling back to a full
  /// read — large enough for any realistic URL + etag, small enough to keep the
  /// request path and prune cheap.
  static const int _headerReadLimit = 4096;

  /// Makes each temp file unique so two concurrent writes to the same URL don't
  /// race on one `.tmp` path.
  static int _tmpSeq = 0;

  /// Returns the cached entry for [url], or null on a miss / corruption.
  Future<CachedResponse?> read(String url) async {
    try {
      final file = _entryFile(url);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final nl = bytes.indexOf(_separator);
      if (nl < 0) return null;
      final header =
          jsonDecode(utf8.decode(bytes.sublist(0, nl))) as Map<String, dynamic>;
      if (header['url'] != url) return null; // sha256 collision — treat as miss
      final body = utf8.decode(gzip.decode(bytes.sublist(nl + 1)));
      return CachedResponse(
        etag: header['etag'] as String,
        body: body,
        contentType: header['contentType'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns just the cached etag for [url] without inflating the body — the
  /// request path only needs the validator for `If-None-Match`. Returns null
  /// (so no conditional header is sent) unless a full, readable entry exists,
  /// preserving the invariant that a resulting 304 can be served from cache.
  Future<String?> readEtag(String url) async {
    try {
      final header = await _readHeader(_entryFile(url));
      if (header == null || header['url'] != url) return null;
      return header['etag'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Stores [body] for [url] under [etag], compressed with gzip level 9. The
  /// header+body are written as one atomic entry; prunes to [maxBytes]
  /// afterwards. Best-effort — errors are swallowed.
  Future<void> write(
    String url, {
    required String etag,
    required String body,
    String? contentType,
  }) async {
    try {
      await _dir.create(recursive: true);
      final gz = _gzip9.encode(utf8.encode(body));
      final header = utf8.encode(
        jsonEncode({
          'url': url,
          'etag': etag,
          'contentType': contentType,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      final payload = Uint8List(header.length + 1 + gz.length)
        ..setRange(0, header.length, header)
        ..[header.length] = _separator
        ..setRange(header.length + 1, header.length + 1 + gz.length, gz);
      await _atomicWrite(
        _entryFile(url),
        (f) => f.writeAsBytes(payload, flush: true),
      );
      await _prune();
    } catch (_) {
      // Caching is an optimisation; a write failure must not surface.
    }
  }

  /// Deletes every cached entry.
  Future<void> clear() async {
    try {
      if (await _dir.exists()) await _dir.delete(recursive: true);
    } catch (_) {}
  }

  Future<void> _atomicWrite(
    File target,
    Future<void> Function(File) write,
  ) async {
    final tmp = File('${target.path}.${_tmpSeq++}.tmp');
    try {
      await write(tmp);
      await tmp.rename(target.path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete(); // don't leak the temp file
      rethrow;
    }
  }

  /// Reads and decodes an entry's leading JSON header without inflating its
  /// body, reading only a bounded prefix (with a full-read fallback for an
  /// unusually long header). Null on a missing file / corruption.
  Future<Map<String, dynamic>?> _readHeader(File file) async {
    if (!await file.exists()) return null;
    final raf = await file.open();
    try {
      final length = await file.length();
      final take = length < _headerReadLimit ? length : _headerReadLimit;
      final prefix = await raf.read(take);
      var nl = prefix.indexOf(_separator);
      if (nl >= 0) {
        return jsonDecode(utf8.decode(prefix.sublist(0, nl)))
            as Map<String, dynamic>;
      }
      if (length <= _headerReadLimit) return null; // no separator → corrupt
      final full = await file.readAsBytes();
      nl = full.indexOf(_separator);
      if (nl < 0) return null;
      return jsonDecode(utf8.decode(full.sublist(0, nl)))
          as Map<String, dynamic>;
    } finally {
      await raf.close();
    }
  }

  /// Evicts oldest-first while the total on-disk size exceeds [_maxBytes].
  Future<void> _prune() async {
    final entries = <({File file, int savedAt, int size})>[];
    var total = 0;
    await for (final entity in _dir.list()) {
      if (entity is! File || !entity.path.endsWith('.entry')) continue;
      try {
        final size = await entity.length();
        final header = await _readHeader(entity);
        total += size;
        entries.add((
          file: entity,
          savedAt: (header?['savedAt'] as num?)?.toInt() ?? 0,
          size: size,
        ));
      } catch (_) {}
    }
    if (total <= _maxBytes) return;
    entries.sort((a, b) => a.savedAt.compareTo(b.savedAt)); // oldest first
    for (final e in entries) {
      if (total <= _maxBytes) break;
      try {
        if (await e.file.exists()) await e.file.delete();
      } catch (_) {}
      total -= e.size;
    }
  }

  String _key(String url) => sha256.convert(utf8.encode(url)).toString();
  File _entryFile(String url) => File('${_dir.path}/${_key(url)}.entry');
}
