import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';

/// Runs [body] and folds it into a [Result]: its value on success, a typed
/// [Failure] (via [mapException]) on any throw.
///
/// The one place the data layer turns a throwing fetch/decode into `Result`, so
/// every repository method is a one-liner and none can accidentally forget the
/// `try` or return `Ok` on failure — which for a safety feed would turn a dead
/// source into a false all-clear.
Future<Result<T>> guardResult<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } catch (error) {
    return Err(mapException(error));
  }
}

/// Maps a caught transport / decode error into a typed [Failure].
///
/// The single place the data layer converts `dio` and parsing exceptions into
/// the app's failure vocabulary, so presentation never sees a raw
/// [DioException] or `TypeError` and timeouts stay distinguishable from real
/// errors (important for realtime STALE handling).
Failure mapException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure('Request timed out');
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return NetworkFailure('Server error${code == null ? '' : ' ($code)'}');
      case DioExceptionType.cancel:
        return const NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return const NetworkFailure('No connection');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const NetworkFailure('Network error');
    }
  }
  // `as`-cast / shape mismatches while decoding, or malformed JSON.
  if (error is TypeError || error is FormatException) {
    return const DecodeFailure('Unexpected response format');
  }
  return UnexpectedFailure(error.toString());
}
