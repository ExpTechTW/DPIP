/// [RainHourTrendRepositoryImpl]'s contract: a transport or decode fault
/// leaves as a typed [Failure], never a thrown exception — this feeds the
/// home sheet's next-hour rain card, so a swallowed fault there should mean
/// the card just doesn't appear, not that it shows a stale or fabricated
/// trend. Only one method, but its own decode (`RainHourTrend.decode`) is
/// unusually strict for this data layer — it throws on a malformed series
/// rather than tolerating it — so that path gets its own case alongside the
/// shared transport-fault matrix.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_api.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingApi implements RainHourTrendApi {
  _FailingApi(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> getForecast(String code) async => throw error;
}

/// Answers with a scripted envelope and records the codes it was asked for.
class _StubApi implements RainHourTrendApi {
  _StubApi(this.json);

  final Map<String, dynamic> json;
  final List<String> codes = [];

  @override
  Future<Map<String, dynamic>> getForecast(String code) async {
    codes.add(code);
    return json;
  }
}

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/weather/rainforecast/6300100');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

void main() {
  test('a 404 folds into NotFoundFailure, not a crash', () async {
    final repo = RainHourTrendRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.badResponse, status: 404)),
    );

    expect(
      (await repo.hourTrend('6300100')).failureOrNull,
      isA<NotFoundFailure>(),
    );
  });

  test('a timeout folds into TimeoutFailure', () async {
    final repo = RainHourTrendRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.connectionTimeout)),
    );

    expect(
      (await repo.hourTrend('6300100')).failureOrNull,
      isA<TimeoutFailure>(),
    );
  });

  test('a dropped connection folds into NetworkFailure', () async {
    final repo = RainHourTrendRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.connectionError)),
    );

    expect(
      (await repo.hourTrend('6300100')).failureOrNull,
      isA<NetworkFailure>(),
    );
  });

  test('a server error folds into NetworkFailure carrying the code', () async {
    final repo = RainHourTrendRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.badResponse, status: 503)),
    );

    final failure = (await repo.hourTrend('6300100')).failureOrNull;
    expect(
      failure,
      isA<NetworkFailure>().having(
        (f) => f.message,
        'message',
        contains('503'),
      ),
    );
  });

  test('a malformed transport response folds into DecodeFailure', () async {
    final repo = RainHourTrendRepositoryImpl(
      _FailingApi(const FormatException('bad json')),
    );

    expect(
      (await repo.hourTrend('6300100')).failureOrNull,
      isA<DecodeFailure>(),
    );
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      final repo = RainHourTrendRepositoryImpl(
        _FailingApi(StateError('no element')),
      );

      expect(
        (await repo.hourTrend('6300100')).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    },
  );

  test(
    "RainHourTrend's own malformed-series error folds into DecodeFailure too",
    () async {
      final api = _StubApi({
        'rainfallWarnings-x': [
          {'start': 1700000000, 'rain': List<int>.filled(5, 0)},
        ],
      });
      final repo = RainHourTrendRepositoryImpl(api);

      final result = await repo.hourTrend('6300100');

      expect(result.failureOrNull, isA<DecodeFailure>());
    },
  );

  test('hourTrend decodes the forecast and passes the code through', () async {
    final api = _StubApi({
      'rainfallWarnings-x': [
        {'start': 1700000000, 'rain': List<int>.filled(60, 0)},
      ],
    });
    final repo = RainHourTrendRepositoryImpl(api);

    final result = await repo.hourTrend('6300100');

    expect(result.valueOrNull?.startSecond, 1700000000);
    expect(api.codes, ['6300100']);
  });
}
