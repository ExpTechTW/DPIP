/// The rain repository's contract: a transport or decode fault leaves as a
/// typed [Failure], never a thrown exception or a silently empty reading —
/// rain accumulation feeds the flood-warning surface, so a dead source read
/// as "zero rain" would be actively wrong, not merely unhelpful. Five methods
/// (three inherited from the shared snapshot base, two of its own) make this
/// easy to wire four and forget the fifth, so every one is exercised against
/// the same fault, plus the two decodes this class supplies itself: the
/// station directory and `RainSnapshot`/`RainTrend`'s own field-array decode.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/data/meteor_rain_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every dataset answers with the same fault, so one loop can hold all five
/// methods to the contract instead of five near-identical tests.
class _FailingApi implements MeteorSnapshotApi {
  _FailingApi(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> getStation() async => throw error;

  @override
  Future<Map<String, dynamic>> getLatest() async => throw error;

  @override
  Future<List<dynamic>> getList() async => throw error;

  @override
  Future<Map<String, dynamic>> getAt(int second) async => throw error;

  @override
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      throw error;
}

/// Answers with scripted data and records the arguments [getTrend] was called
/// with.
class _StubApi implements MeteorSnapshotApi {
  _StubApi({
    this.stationJson,
    this.latestJson,
    this.listJson,
    this.atJson,
    this.trendJson,
  });

  final Map<String, dynamic>? stationJson;
  final Map<String, dynamic>? latestJson;
  final List<dynamic>? listJson;
  final Map<String, dynamic>? atJson;
  final Map<String, dynamic>? trendJson;
  final List<(String, String)> trendArgs = [];

  @override
  Future<Map<String, dynamic>> getStation() async => stationJson!;

  @override
  Future<Map<String, dynamic>> getLatest() async => latestJson!;

  @override
  Future<List<dynamic>> getList() async => listJson!;

  @override
  Future<Map<String, dynamic>> getAt(int second) async => atJson!;

  @override
  Future<Map<String, dynamic>> getTrend(String id, String range) async {
    trendArgs.add((id, range));
    return trendJson!;
  }
}

/// The five methods, as calls, so a fault can be held against every one.
final Map<String, Future<Result<Object?>> Function(MeteorRainRepositoryImpl)>
_calls = {
  'stations': (repo) => repo.stations(),
  'latest': (repo) => repo.latest(),
  'history': (repo) => repo.history(),
  'at': (repo) => repo.at(0),
  'trend': (repo) => repo.trend('C0A940'),
};

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v5/meteor/rain');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = MeteorRainRepositoryImpl(_FailingApi(error));

  for (final entry in _calls.entries) {
    final result = await entry.value(repo);
    expect(result.failureOrNull, failure, reason: entry.key);
    expect(result.valueOrNull, isNull, reason: entry.key);
  }
}

void main() {
  test('a 404 folds into NotFoundFailure, not a crash', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.badResponse, status: 404),
      isA<NotFoundFailure>(),
    );
  });

  test('a timeout folds into TimeoutFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionTimeout),
      isA<TimeoutFailure>(),
    );
  });

  test('a dropped connection folds into NetworkFailure', () async {
    await _expectEveryCallFailsWith(
      _dio(DioExceptionType.connectionError),
      isA<NetworkFailure>(),
    );
  });

  test('a server error folds into NetworkFailure carrying the code', () async {
    final repo = MeteorRainRepositoryImpl(
      _FailingApi(_dio(DioExceptionType.badResponse, status: 503)),
    );

    final failure = (await repo.latest()).failureOrNull;
    expect(
      failure,
      isA<NetworkFailure>().having(
        (f) => f.message,
        'message',
        contains('503'),
      ),
    );
  });

  test('malformed JSON folds into DecodeFailure', () async {
    await _expectEveryCallFailsWith(
      const FormatException('unexpected token'),
      isA<DecodeFailure>(),
    );
  });

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      await _expectEveryCallFailsWith(
        StateError('no element'),
        isA<UnexpectedFailure>(),
      );
    },
  );

  test('stations decodes the directory keyed by station code', () async {
    final api = _StubApi(
      stationJson: {
        'C0A940': {
          'n': 'Taipei',
          'c': 'Taipei City',
          't': 'Zhongzheng',
          'alt': 5.0,
          'lat': 25.033,
          'lon': 121.5654,
        },
      },
    );

    final result = await MeteorRainRepositoryImpl(api).stations();

    expect(result.valueOrNull?['C0A940']?.name, 'Taipei');
  });

  test(
    'latest decodes the field-array snapshot via RainSnapshot.decode',
    () async {
      final api = _StubApi(
        latestJson: {
          'time': 1700000000,
          'ids': ['C0A940'],
          'now': [1.2],
        },
      );

      final result = await MeteorRainRepositoryImpl(api).latest();

      expect(result.valueOrNull?.time, 1700000000);
      expect(result.valueOrNull?.stations.single.now, 1.2);
    },
  );

  test('history restores the delta axis to absolute seconds', () async {
    final api = _StubApi(listJson: [1000, 5, 5, 0]);

    final result = await MeteorRainRepositoryImpl(api).history();

    expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
  });

  test(
    'at decodes the historical rain snapshot for the requested second',
    () async {
      final api = _StubApi(
        atJson: {
          'time': 1700000000,
          'ids': ['C0A940'],
          'now': [0.8],
        },
      );

      final result = await MeteorRainRepositoryImpl(api).at(1700000000);

      expect(result.valueOrNull?.time, 1700000000);
      expect(result.valueOrNull?.stations.single.now, 0.8);
    },
  );

  test(
    'trend decodes the series and passes id/range through unmodified',
    () async {
      final api = _StubApi(
        trendJson: {
          'id': 'C0A940',
          'range': '7d',
          'ts': [1700000000],
          'rain': [0.4],
        },
      );

      final result = await MeteorRainRepositoryImpl(api)
          .trend('C0A940', range: '7d');

      expect(result.valueOrNull?.range, '7d');
      expect(result.valueOrNull?.rain, [0.4]);
      expect(api.trendArgs, [('C0A940', '7d')]);
    },
  );
}
