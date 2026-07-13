import 'package:dio/dio.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';

/// Builds the shared [Dio] instance for the region-aware `ApiClient`.
///
/// No base URL is set: every request targets an absolute, region-pinned host
/// resolved from the current region selection. gzip is negotiated by the
/// platform HTTP stack (`Accept-Encoding: gzip`), so no manual decompression
/// adapter is required. When an [etagCache] is supplied, an [EtagInterceptor]
/// adds global HTTP ETag revalidation — cached bodies are stored gzip-9 on disk
/// and a `304` is served from cache instead of re-downloading.
///
/// Timeouts are kept tight: the payloads are small JSON snapshots and a realtime
/// feed polls every second, so a hung request should fail over (or surface as a
/// [DioExceptionType.receiveTimeout]) quickly rather than block. A caller needing
/// more slack passes its own `Options` per request.
Dio createDio({EtagCacheStore? etagCache}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept-Encoding': 'gzip'},
      // Accept 304 so the ETag interceptor can rewrite it into a cached 200;
      // other non-2xx still throw, preserving the region client's failover and
      // error mapping. A 304 only occurs when the interceptor sent an
      // If-None-Match, so this is inert without a cache.
      validateStatus: (status) =>
          status != null && ((status >= 200 && status < 300) || status == 304),
    ),
  );
  if (etagCache != null) {
    dio.interceptors.add(EtagInterceptor(etagCache));
  }
  return dio;
}
