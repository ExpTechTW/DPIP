import 'package:dio/dio.dart';

/// Builds the shared [Dio] instance for the region-aware `ApiClient`.
///
/// No base URL is set: every request targets an absolute, region-pinned host
/// resolved from the current region selection. gzip is negotiated by the
/// platform HTTP stack, so no manual decompression adapter is required.
/// Cross-cutting interceptors (logging, auth) are registered here as the app
/// grows.
Dio createDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept-Encoding': 'gzip'},
    ),
  );
}
