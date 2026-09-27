/// Replays the EEW feed at a fixed instant — the [RtsReplaySource]'s sibling,
/// sharing the same JMA/`cwaOnly` filtering [EewRepositoryImpl] applies live,
/// but pointed at [EarthquakeApi.getEewAt] and, deliberately, NOT treating a
/// missing-history 404 as ignorable the way the RTS replay does: this source
/// takes [RealtimeSource]'s default (every failure counts), so a change here
/// is a decision, not something that could slip by unnoticed.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_replay_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _FakeEarthquakeApi implements EarthquakeApi {
  dynamic nextEewAt;
  Object? error;
  int? lastSeconds;

  @override
  Future<List<dynamic>> getEewAt(int seconds) async {
    lastSeconds = seconds;
    if (error != null) throw error!;
    return nextEewAt as List<dynamic>;
  }

  @override
  Stream<SseEvent> openTremSse({required bool live}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getRtsAt(int seconds) =>
      throw UnimplementedError();

  @override
  Future<List<dynamic>> getEewRealtime() => throw UnimplementedError();

  @override
  Stream<SseEvent> openEewSse() => throw UnimplementedError();

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
  late _FakeElapsed elapsed;
  late ReplayClock clock;

  setUp(() {
    api = _FakeEarthquakeApi();
    elapsed = _FakeElapsed();
    clock = ReplayClock(DateTime.utc(2026, 4, 3, 12), elapsed: elapsed);
  });

  test('fetch asks for the whole second the replay clock is at', () async {
    api.nextEewAt = <dynamic>[];
    elapsed.value = const Duration(seconds: 42, milliseconds: 900);
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    await source.fetch();

    final expectedSeconds =
        DateTime.utc(
          2026,
          4,
          3,
          12,
        ).add(const Duration(seconds: 42)).millisecondsSinceEpoch ~/
        1000;
    expect(api.lastSeconds, expectedSeconds);
  });

  test('decodes every alert the api returns', () async {
    api.nextEewAt = [_eewJson('cwa-1', 'cwa'), _eewJson('cwa-2', 'cwa')];
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    final result = await source.fetch();

    expect(result.valueOrNull!.map((e) => e.id), ['cwa-1', 'cwa-2']);
  });

  test('excludes JMA unconditionally, regardless of cwaOnly', () async {
    api.nextEewAt = [_eewJson('cwa-1', 'cwa'), _eewJson('jma-1', 'jma')];
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    final result = await source.fetch();

    expect(result.valueOrNull!.map((e) => e.id), ['cwa-1']);
  });

  test(
    'cwaOnly=true additionally excludes every non-CWA, non-JMA source',
    () async {
      api.nextEewAt = [_eewJson('cwa-1', 'cwa'), _eewJson('other-1', 'x')];
      final source = EewReplaySource(api, clock, cwaOnly: () => true);

      final result = await source.fetch();

      expect(result.valueOrNull!.map((e) => e.id), ['cwa-1']);
    },
  );

  test('cwaOnly is read fresh on every call', () async {
    api.nextEewAt = [_eewJson('cwa-1', 'cwa'), _eewJson('other-1', 'x')];
    var only = false;
    final source = EewReplaySource(api, clock, cwaOnly: () => only);

    final before = await source.fetch();
    expect(before.valueOrNull!.map((e) => e.id), ['cwa-1', 'other-1']);

    only = true;
    final after = await source.fetch();
    expect(after.valueOrNull!.map((e) => e.id), ['cwa-1']);
  });

  test(
    'timestampOf is always null — freshness is feed liveness, not payload age',
    () {
      final source = EewReplaySource(api, clock, cwaOnly: () => false);
      expect(source.timestampOf(const <Eew>[]), isNull);
    },
  );

  test('sameData compares element-wise, not by list identity', () {
    final source = EewReplaySource(api, clock, cwaOnly: () => false);
    final a = [Eew.fromJson(_eewJson('cwa-1', 'cwa'))];
    final b = [Eew.fromJson(_eewJson('cwa-1', 'cwa'))];
    final c = [Eew.fromJson(_eewJson('cwa-2', 'cwa'))];

    expect(identical(a, b), isFalse);
    expect(source.sameData(a, b), isTrue);
    expect(source.sameData(a, c), isFalse);
  });

  test('isIgnorableFailure defaults to false, unlike the RTS replay', () {
    final source = EewReplaySource(api, clock, cwaOnly: () => false);
    expect(source.isIgnorableFailure(const NotFoundFailure('x')), isFalse);
  });

  test(
    'a 404 still folds into NotFoundFailure (recorded, just not ignored)',
    () async {
      api.error = _dio(DioExceptionType.badResponse, status: 404);
      final source = EewReplaySource(api, clock, cwaOnly: () => false);

      final result = await source.fetch();

      expect(result.failureOrNull, isA<NotFoundFailure>());
    },
  );

  test('a timeout folds into TimeoutFailure', () async {
    api.error = _dio(DioExceptionType.connectionTimeout);
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    final result = await source.fetch();

    expect(result.failureOrNull, isA<TimeoutFailure>());
  });

  test('malformed JSON folds into DecodeFailure', () async {
    api.error = const FormatException('bad token');
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    final result = await source.fetch();

    expect(result.failureOrNull, isA<DecodeFailure>());
  });

  test('anything else folds into UnexpectedFailure', () async {
    api.error = StateError('boom');
    final source = EewReplaySource(api, clock, cwaOnly: () => false);

    final result = await source.fetch();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
