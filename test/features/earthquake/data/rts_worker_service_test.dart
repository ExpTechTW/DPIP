/// The lifecycle around the RTS worker: it starts on the first frame and only
/// once, and when it cannot start or stops, the frames it was handed are still
/// decoded and every later one goes back to the UI isolate — the path the feed
/// took before the worker existed. The station layer is only ever answered for
/// a frame the worker decoded; anything else is left to the monitor.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/data/rts_worker_service.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
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

  group('station layer', () {
    const stations = {
      'A1': SeismicStation(id: 'A1', latitude: 23.5, longitude: 121.2),
      'B2': SeismicStation(id: 'B2', latitude: 24.1, longitude: 120.9),
    };
    final icons = [for (var level = 0; level < 10; level++) 'icon-$level'];

    Future<String?> layerOf(RtsWorkerService service, Rts frame) => service
        .encode(frame, eventLit: true, eewActive: false, badgeIcons: icons);

    test('is built on the worker for a frame it decoded', () async {
      final service = RtsWorkerService(spawn: spawn)
        // Placed before the worker exists: it is handed over on start.
        ..placeStations(stations);
      final frame = (await service.decode(_payload(1)))!;

      expect(
        await layerOf(service, frame),
        encodeRtsStationGeoJson(
          frame.stations,
          stations,
          eventLit: true,
          eewActive: false,
          badgeIcons: icons,
        ),
      );
      service.dispose();
    });

    test('is left to the caller for any other frame', () async {
      final service = RtsWorkerService(spawn: spawn)..placeStations(stations);
      final decoded = (await service.decode(_payload(1)))!;

      expect(await layerOf(service, decodeRtsPayload(_payload(1))!), isNull);
      expect(await layerOf(service, const Rts()), isNull);
      expect(
        await layerOf(service, decoded.copyWith()),
        isNull,
        reason: 'an equal frame is still not the one the worker holds',
      );
      service.dispose();
    });

    test('is left to the caller once the worker stops', () async {
      final service = RtsWorkerService(spawn: spawn)..placeStations(stations);
      final frame = (await service.decode(_payload(1)))!;
      workers.single.dispose();
      await workers.single.stopped;
      await pumpEventQueue();

      expect(await layerOf(service, frame), isNull);
    });

    test('is left to the caller when the worker cannot start', () async {
      final service = RtsWorkerService(
        spawn: () async => throw StateError('no isolates here'),
      )..placeStations(stations);
      final frame = (await service.decode(_payload(1)))!;
      expect(await layerOf(service, frame), isNull);
    });
  });

  test('disposed while starting, the worker is let go at once', () async {
    final service = RtsWorkerService(spawn: spawn);
    final waiting = service.decode(_payload(1));
    service.dispose();

    expect((await waiting)?.time, 1);
    await workers.single.stopped;
  });
}
