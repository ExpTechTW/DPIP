import 'package:dio/dio.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/network/network_usage_store.dart';

/// Builds the shared [Dio] instance for the region-aware `ApiClient`.
///
/// No base URL is set: every request targets an absolute, region-pinned host
/// resolved from the current region selection. gzip is negotiated by the
/// platform HTTP stack (`Accept-Encoding: gzip`), so no manual decompression
/// adapter is required. When an [etagCache] is supplied, an [EtagInterceptor]
/// adds global HTTP ETag revalidation — JSON and compressible binaries (PBF /
/// MVT / …) are gzip-1 on disk; WebP etc. stay raw. A `304` is served from cache.
///
/// Timeouts are kept tight: the payloads are small JSON snapshots and a realtime
/// feed polls every second, so a hung request should fail over (or surface as a
/// [DioExceptionType.receiveTimeout]) quickly rather than block. A caller needing
/// more slack passes its own `Options` per request.
Dio createDio({EtagCacheStore? etagCache, NetworkUsageStore? usage}) {
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
      // Redirects are followed by the adapter (`followRedirects` defaults to
      // true, `maxRedirects` to 5), which matters for one endpoint family:
      // notify/location are primary-on-tnn1 with a hot standby, and a standby
      // that is up while the primary is not answers `307` at the *interim*
      // node, not at tnn1. Following it means the write lands on tnn1, where it
      // belongs. A 3xx never reaches [validateStatus] — by the time the status
      // is checked the chain has already settled on its final response.
    ),
  );
  if (etagCache != null) {
    dio.interceptors.add(EtagInterceptor(etagCache, usage: usage));
  }
  return dio;
}
