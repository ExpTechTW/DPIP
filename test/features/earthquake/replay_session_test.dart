/// Assembles exactly the pair of realtime channels a replay page needs: a
/// [ReplayClock] anchored at the requested instant, shared by an RTS and an
/// EEW channel so both replay the same simulated "now", wrapped in the same
/// [RtsRealtimeController]/[EewRealtimeController] the live feed uses so the
/// UI cannot tell replay and live apart.
///
/// The channels are built with the real system ticker/elapsed (not
/// injectable from here — see `replay_session.dart`), so this test cannot
/// drive staleness or poll cadence deterministically; that is already
/// [RealtimeChannel]'s own well-covered contract. What it verifies instead is
/// the wiring: the clock is anchored correctly, [start] actually reaches the
/// api, and [dispose] is safe to call exactly once.
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
import 'package:dpip/features/earthquake/replay_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _RecordingApiClient implements ApiClient {
  final List<String> paths = [];

  @override
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    paths.add(path);
    if (path.contains('/trem/rts')) return <String, dynamic>{};
    if (path.contains('/eq/eew')) return <dynamic>[];
    return null;
  }

  @override
  Future<BytePayload> getBytes(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<BytePayload> getBytesAbsolute(
    String url, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> getAbsolute(
    String url, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> postAbsolute(
    String url, {
    Object? data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> post(
    ApiTier tier,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> request(
    ApiTier tier,
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<StreamedResponse> openStream(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) => throw UnimplementedError();

  @override
  List<String> hostsFor(ApiTier tier) => throw UnimplementedError();
}

Future<void> pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _RecordingApiClient apiClient;
  late Clock serverClock;

  setUp(() {
    apiClient = _RecordingApiClient();
    serverClock = _FixedClock(DateTime.utc(2026, 1, 1));
  });

  test('clock is anchored at the requested replay instant', () {
    final replayAt = DateTime.utc(2026, 4, 3, 12, 30);
    final session = ReplaySession(
      apiClient,
      serverClock,
      replayAt.millisecondsSinceEpoch,
      cwaOnly: () => false,
    );
    addTearDown(session.dispose);

    expect(session.clock.now().difference(replayAt).inSeconds, 0);
  });

  test(
    'rts and eew start in the connecting state before start() is called',
    () {
      final session = ReplaySession(
        apiClient,
        serverClock,
        DateTime.utc(2026, 4, 3).millisecondsSinceEpoch,
        cwaOnly: () => false,
      );
      addTearDown(session.dispose);

      expect(session.rts.state.status, RealtimeStatus.connecting);
      expect(session.eew.state.status, RealtimeStatus.connecting);
    },
  );

  test('start() reaches the api for both feeds', () async {
    final session = ReplaySession(
      apiClient,
      serverClock,
      DateTime.utc(2026, 4, 3).millisecondsSinceEpoch,
      cwaOnly: () => false,
    );
    addTearDown(session.dispose);

    session.start();
    await pump();

    expect(apiClient.paths.any((p) => p.contains('/trem/rts')), isTrue);
    expect(apiClient.paths.any((p) => p.contains('/eq/eew')), isTrue);
  });

  test('pause and resume do not throw', () async {
    final session = ReplaySession(
      apiClient,
      serverClock,
      DateTime.utc(2026, 4, 3).millisecondsSinceEpoch,
      cwaOnly: () => false,
    );
    addTearDown(session.dispose);
    session.start();
    await pump();

    expect(session.pause, returnsNormally);
    expect(session.resume, returnsNormally);
  });

  test('dispose is safe to call exactly once', () {
    final session = ReplaySession(
      apiClient,
      serverClock,
      DateTime.utc(2026, 4, 3).millisecondsSinceEpoch,
      cwaOnly: () => false,
    );

    expect(session.dispose, returnsNormally);
  });
}
