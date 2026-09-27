/// [EewRepositoryImpl] guards every network/decode fault into a typed
/// [Failure] (never a thrown exception) and applies the two source-side
/// filters that decide which alerts even reach the UI: JMA is unconditionally
/// excluded, and `cwaOnly` — read fresh on every call, not captured once at
/// construction — narrows further to CWA only when the setting is on.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEarthquakeApi implements EarthquakeApi {
  dynamic nextEewRealtime;
  Object? error;

  @override
  Future<List<dynamic>> getEewRealtime() async {
    if (error != null) throw error!;
    return nextEewRealtime as List<dynamic>;
  }

  @override
  Stream<SseEvent> openTremSse({required bool live}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getRtsAt(int seconds) =>
      throw UnimplementedError();

  @override
  Stream<SseEvent> openEewSse() => throw UnimplementedError();

  @override
  Future<List<dynamic>> getEewAt(int seconds) => throw UnimplementedError();

  @override
  Future<List<dynamic>> getReportList({
    int limit = 50,
    int page = 1,
    int? minIntensity,
    int? maxIntensity,
    double? minMagnitude,
    double? maxMagnitude,
    double? minDepth,
    double? maxDepth,
    String? startTime,
    String? endTime,
    String? sort,
    String? order,
    String? city,
    int? cityMinInt,
    int? cityMaxInt,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> getReport(String reportId) => throw UnimplementedError();
}

Map<String, dynamic> _eewJson(String id, String author) => {
  'author': author,
  'id': id,
  'serial': 1,
  'status': 1,
  'final': 0,
  'eq': {
    'time': 1700000000000,
    'lon': 121.5,
    'lat': 24.0,
    'depth': 10.0,
    'mag': 5.0,
    'loc': '花蓮縣',
    'max': 4,
  },
};

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v2/eq/eew');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<void>(requestOptions: options, statusCode: status),
  );
}

void main() {
  late _FakeEarthquakeApi api;

  setUp(() {
    api = _FakeEarthquakeApi();
  });

  test('decodes every alert the api returns', () async {
    api.nextEewRealtime = [_eewJson('cwa-1', 'cwa'), _eewJson('cwa-2', 'cwa')];
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.valueOrNull!.map((e) => e.id), ['cwa-1', 'cwa-2']);
  });

  test('excludes JMA unconditionally, regardless of cwaOnly', () async {
    api.nextEewRealtime = [_eewJson('cwa-1', 'cwa'), _eewJson('jma-1', 'jma')];
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.valueOrNull!.map((e) => e.id), ['cwa-1']);
  });

  test(
    'cwaOnly=true additionally excludes every non-CWA, non-JMA source',
    () async {
      api.nextEewRealtime = [
        _eewJson('cwa-1', 'cwa'),
        _eewJson('other-1', 'someOtherAgency'),
        _eewJson('jma-1', 'jma'),
      ];
      final repo = EewRepositoryImpl(api, cwaOnly: () => true);

      final result = await repo.activeEews();

      expect(result.valueOrNull!.map((e) => e.id), ['cwa-1']);
    },
  );

  test('cwaOnly=false keeps every non-JMA source', () async {
    api.nextEewRealtime = [
      _eewJson('cwa-1', 'cwa'),
      _eewJson('other-1', 'someOtherAgency'),
    ];
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.valueOrNull!.map((e) => e.id), ['cwa-1', 'other-1']);
  });

  test(
    'cwaOnly is read fresh on every call, not captured at construction',
    () async {
      api.nextEewRealtime = [
        _eewJson('cwa-1', 'cwa'),
        _eewJson('other-1', 'x'),
      ];
      var only = false;
      final repo = EewRepositoryImpl(api, cwaOnly: () => only);

      final before = await repo.activeEews();
      expect(before.valueOrNull!.map((e) => e.id), ['cwa-1', 'other-1']);

      only = true;
      final after = await repo.activeEews();
      expect(after.valueOrNull!.map((e) => e.id), ['cwa-1']);
    },
  );

  test('a 404 folds into NotFoundFailure', () async {
    api.error = _dio(DioExceptionType.badResponse, status: 404);
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('a timeout folds into TimeoutFailure', () async {
    api.error = _dio(DioExceptionType.connectionTimeout);
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.failureOrNull, isA<TimeoutFailure>());
  });

  test('a dropped connection folds into NetworkFailure', () async {
    api.error = _dio(DioExceptionType.connectionError);
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('malformed JSON folds into DecodeFailure, not a crash', () async {
    api.error = const FormatException('unexpected token');
    final repo = EewRepositoryImpl(api, cwaOnly: () => false);

    final result = await repo.activeEews();

    expect(result.failureOrNull, isA<DecodeFailure>());
  });

  test(
    'a shape mismatch in one alert folds the whole batch into DecodeFailure',
    () async {
      api.nextEewRealtime = [
        {'author': 'cwa', 'id': 'bad', 'serial': 1, 'status': 1, 'final': 0},
      ];
      final repo = EewRepositoryImpl(api, cwaOnly: () => false);

      final result = await repo.activeEews();

      expect(result.failureOrNull, isA<DecodeFailure>());
    },
  );

  test(
    'anything else folds into UnexpectedFailure rather than escaping',
    () async {
      api.error = StateError('no element');
      final repo = EewRepositoryImpl(api, cwaOnly: () => false);

      final result = await repo.activeEews();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    },
  );
}
