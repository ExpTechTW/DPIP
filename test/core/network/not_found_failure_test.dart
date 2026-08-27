import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

Failure of(int code) => mapException(
  DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: DioExceptionType.badResponse,
    response: Response<void>(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: code,
    ),
  ),
);

void main() {
  // A 404 is the one status where retrying can never succeed, so it gets its
  // own type and callers send the reader somewhere real instead.
  test('404 maps to NotFoundFailure', () {
    expect(of(404), isA<NotFoundFailure>());
  });

  test('other bad responses stay retryable NetworkFailures', () {
    for (final code in [400, 401, 403, 429, 500, 502, 503]) {
      expect(
        of(code),
        isA<NetworkFailure>(),
        reason: '$code should keep the retry affordance',
      );
    }
  });

  test('a timeout is still a TimeoutFailure', () {
    expect(
      mapException(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isA<TimeoutFailure>(),
    );
  });
}
