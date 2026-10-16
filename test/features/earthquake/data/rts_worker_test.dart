/// The RTS worker isolate, run for real: a frame it decodes is the frame the
/// UI isolate would have decoded, the station layer it builds is the one the
/// UI isolate would have built, a frame it cannot handle costs only that
/// request, answers come back in the order they were asked, and a stopped
/// worker fails what it was still holding instead of leaving it waiting.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/shared/map/monitor_map_stack.dart';
import 'package:flutter_test/flutter_test.dart';

/// [json] as the TREM stream sends a frame: base64 over gzip over JSON.
String _payload(Object json) =>
    base64.encode(gzip.encode(utf8.encode(jsonEncode(json))));

Map<String, dynamic> _frame(int ts, {int stations = 300}) => {
  'ts': ts,
  'stations': {
    for (var n = 0; n < stations; n++)
      'S${n.toRadixString(16)}': {
        'i': (n % 40) / 10 - 1.5,
        if (n.isEven) 'pga': n / 7,
        if (n % 50 == 0) 'alert': 1,
      },
  },
};

/// A directory for [_frame]'s stations, leaving every seventh one out.
Map<String, SeismicStation> _directory({double shift = 0}) => {
  for (var n = 0; n < 300; n++)
    if (n % 7 != 0)
      'S${n.toRadixString(16)}': SeismicStation(
        id: 'S${n.toRadixString(16)}',
        latitude: 22 + n / 100 + shift,
        longitude: 120 + n / 150,
      ),
};

List<String> _icons({required bool dark}) => [
  for (var level = 0; level < 10; level++) monitorBadgeIcon(level, dark: dark),
];

void main() {
  late RtsWorker worker;

  setUp(() async => worker = await RtsWorker.spawn());
  tearDown(() => worker.dispose());

  test('decodes a frame into what the UI isolate would decode', () async {
    final payload = _payload(_frame(1790537637000));
    final source = RtsRealtimeSource(
      ({required live}) => const Stream<SseEvent>.empty(),
      demand: RtsLiveDemand(),
    );
    final here = source.decodeBytes(
      Uint8List.fromList(gzip.decode(base64.decode(payload))),
    );
    source.dispose();

    final decoded = await worker.decode(payload);
    expect(decoded, isNotNull);
    expect(decoded!.frame, here);
    expect(decoded.frame.stations, hasLength(300));
    expect(decoded.frame.stations['S0']?.alert, isTrue);
  });

  test('numbers each frame it decodes, in order', () async {
    final frames = await Future.wait([
      for (var ts = 1; ts <= 20; ts++) worker.decode(_payload(_frame(ts))),
    ]);
    expect(
      [for (final f in frames) f!.frame.time],
      [for (var t = 1; t <= 20; t++) t],
    );
    expect([for (final f in frames) f!.seq], [for (var s = 0; s < 20; s++) s]);
  });

  test('a frame with no payload decodes to nothing', () async {
    final empty = base64.encode(gzip.encode(const <int>[]));
    expect(await worker.decode(empty), isNull);
  });

  test('a frame that does not decode fails alone', () async {
    final bad = worker.decode('not base64 at all');
    final next = worker.decode(_payload(_frame(2)));
    await expectLater(bad, throwsA(isA<RemoteError>()));
    expect((await next)?.frame.time, 2);
  });

  test('a stopped worker fails what it held and what comes after', () async {
    final pending = worker.decode(_payload(_frame(1, stations: 3000)));
    worker.dispose();
    await expectLater(pending, throwsA(isA<RtsWorkerGone>()));
    await expectLater(
      worker.decode(_payload(_frame(2))),
      throwsA(isA<RtsWorkerGone>()),
    );
    await worker.stopped;
  });

  test('a worker that dies is stopped, not left waiting', () async {
    // Answered before the end landed, or failed by it — never left hanging.
    final outcome = worker
        .decode(_payload(_frame(1, stations: 3000)))
        .then<Object?>((_) => null, onError: (Object error) => error);
    worker.isolate.kill(priority: Isolate.immediate);
    await worker.stopped.timeout(const Duration(seconds: 5));
    final error = await outcome;
    if (error != null) expect(error, isA<RtsWorkerGone>());
    await expectLater(
      worker.decode(_payload(_frame(2))),
      throwsA(isA<RtsWorkerGone>()),
    );
  });

  group('station layer', () {
    test('is what the UI isolate builds from the same frame', () async {
      final stations = _directory();
      worker.placeStations(stations);
      final decoded = (await worker.decode(_payload(_frame(1))))!;
      for (final eventLit in [false, true]) {
        for (final eewActive in [false, true]) {
          for (final dark in [false, true]) {
            final encoded = await worker.encode(
              decoded.seq,
              eventLit: eventLit,
              eewActive: eewActive,
              badgeIcons: _icons(dark: dark),
            );
            final here = rtsStationGeoJson(
              decoded.frame.stations,
              stations,
              eventLit: eventLit,
              eewActive: eewActive,
              badgeIcons: _icons(dark: dark),
            );
            expect(encoded, jsonEncode(here));
          }
        }
      }
    });

    test('is placed against the directory given last', () async {
      final decoded = (await worker.decode(_payload(_frame(1))))!;
      Future<String?> layer() => worker.encode(
        decoded.seq,
        eventLit: false,
        eewActive: false,
        badgeIcons: _icons(dark: false),
      );
      expect(await layer(), jsonEncode(monitorEmptyCollection));

      final moved = _directory(shift: 0.5);
      worker.placeStations(_directory());
      worker.placeStations(moved);
      expect(
        await layer(),
        encodeRtsStationGeoJson(
          decoded.frame.stations,
          moved,
          eventLit: false,
          eewActive: false,
          badgeIcons: _icons(dark: false),
        ),
      );
    });

    test('is built from the newest frames and the last one built', () async {
      Future<String?> layer(int seq) => worker.encode(
        seq,
        eventLit: false,
        eewActive: false,
        badgeIcons: _icons(dark: false),
      );
      worker.placeStations(_directory());
      final first = (await worker.decode(_payload(_frame(1))))!;
      expect(await layer(first.seq), isNotNull);
      final later = [
        for (var ts = 2; ts <= 12; ts++)
          (await worker.decode(_payload(_frame(ts))))!,
      ];

      expect(await layer(first.seq), isNotNull, reason: 'the last one built');
      expect(await layer(later.first.seq), isNull, reason: 'let go');
      expect(await layer(later.last.seq), isNotNull, reason: 'the newest');
      expect(await layer(9999), isNull, reason: 'never decoded');
    });

    test('a directory it cannot write fails that request alone', () async {
      final decoded = (await worker.decode(_payload(_frame(1))))!;
      worker.placeStations({
        'S1': const SeismicStation(id: 'S1', latitude: 23, longitude: 1 / 0),
      });
      await expectLater(
        worker.encode(
          decoded.seq,
          eventLit: false,
          eewActive: false,
          badgeIcons: _icons(dark: false),
        ),
        throwsA(isA<RemoteError>()),
      );
      worker.placeStations(_directory());
      expect(
        await worker.encode(
          decoded.seq,
          eventLit: false,
          eewActive: false,
          badgeIcons: _icons(dark: false),
        ),
        isNotNull,
      );
    });
  });

  test('the payload decoder matches the stream source exactly', () {
    final payload = _payload(_frame(7));
    final source = RtsRealtimeSource(
      ({required live}) => const Stream<SseEvent>.empty(),
      demand: RtsLiveDemand(),
    );
    expect(
      decodeRtsPayload(' $payload\n'),
      source.decodeBytes(
        Uint8List.fromList(gzip.decode(base64.decode(payload))),
      ),
    );
    source.dispose();
    expect(decodeRtsPayload(base64.encode(gzip.encode(const <int>[]))), isNull);
  });

  test('frames survive the trip as the domain types', () async {
    final decoded = await worker.decode(_payload(_frame(3)));
    expect(decoded!.frame, isA<Rts>());
    expect(decoded.frame.stations.values.first, isA<RtsStation>());
    expect(
      sameRtsFrame(decoded.frame, decodeRtsPayload(_payload(_frame(3)))),
      isTrue,
    );
  });
}
