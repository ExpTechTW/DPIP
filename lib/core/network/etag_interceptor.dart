import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/etag_cache_store.dart';

/// Dio interceptor implementing HTTP ETag revalidation against an
/// [EtagCacheStore].
///
/// - **Request:** for a cacheable GET, attaches `If-None-Match` from the cached
///   entry so the server can answer `304 Not Modified` instead of resending.
/// - **Response 304:** rewrites the empty 304 into a `200` carrying the cached
///   body, so callers above never see a 304 and get the data for free.
/// - **Response 200 + ETag:** stores the body (gzip-9) keyed by URL.
///
/// Streaming responses (Server-Sent Events) are skipped — they are neither
/// cacheable nor safe to buffer. Requires the Dio `validateStatus` to accept
/// 304 (set in `createDio`) so a 304 arrives here rather than throwing.
class EtagInterceptor extends Interceptor {
  EtagInterceptor(this._store);

  final EtagCacheStore _store;

  static bool _cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' && o.responseType != ResponseType.stream;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_cacheable(options)) {
      final etag = await _store.readEtag(options.uri.toString());
      if (etag != null) {
        options.headers[HttpHeadersEtag.ifNoneMatch] = etag;
      }
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
      if (response.statusCode == 304) {
        final cached = await _store.read(url);
        if (cached != null) {
          // Present the revalidated cache as a normal 200 to callers above.
          response.statusCode = 200;
          response.data = jsonDecode(cached.body);
          handler.next(response);
          return;
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
        final etag = response.headers.value('etag');
        if (etag != null && response.data != null) {
          // Awaited deliberately: the payloads are small (gzip-9 of a JSON
          // snapshot, plus a bounded-header prune), and completing the write
          // before the response returns means an immediately-following request
          // revalidates from cache instead of racing a pending write.
          await _store.write(
            url,
            etag: etag,
            body: jsonEncode(response.data),
            contentType: response.headers.value(Headers.contentTypeHeader),
          );
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
