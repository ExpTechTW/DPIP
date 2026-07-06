import 'package:dio/dio.dart';
import 'package:dpip/core/constants/app_constants.dart';

/// Builds the shared [Dio] instance used for all HTTP access.
///
/// Cross-cutting interceptors (logging, auth, caching) are registered here as
/// the app grows, keeping transport concerns out of individual repositories.
Dio createDioClient() {
  return Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
}
