/// The lifecycle around the RTS worker: it starts on the first frame and only
/// once, and when it cannot start or stops, the frames it was handed are still
/// decoded and every later one goes back to the UI isolate — the path the feed
/// took before the worker existed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/data/rts_worker_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _payload(int ts) => base64.encode(
  gzip.encode(
    utf8.encode(
      jsonEncode({
        'ts': ts,
        'stations': {
          'A1': {'i': 1.2, 'pga': 3.4},
          'B2': {'i': -0.5, 'alert': 1},
        },
      }),
    ),
  ),
);

void main() {
  final workers = <RtsWorker>[];
  var spawns = 0;

  Future<RtsWorker> spawn() async {
    spawns++;
    final worker = await RtsWorker.spawn();
    workers.add(worker);
    return worker;
  }

  setUp(() => spawns = 0);
  tearDown(() {
    for (final worker in workers) {
      worker.dispose();
    }
    workers.clear();
  });

  test('starts the worker on the first frame, and only once', () async {
    final service = RtsWorkerService(spawn: spawn);
    expect(spawns, 0, reason: 'nothing starts before a frame arrives');

    final frames = await Future.wait([
      service.decode(_payload(1))!,
      service.decode(_payload(2))!,
    ]);
    expect(spawns, 1);
    expect([for (final f in frames) f!.time], [1, 2]);
    expect(frames.first, decodeRtsPayload(_payload(1)));
    service.dispose();
  });

  test('a worker that cannot start leaves frames to the caller', () async {
    final service = RtsWorkerService(
      spawn: () async => throw StateError('no isolates here'),
    );

    final waiting = service.decode(_payload(1));
    expect(waiting, isNotNull, reason: 'not known to fail until it is tried');
    expect(
      (await waiting)?.time,
      1,
      reason: 'the frame that found out is decoded here, not lost',
    );
    expect(service.decode(_payload(2)), isNull, reason: 'the caller decodes');
  });

  test('a worker that stops hands its frames back', () async {
    final service = RtsWorkerService(spawn: spawn);
    expect((await service.decode(_payload(1)))?.time, 1);

    final inFlight = service.decode(_payload(2));
    workers.single.dispose();
    expect((await inFlight)?.time, 2, reason: 'decoded here instead');

    await workers.single.stopped;
    await pumpEventQueue();
    expect(service.decode(_payload(3)), isNull);
    expect(spawns, 1, reason: 'a stopped worker is not replaced');
  });

  test('dispose stops the worker and declines every later frame', () async {
    final service = RtsWorkerService(spawn: spawn);
    await service.decode(_payload(1));
    service.dispose();

    await workers.single.stopped;
    expect(service.decode(_payload(2)), isNull);
  });

  test('disposed while starting, the worker is let go at once', () async {
    final service = RtsWorkerService(spawn: spawn);
    final waiting = service.decode(_payload(1));
    service.dispose();

    expect((await waiting)?.time, 1);
    await workers.single.stopped;
  });
}
