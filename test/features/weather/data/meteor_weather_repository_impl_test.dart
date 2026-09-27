/// The weather repository's contract: a transport or decode fault leaves as a
/// typed [Failure], never a thrown exception — a weather panel that went
/// silently blank on a dead source would look identical to "nothing to
/// report". Seven methods (three inherited from the shared snapshot base,
/// four of its own) make it easy to wire six and forget one, so every one is
/// exercised against the same fault. `realtime` also has its own non-failure
/// special case worth its own test: the API answers `{}` for a coordinate
/// outside Taiwan, and that must decode to `Ok(null)`, not a [DecodeFailure]
/// and not a thrown cast error.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingSnapshotApi implements MeteorSnapshotApi {
  _FailingSnapshotApi(this.error);

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

/// Every dataset and both of the weather-only endpoints answer with the same
/// fault, so one loop can hold all seven methods to the contract.
class _FailingWeatherApi implements MeteorWeatherApi {
  _FailingWeatherApi(this.error);

  final Object error;

  @override
  MeteorSnapshotApi get snapshots => _FailingSnapshotApi(error);

  @override
  Future<Map<String, dynamic>> getRealtime(
    double latitude,
    double longitude,
  ) async => throw error;

  @override
  Future<Map<String, dynamic>> getForecast(String code) async => throw error;
}

class _StubSnapshotApi implements MeteorSnapshotApi {
  _StubSnapshotApi({
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

/// Answers the two weather-only endpoints with scripted data, and records the
/// coordinates [getRealtime] was called with.
class _StubWeatherApi implements MeteorWeatherApi {
  _StubWeatherApi({
    MeteorSnapshotApi? snapshots,
    this.realtimeJson,
    this.forecastJson,
  }) : snapshots = snapshots ?? _StubSnapshotApi();

  @override
  final MeteorSnapshotApi snapshots;
  final Map<String, dynamic>? realtimeJson;
  final Map<String, dynamic>? forecastJson;
  final List<(double, double)> realtimeArgs = [];

  @override
  Future<Map<String, dynamic>> getRealtime(
    double latitude,
    double longitude,
  ) async {
    realtimeArgs.add((latitude, longitude));
    return realtimeJson!;
  }

  @override
  Future<Map<String, dynamic>> getForecast(String code) async => forecastJson!;
}

/// The seven methods, as calls, so a fault can be held against every one.
final Map<String, Future<Result<Object?>> Function(MeteorWeatherRepositoryImpl)>
_calls = {
  'stations': (repo) => repo.stations(),
  'latest': (repo) => repo.latest(),
  'history': (repo) => repo.history(),
  'at': (repo) => repo.at(0),
  'trend': (repo) => repo.trend('C0A940'),
  'realtime': (repo) => repo.realtime(25.0, 121.5),
  'forecast': (repo) => repo.forecast('6300100'),
};

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v5/meteor/weather');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = MeteorWeatherRepositoryImpl(_FailingWeatherApi(error));

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
    final repo = MeteorWeatherRepositoryImpl(
      _FailingWeatherApi(_dio(DioExceptionType.badResponse, status: 503)),
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
    final api = _StubWeatherApi(
      snapshots: _StubSnapshotApi(
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
      ),
    );

    final result = await MeteorWeatherRepositoryImpl(api).stations();

    expect(result.valueOrNull?['C0A940']?.name, 'Taipei');
  });

  test(
    'latest decodes the field-array snapshot via WeatherSnapshot.decode',
    () async {
      final api = _StubWeatherApi(
        snapshots: _StubSnapshotApi(
          latestJson: {
            'time': 1700000000,
            'ids': ['C0A940'],
          },
        ),
      );

      final result = await MeteorWeatherRepositoryImpl(api).latest();

      expect(result.valueOrNull?.time, 1700000000);
      expect(result.valueOrNull?.stations.single.id, 'C0A940');
    },
  );

  test('history restores the delta axis to absolute seconds', () async {
    final api = _StubWeatherApi(
      snapshots: _StubSnapshotApi(listJson: [1000, 5, 5, 0]),
    );

    final result = await MeteorWeatherRepositoryImpl(api).history();

    expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
  });

  test(
    'at decodes the historical weather snapshot for the requested second',
    () async {
      final api = _StubWeatherApi(
        snapshots: _StubSnapshotApi(
          atJson: {
            'time': 1700000000,
            'ids': ['C0A940'],
          },
        ),
      );

      final result = await MeteorWeatherRepositoryImpl(api).at(1700000000);

      expect(result.valueOrNull?.time, 1700000000);
      expect(result.valueOrNull?.stations.single.id, 'C0A940');
    },
  );

  test(
    'trend decodes the series and passes id/range through unmodified',
    () async {
      final snapshots = _StubSnapshotApi(
        trendJson: {
          'id': 'C0A940',
          'range': '7d',
          'ts': [1700000000],
          'temp': [25.5],
        },
      );
      final api = _StubWeatherApi(snapshots: snapshots);

      final result = await MeteorWeatherRepositoryImpl(api)
          .trend('C0A940', range: '7d');

      expect(result.valueOrNull?.range, '7d');
      expect(result.valueOrNull?.temperature, [25.5]);
      expect(snapshots.trendArgs, [('C0A940', '7d')]);
    },
  );

  test('forecast decodes the township series', () async {
    final api = _StubWeatherApi(
      forecastJson: {
        'updateTime': 1700000000000,
        'forecast': [
          {
            'time': '14:00',
            'temperature': 25.0,
            'apparentTemp': 26.0,
            'humidity': 60,
            'weather': '多雲',
            'weatherCode': 200,
            'pop': 10,
            'wind': {'direction': 'NE', 'speed': 2.0, 'beaufort': 2},
          },
        ],
      },
    );

    final result = await MeteorWeatherRepositoryImpl(api).forecast('6300100');

    expect(result.valueOrNull?.updateTime, 1700000000000);
    expect(result.valueOrNull?.forecast.single.time, '14:00');
  });

  test(
    'realtime decodes the nearest station for a coordinate inside Taiwan',
    () async {
      final api = _StubWeatherApi(
        realtimeJson: {
          'id': 'C0A94',
          'station': {
            'name': 'Taipei',
            'lat': 25.03,
            'lon': 121.56,
            'altitude': 5.0,
            'distance': 1.2,
          },
          'time': 1700000000,
          'data': {
            'weather': '多雲',
            'weatherCode': 200,
            'temperature': 25.5,
            'humidity': 60,
            'rain': 0,
            'wind': {'speed': 2.5, 'beaufort': 2},
            'gust': {'speed': 5.0, 'beaufort': 3},
            'pressure': 1013.2,
          },
        },
      );

      final result = await MeteorWeatherRepositoryImpl(api)
          .realtime(25.033, 121.5654);

      // The 5-char station code from the realtime endpoint is padded to the
      // 6-char form used everywhere else (the station directory, trend, …).
      expect(result.valueOrNull?.id, 'C0A940');
      expect(api.realtimeArgs, [(25.033, 121.5654)]);
    },
  );

  test(
    "realtime outside Taiwan (the API's {}) is Ok(null), not a decode failure",
    () async {
      final api = _StubWeatherApi(realtimeJson: const {});

      final result = await MeteorWeatherRepositoryImpl(api).realtime(0, 0);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    },
  );
}
