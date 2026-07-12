import 'package:dio/dio.dart';

/// Builds the shared [Dio] instance for the region-aware `ApiClient`.
///
/// No base URL is set: every request targets an absolute, region-pinned host
/// resolved from the current region selection. gzip is negotiated by the
/// platform HTTP stack, so no manual decompression adapter is required.
/// Cross-cutting interceptors (logging, auth) are registered here as the app
/// grows.
///
/// Timeouts are kept tight: the payloads are small JSON snapshots and a realtime
/// feed polls every second, so a hung request should fail over (or surface as a
/// [DioExceptionType.receiveTimeout]) quickly rather than block. A caller needing
/// more slack passes its own `Options` per request.
Dio createDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {'Accept-Encoding': 'gzip'},
    ),
  );
}
