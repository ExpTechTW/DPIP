import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
