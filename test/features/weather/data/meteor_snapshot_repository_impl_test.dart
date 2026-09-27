/// The base impl every meteor snapshot repository (weather / rain / lightning)
/// shares for latest / history / at: a transport or decode fault must leave as
/// a typed [Failure], never an uncaught exception or a silently empty result —
/// for a dataset like rain or lightning, swallowing a dead source's error
/// would read as "nothing is happening" rather than "we don't know". A
/// subclass only supplies [MeteorSnapshotRepositoryImpl.decodeSnapshot], so
/// this is the one place that proves the shared trio itself — not a
/// subclass's own decode — holds the `guardResult` contract, mirroring how
/// the typhoon repository's own test proves the same contract for typhoon's
/// (unrelated) endpoint set.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal concrete snapshot, so the base class is tested in isolation from
/// any real dataset's own decode (weather/rain/lightning each supply theirs).
class _TestSnapshot {
  const _TestSnapshot(this.value);

  final int value;
}

class _TestRepository extends MeteorSnapshotRepositoryImpl<_TestSnapshot> {
  const _TestRepository(super.api);

  @override
  _TestSnapshot decodeSnapshot(Map<String, dynamic> json) =>
      _TestSnapshot(json['value'] as int);
}

/// Every dataset answers with the same fault, so one loop can hold latest /
/// history / at to the contract instead of three near-identical tests.
class _FailingApi implements MeteorSnapshotApi {
  _FailingApi(this.error);

  final Object error;

  @override
  Future<Map<String, dynamic>> getLatest() async => throw error;

  @override
  Future<List<dynamic>> getList() async => throw error;

  @override
  Future<Map<String, dynamic>> getAt(int second) async => throw error;

  @override
  Future<Map<String, dynamic>> getStation() async => throw error;

  @override
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      throw error;
}

/// Answers latest/list/at with scripted data and records the arguments [at]
/// was called with.
class _StubApi implements MeteorSnapshotApi {
  _StubApi({this.latestJson, this.listJson, this.atJson});

  final Map<String, dynamic>? latestJson;
  final List<dynamic>? listJson;
  final Map<String, dynamic>? atJson;
  final List<int> atSeconds = [];

  @override
  Future<Map<String, dynamic>> getLatest() async => latestJson!;

  @override
  Future<List<dynamic>> getList() async => listJson!;

  @override
  Future<Map<String, dynamic>> getAt(int second) async {
    atSeconds.add(second);
    return atJson!;
  }

  @override
  Future<Map<String, dynamic>> getStation() async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getTrend(String id, String range) async =>
      throw UnimplementedError();
}

/// The three shared methods, as calls, so a fault can be held against every
/// one.
final Map<String, Future<Result<Object?>> Function(_TestRepository)> _calls = {
  'latest': (repo) => repo.latest(),
  'history': (repo) => repo.history(),
  'at': (repo) => repo.at(0),
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
  final repo = _TestRepository(_FailingApi(error));

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
    final repo = _TestRepository(
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

  test('latest decodes the raw payload via decodeSnapshot', () async {
    final api = _StubApi(latestJson: {'value': 7});

    final result = await _TestRepository(api).latest();

    expect(result.valueOrNull?.value, 7);
  });

  test('history restores the delta axis to absolute seconds', () async {
    final api = _StubApi(listJson: [1000, 5, 5, 0]);

    final result = await _TestRepository(api).history();

    expect(result.valueOrNull, [1000, 1005, 1010, 1010]);
  });

  test('at decodes the historical snapshot for the requested second', () async {
    final api = _StubApi(atJson: {'value': 9});

    final result = await _TestRepository(api).at(1700000000);

    expect(result.valueOrNull?.value, 9);
    expect(api.atSeconds, [1700000000]);
  });
}
