import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Result<int>> _throwing({bool Function(Failure)? shouldLog}) =>
    guardResult<int>(() async {
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response<void>(
          requestOptions: RequestOptions(),
          statusCode: 404,
        ),
      );
    }, shouldLog: shouldLog);

void main() {
  group('guardResult', () {
    test('returns Ok with the body value on success', () async {
      final result = await guardResult(() async => 42);
      expect(result, isA<Ok<int>>());
      expect(result.valueOrNull, 42);
    });

    test('folds a throw into Err with the failure classified', () async {
      final result = await guardResult<int>(() async {
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        );
      });
      expect(result, isA<Err<int>>());
      // A timeout must stay distinguishable (drives realtime STALE handling).
      expect(result.failureOrNull, isA<TimeoutFailure>());
    });

    test('classifies a decode error as DecodeFailure', () async {
      final result = await guardResult<int>(() async {
        return ['not', 'an', 'int'] as int; // TypeError
      });
      expect(result.failureOrNull, isA<DecodeFailure>());
    });

    test('logs the failure by default', () async {
      Log.talker.cleanHistory();
      final result = await _throwing();
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(Log.talker.history, isNotEmpty);
    });

    test('shouldLog:false drops the log line but still returns Err', () async {
      Log.talker.cleanHistory();
      Failure? seen;
      final result = await _throwing(
        shouldLog: (failure) {
          seen = failure;
          return false;
        },
      );
      // The suppression is of the log line only — a caller can never mistake a
      // quiet failure for a success.
      expect(result, isA<Err<int>>());
      expect(result.failureOrNull, isA<NotFoundFailure>());
      // And it decides on the classified failure, not the raw exception.
      expect(seen, isA<NotFoundFailure>());
      expect(Log.talker.history, isEmpty);
    });
  });
}
