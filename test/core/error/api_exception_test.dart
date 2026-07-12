import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/x');

  group('mapException', () {
    test('a timeout becomes a TimeoutFailure (distinct from an error)', () {
      final failure = mapException(
        DioException(
          requestOptions: request,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(failure, isA<TimeoutFailure>());
    });

    test('a non-2xx response becomes a NetworkFailure carrying the code', () {
      final failure = mapException(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: request, statusCode: 503),
        ),
      );
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('503'));
    });

    test('a decode/shape error becomes a DecodeFailure, not a network error', () {
      expect(mapException(const FormatException('bad')), isA<DecodeFailure>());
      try {
        // A renamed field would make a cast like this throw a TypeError.
        (<String, dynamic>{'mag': 'x'})['mag']! as double;
        fail('expected a cast error');
      } catch (error) {
        expect(mapException(error), isA<DecodeFailure>());
      }
    });

    test('anything else becomes an UnexpectedFailure', () {
      expect(mapException(StateError('boom')), isA<UnexpectedFailure>());
    });
  });
}
