/// The lightning repository's contract: a transport or decode fault leaves as
/// a typed [Failure], never a thrown exception or a silently empty strike
/// layer — lightning has no station directory to fall back on, so a fault
/// swallowed here would just show a map with no strikes, indistinguishable
/// from a quiet sky. Only three methods, all inherited from the shared
/// snapshot base, plus this class's own `LightningSnapshot.decode` wiring —
/// both are exercised here even though the base class's own generic
/// behaviour already has its own test.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/data/meteor_lightning_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every dataset answers with the same fault, so one loop can hold all three
/// methods to the contract instead of three near-identical tests.
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

class _StubApi implements MeteorSnapshotApi {
  _StubApi({this.latestJson, this.listJson, this.atJson});

  final Map<String, dynamic>? latestJson;
  final List<dynamic>? listJson;
  final Map<String, dynamic>? atJson;

  @override
  Future<Map<String, dynamic>> getLatest() async => latestJson!;

  @override
  Future<List<dynamic>> getList() async => listJson!;

  @override
  Future<Map<String, dynamic>> getAt(int second) async => atJson!;

  @override
  Future<Map<String, dynamic>> getStation() async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      throw UnimplementedError();
}

/// The three methods, as calls, so a fault can be held against every one.
final Map<
  String,
  Future<Result<Object?>> Function(MeteorLightningRepositoryImpl)
>
_calls = {
  'latest': (repo) => repo.latest(),
  'history': (repo) => repo.history(),
  'at': (repo) => repo.at(0),
};

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v5/meteor/lightning');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

Future<void> _expectEveryCallFailsWith(Object error, Matcher failure) async {
  final repo = MeteorLightningRepositoryImpl(_FailingApi(error));

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
    final repo = MeteorLightningRepositoryImpl(
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

  test('latest decodes strikes via LightningSnapshot.decode', () async {
    final api = _StubApi(
      latestJson: {
        'time': 1700000000,
        'type': [1],
        't': [1700000000],
        'lat': [24.5],
        'lon': [121.7],
      },
    );

    final result = await MeteorLightningRepositoryImpl(api).latest();

    expect(result.valueOrNull?.time, 1700000000);
    expect(result.valueOrNull?.strikes.single.type, 1);
  });

  test('history restores the delta axis to absolute seconds', () async {
    final api = _StubApi(listJson: [1000, 5, 5, 0]);

    final result = await MeteorLightningRepositoryImpl(api).history();

    expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
  });

  test('at decodes the historical snapshot for the requested second', () async {
    final api = _StubApi(
      atJson: {
        'time': 1700000000,
        'type': [0],
        't': [1700000000],
        'lat': [22.6],
        'lon': [120.3],
      },
    );

    final result = await MeteorLightningRepositoryImpl(api).at(1700000000);

    expect(result.valueOrNull?.strikes.single.type, 0);
  });
}
