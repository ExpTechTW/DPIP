/// Replays the RTS feed at a fixed instant: each [RtsReplaySource.fetch]
/// converts the replay clock's current second into the same
/// `EarthquakeApi.getRtsAt` call the live map would never make, decodes the
/// same [Rts] shape the live feed uses, and — the one behaviour a plain live
/// source doesn't need — treats "no snapshot that far back" as an ignorable
/// answer rather than a fault, so an old replay doesn't file a crash report
/// once a second for its whole length.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/rts_replay_source.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _FakeEarthquakeApi implements EarthquakeApi {
  dynamic nextRtsAt;
  Object? error;
  int? lastSeconds;

  @override
  Future<Map<String, dynamic>> getRtsAt(int seconds) async {
    lastSeconds = seconds;
    if (error != null) throw error!;
    return nextRtsAt as Map<String, dynamic>;
  }

  @override
  Stream<SseEvent> openTremSse({required bool live}) =>
      throw UnimplementedError();

  @override
  Future<List<dynamic>> getEewRealtime() => throw UnimplementedError();

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

DioException _dio(DioExceptionType type, {int? status}) {
  final options = RequestOptions(path: '/api/v2/trem/rts');
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
  late RtsReplaySource source;

  setUp(() {
    api = _FakeEarthquakeApi();
    elapsed = _FakeElapsed();
    clock = ReplayClock(DateTime.utc(2026, 4, 3, 12), elapsed: elapsed);
    source = RtsReplaySource(api, clock);
  });

  test('fetch asks for the whole second the replay clock is at', () async {
    api.nextRtsAt = {'ts': 1000};
    elapsed.value = const Duration(seconds: 90, milliseconds: 400);

    await source.fetch();

    final expectedSeconds =
        DateTime.utc(
          2026,
          4,
          3,
          12,
        ).add(const Duration(seconds: 90)).millisecondsSinceEpoch ~/
        1000;
    expect(api.lastSeconds, expectedSeconds);
  });

  test('decodes an archived rts.v1 frame into Rts', () async {
    api.nextRtsAt = {
      'source': 'core-tnn1',
      'ts': 1700000000000,
      'stations': {
        '11DFDBC': {'i': 3.0, 'pga': 1.0, 'alert': 1},
      },
      'eq': <dynamic>[],
    };

    final result = await source.fetch();

    final rts = result.valueOrNull!;
    expect(rts.time, 1700000000000);
    expect(rts.stations['11DFDBC']!.intensity, 3.0);
    expect(rts.stations['11DFDBC']!.alert, isTrue);
  });

  test(
    'timestampOf is always null — freshness is liveness, not payload age',
    () {
      final rts = Rts(time: 999999);
      expect(source.timestampOf(rts), isNull);
    },
  );

  test('isIgnorableFailure is true only for NotFoundFailure', () {
    expect(source.isIgnorableFailure(const NotFoundFailure('x')), isTrue);
    expect(source.isIgnorableFailure(const NetworkFailure('x')), isFalse);
    expect(source.isIgnorableFailure(const TimeoutFailure('x')), isFalse);
    expect(source.isIgnorableFailure(const DecodeFailure('x')), isFalse);
  });

  test(
    'a 404 (no snapshot that far back) folds into NotFoundFailure',
    () async {
      api.error = _dio(DioExceptionType.badResponse, status: 404);

      final result = await source.fetch();

      expect(result.failureOrNull, isA<NotFoundFailure>());
    },
  );

  test('a timeout folds into TimeoutFailure', () async {
    api.error = _dio(DioExceptionType.connectionTimeout);

    final result = await source.fetch();

    expect(result.failureOrNull, isA<TimeoutFailure>());
  });

  test('a dropped connection folds into NetworkFailure', () async {
    api.error = _dio(DioExceptionType.connectionError);

    final result = await source.fetch();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('malformed JSON folds into DecodeFailure', () async {
    api.error = const FormatException('bad token');

    final result = await source.fetch();

    expect(result.failureOrNull, isA<DecodeFailure>());
  });

  test('anything else folds into UnexpectedFailure', () async {
    api.error = StateError('boom');

    final result = await source.fetch();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
