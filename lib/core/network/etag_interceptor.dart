import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/network/terrain_tile_codec.dart';

/// Dio interceptor implementing HTTP ETag revalidation against an
/// [EtagCacheStore].
///
/// - **Request:** for a cacheable GET, attaches `If-None-Match` from the cached
///   entry so the server can answer `304 Not Modified` instead of resending.
/// - **Response 304:** rewrites the empty 304 into a `200` carrying the cached
///   body, so callers above never see a 304 and get the data for free.
/// - **Response 200 + ETag:** stores the body keyed by URL (JSON gzip-1;
///   binary gzip-1 when it shrinks — PBF/MVT yes, WebP no).
///
/// **Immutable tiles** (basemap PBF / radar / satellite / DPM — frame or z/x/y
/// in the path) are **URL-addressed**: local hit → serve, no `If-None-Match`.
/// A `200` is always stored under a synthetic [etagFromUrl] (server ETag is
/// ignored — the URL already pins the content). Basemap `404` is negatively
/// cached (empty + [negativeTileEtag]); radar/sat/DPM 404s are not.
///
/// For everything else, **ETag is the only validator** — `Cache-Control` /
/// `no-store` are ignored; a `200` without an ETag is not written. Streaming
/// (SSE) is skipped. High-churn / unique-URL GETs (EEW, RTS, device location,
/// notify) are never cached. Requires Dio `validateStatus` to accept 304 (set
/// in `createDio`).
class EtagInterceptor extends Interceptor {
  EtagInterceptor(this._store, {this._usage});

  final EtagCacheStore _store;

  /// Optional traffic accounting: records downloaded bytes, cache misses, and
  /// JSON `304` hits. Binary serves (immutable tile / binary `304`) are metered
  /// inside [EtagCacheStore.readBytes] so memory + SQLite→memory count once.
  final NetworkUsageStore? _usage;

  /// Synthetic ETag for a cached immutable-tile `404` (empty body).
  static const String negativeTileEtag = 'W/"404"';

  static bool _cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' &&
      o.responseType != ResponseType.stream &&
      !isUncacheablePath(o.uri.path);

  /// Paths that must never enter the ETag store (live / unique / personal).
  static bool isUncacheablePath(String path) {
    if (path == ApiPaths.eew || path == ApiPaths.rts) return true;
    if (path.startsWith(ApiPaths.location)) return true;
    // getNotify + setNotify — token-keyed, must not stick in SQLite.
    return path.startsWith(ApiPaths.notify);
  }

  static bool _isBytes(RequestOptions o) =>
      o.responseType == ResponseType.bytes;

  /// Bare-host basemap vector tiles (no server ETag).
  static bool isBasemapPbf(Uri uri) =>
      uri.host == 'static.lb.exptech.dev' &&
      uri.path.contains(ApiPaths.mapTilesV1) &&
      uri.path.endsWith('.pbf');

  /// URL fragments marking a **content-addressed** asset: the URL fully
  /// determines the bytes, so a local hit is served without revalidating (a new
  /// radar frame, or a new glyph range, is a new URL).
  ///
  /// The single source of truth for what this app caches. [isImmutableTile]
  /// gates the Dio path with it, and [MapTileCache] hands the same list to
  /// MapLibre's native intercept — one list, so the two can never drift into a
  /// URL that native keeps asking about and Dart never stores.
  ///
  /// Glyphs are here so **every** byte the map costs lands in one store with one
  /// eviction policy and one traffic total. They used to be cached only by
  /// MapLibre's own ambient database, which meant they were invisible to the
  /// app's usage accounting.
  static const List<String> immutableAssetMarkers = [
    ApiPaths.mapTilesV1, // basemap vector tiles
    ApiPaths.mapTerrainV1, // terrain vector tiles
    '${ApiPaths.tiles}/radar/',
    '${ApiPaths.tiles}/satellite/',
    '${ApiPaths.tiles}/wind/',
    '${ApiPaths.dpm}/',
    '/gh/exptechtw/map-assets/', // glyph PBFs (jsDelivr)
  ];

  /// Whether [uri] names a content-addressed asset — see
  /// [immutableAssetMarkers].
  static bool isImmutableTile(Uri uri) {
    final url = uri.toString();
    for (final marker in immutableAssetMarkers) {
      if (url.contains(marker)) return true;
    }
    return false;
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

    // Immutable tiles: URL is the key — serve SQLite hits locally. Never send
    // If-None-Match (content is pinned by the URL; revalidation is pointless).
    if (_isBytes(options) && isImmutableTile(options.uri)) {
      final cached = await _store.readBytes(url);
      if (cached != null) {
        // Hit metering lives in [EtagCacheStore.readBytes].
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
            // Hit metering lives in [EtagCacheStore.readBytes].
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
        final immutable =
            binary && response.data != null && isImmutableTile(options.uri);
        var etag = response.headers.value('etag');
        if (immutable) {
          // URL pins content — ignore server ETag, always store under URL hash.
          etag = etagFromUrl(options.uri);
          response.headers.set('etag', etag);
        }
        // Non-immutable: ETag only — no ETag ⇒ no store.
        if (etag != null && response.data != null) {
          if (binary) {
            final bytes = _asBytes(response.data);
            final converted = isTerrainPng(options.uri)
                ? ensureTerrarium(bytes)
                : null;
            unawaited(
              _store.writeBytes(
                url,
                etag: etag,
                bytes: converted ?? bytes,
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

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final status = err.response?.statusCode;
    // Basemap PBF only — ocean / uncovered z/x/y is stable. Not radar/sat/DPM.
    if (_cacheable(options) &&
        _isBytes(options) &&
        status == 404 &&
        isBasemapPbf(options.uri)) {
      final url = options.uri.toString();
      await _store.writeBytes(
        url,
        etag: negativeTileEtag,
        bytes: Uint8List(0),
        contentType: 'application/octet-stream',
        size: 0,
      );
      final usage = _usage;
      if (usage != null) {
        unawaited(usage.record(down: 0, hit: false, saved: 0));
      }
    }
    handler.next(err);
  }
}

/// Header-name constants used by [EtagInterceptor].
abstract final class HttpHeadersEtag {
  static const String ifNoneMatch = 'if-none-match';
}
