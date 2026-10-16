/// The RTS worker isolate, run for real: a frame it decodes is the frame the
/// UI isolate would have decoded, a frame it cannot decode costs only that
/// frame, answers come back in the order they were asked, and a stopped
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
