import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';

/// Dio interceptor implementing HTTP ETag revalidation against an
/// [EtagCacheStore].
///
/// - **Request:** for a cacheable GET, attaches `If-None-Match` from the cached
///   entry so the server can answer `304 Not Modified` instead of resending.
/// - **Response 304:** rewrites the empty 304 into a `200` carrying the cached
///   body, so callers above never see a 304 and get the data for free.
/// - **Response 200 + ETag:** stores the body (gzip-9) keyed by URL.
///
/// **ETag is the only validator** — `Cache-Control` / `no-store` are ignored.
/// A `200` without an ETag is not written, **except** ExpTech basemap PBF
/// (`lb.exptech.dev/…/map/tiles/…`), which gets a synthetic ETag = FNV hash of
/// the URL (LB has no ETag; the tile is content-addressed by z/x/y).
///
/// **Immutable tile URLs** (basemap / radar / satellite / DPM — the frame or
/// z/x/y is in the path) are served from SQLite on hit with **no**
/// `If-None-Match` round trip. Supports JSON and binary (`ResponseType.bytes`).
/// Streaming (SSE) is skipped. High-churn / unique-URL GETs (EEW, RTS, device
/// location, notify) are never cached. Requires Dio `validateStatus` to accept
/// 304 (set in `createDio`).
class EtagInterceptor extends Interceptor {
  EtagInterceptor(this._store, {this._usage});

  final EtagCacheStore _store;

  /// Optional traffic accounting: records downloaded bytes, cache hits/misses,
  /// and the bytes a `304` / local tile hit saved.
  final NetworkUsageStore? _usage;

  static bool _cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' &&
      o.responseType != ResponseType.stream &&
      !isUncacheablePath(o.uri.path);

  /// Paths that must never enter the ETag store (live / unique / personal).
  static bool isUncacheablePath(String path) {
    if (path == '/api/v2/eq/eew' || path == '/api/v2/trem/rts') return true;
    if (path.startsWith('/api/v2/location/')) return true;
    // getNotify only — setNotify has more segments after the token.
    final notify = RegExp(r'^/api/v2/notify/[^/]+$');
    return notify.hasMatch(path);
  }

  static bool _isBytes(RequestOptions o) =>
      o.responseType == ResponseType.bytes;

  /// Bare-host basemap vector tiles (no server ETag).
  static bool isBasemapPbf(Uri uri) =>
      uri.host == 'lb.exptech.dev' &&
      uri.path.contains('/api/v1/map/tiles/') &&
      uri.path.endsWith('.pbf');

  /// XYZ / frame-keyed tiles — URL is content-addressed; never revalidate on
  /// the hot path (a new frame = a new URL).
  static bool isImmutableTile(Uri uri) {
    if (isBasemapPbf(uri)) return true;
    final p = uri.path;
    return p.contains('/api/v2/tiles/radar/') ||
        p.contains('/api/v2/tiles/satellite/') ||
        p.contains('/api/v2/tiles/dpm/');
  }

  /// Stable weak ETag derived from the request URL (FNV-1a 64-bit).
  static String etagFromUrl(Uri uri) {
    const offset = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    var hash = offset;
    for (final unit in utf8.encode(uri.toString())) {
      hash ^= unit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return 'W/"u${hash.toRadixString(16)}"';
  }

  static bool _isUrlHashEtag(String etag) => etag.startsWith('W/"u');

  /// Best-effort transferred-byte estimate: the server's `Content-Length` when
  /// present (the compressed wire size), else the decoded body length (an upper
  /// bound — the platform strips Content-Length when it transparently gunzips).
  static int _downBytes(Response<dynamic> response) {
    final length = int.tryParse(
      response.headers.value(Headers.contentLengthHeader) ?? '',
    );
    if (length != null && length > 0) return length;
    final data = response.data;
    if (data == null) return 0;
    if (data is List<int>) return data.length;
    return utf8.encode(data is String ? data : jsonEncode(data)).length;
  }

  static Uint8List _asBytes(Object? data) {
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw StateError('Expected bytes, got ${data.runtimeType}');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_cacheable(options)) {
      handler.next(options);
      return;
    }
    final url = options.uri.toString();

    // Immutable tiles (basemap / radar / sat / DPM): URL is the key — serve
    // SQLite hits locally. Never send If-None-Match (would force a RTT every
    // pan even when the body is already on disk).
    if (_isBytes(options) && isImmutableTile(options.uri)) {
      final cached = await _store.readBytes(url);
      if (cached != null) {
        final usage = _usage;
        if (usage != null) {
          unawaited(usage.record(down: 0, hit: true, saved: cached.size));
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: cached.bytes,
            headers: Headers.fromMap({
              'etag': [cached.etag],
              if (cached.contentType != null)
                Headers.contentTypeHeader: [cached.contentType!],
            }),
          ),
        );
        return;
      }
      handler.next(options);
      return;
    }

    final etag = await _store.readEtag(url);
    // Never send a synthetic URL-hash If-None-Match — the origin doesn't know it.
    if (etag != null && !_isUrlHashEtag(etag)) {
      options.headers[HttpHeadersEtag.ifNoneMatch] = etag;
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    if (_cacheable(options)) {
      final url = options.uri.toString();
      final binary = _isBytes(options);
      if (response.statusCode == 304) {
        if (binary) {
          final cached = await _store.readBytes(url);
          if (cached != null) {
            response.statusCode = 200;
            response.data = cached.bytes;
            response.headers.set('etag', cached.etag);
            final usage = _usage;
            if (usage != null) {
              unawaited(usage.record(down: 0, hit: true, saved: cached.size));
            }
            handler.next(response);
            return;
          }
        } else {
          final cached = await _store.read(url);
          if (cached != null) {
            // Present the revalidated cache as a normal 200 to callers above.
            response.statusCode = 200;
            response.data = jsonDecode(cached.body);
            response.headers.set('etag', cached.etag);
            final usage = _usage;
            if (usage != null) {
              unawaited(usage.record(down: 0, hit: true, saved: cached.size));
            }
            handler.next(response);
            return;
          }
        }
        // The entry was evicted between request and response, so there is no
        // body to serve. Never hand a bodyless 304 up as a success: reject as
        // retryable so the region client fails over (and on retry the now-empty
        // cache sends no If-None-Match → a full 200) or raises an honest error
        // on the last host.
        handler.reject(
          DioException(
            requestOptions: options,
            response: response,
            type: DioExceptionType.unknown,
            error: StateError('ETag 304 but cache entry was evicted'),
          ),
        );
        return;
      } else if (response.statusCode == 200) {
        final down = _downBytes(response);
        var etag = response.headers.value('etag');
        if (binary &&
            etag == null &&
            response.data != null &&
            isBasemapPbf(options.uri)) {
          etag = etagFromUrl(options.uri);
          response.headers.set('etag', etag);
        }
        // ETag only — no ETag ⇒ no store (Cache-Control is irrelevant).
        if (etag != null && response.data != null) {
          if (binary) {
            final bytes = _asBytes(response.data);
            unawaited(
              _store.writeBytes(
                url,
                etag: etag,
                bytes: bytes,
                contentType: response.headers.value(Headers.contentTypeHeader),
                size: down,
              ),
            );
          } else {
            unawaited(
              _store.write(
                url,
                etag: etag,
                body: jsonEncode(response.data),
                contentType: response.headers.value(Headers.contentTypeHeader),
                size: down,
              ),
            );
          }
        }
        final usage = _usage;
        if (usage != null) {
          unawaited(usage.record(down: down, hit: false, saved: 0));
        }
      }
    }
    handler.next(response);
  }
}

/// Header-name constants used by [EtagInterceptor].
abstract final class HttpHeadersEtag {
  static const String ifNoneMatch = 'if-none-match';
}
