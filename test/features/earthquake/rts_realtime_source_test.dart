/// The live RTS source on the TREM stream: which frames it reads, and its two
/// speeds.
///
/// The speeds are the part that fails quietly. Asleep, the server sends a
/// frame only while a station alerts, so silence is the calm answer — a source
/// that read it as a dead feed would show the monitor "offline" between every
/// earthquake. Live, silence is a fault, and a source that kept answering calm
/// would present a frozen feed as a quiet one. And the switch between them has
/// to reach the server: a change of speed that never reopened the connection
/// would leave the monitor on alert-only frames while it is on screen.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

/// Records each connection the source opens, and at which speed.
class _Connections {
  final opened = <({bool live, StreamController<SseEvent> stream})>[];

  Stream<SseEvent> connect({required bool live}) {
    final stream = StreamController<SseEvent>();
    opened.add((live: live, stream: stream));
    return stream.stream;
  }

  StreamController<SseEvent> get last => opened.last.stream;
}

SseEvent _frame(Map<String, dynamic> json) => SseEvent(
  name: 'trem.rts.v1',
  data: base64.encode(gzip.encode(utf8.encode(jsonEncode(json)))),
);

const _info = SseEvent(
  name: 'info',
  data: '{"location":"lb-tpe1","topics":["trem.rts.v1"]}',
);

void main() {
  test('reads the trem.rts.v1 frame, base64-gzipped, by its topic name', () {
    fakeAsync((async) {
      final connections = _Connections();
      final source = RtsRealtimeSource(
        connections.connect,
        demand: RtsLiveDemand()..hold(),
      );

      source.fetch();
      connections.last.add(
        _frame({
          'ts': 1790537637000,
          'stations': {
            '11DFDBC': {'i': 4.6, 'pga': 38.2, 'alert': 1},
          },
        }),
      );
      async.flushMicrotasks();

      final rts = source.fetch();
      async.flushMicrotasks();
      rts.then((result) {
        expect(result.valueOrNull?.time, 1790537637000);
        expect(result.valueOrNull?.stations['11DFDBC']?.alert, isTrue);
      });
      async.flushMicrotasks();
      source.dispose();
    });
  });

  test('asleep, an open connection with no frames reports calm', () {
    fakeAsync((async) {
      final connections = _Connections();
      final source = RtsRealtimeSource(
        connections.connect,
        demand: RtsLiveDemand(),
      );

      source.fetch();
      expect(connections.opened.single.live, isFalse);
      connections.last.add(_info);
      async.flushMicrotasks();

      source.fetch().then((result) {
        expect(result.isOk, isTrue);
        expect(result.valueOrNull?.stations, isEmpty);
      });
      async.flushMicrotasks();
      source.dispose();
    });
  });

  test('live, a connection that has gone quiet is a failure, not calm', () {
    fakeAsync((async) {
      final connections = _Connections();
      final elapsed = _FakeElapsed();
      final source = RtsRealtimeSource(
        connections.connect,
        demand: RtsLiveDemand()..hold(),
        elapsed: elapsed,
      );

      source.fetch();
      expect(connections.opened.single.live, isTrue);
      connections.last.add(_frame({'ts': 1, 'stations': <String, dynamic>{}}));
      async.flushMicrotasks();
      elapsed.value = const Duration(seconds: 4);

      source.fetch().then((result) => expect(result.isOk, isFalse));
      async.flushMicrotasks();
      source.dispose();
    });
  });

  test('waking reconnects live at once; sleeping waits out the delay', () {
    fakeAsync((async) {
      final connections = _Connections();
      final demand = RtsLiveDemand();
      final source = RtsRealtimeSource(connections.connect, demand: demand);

      source.fetch();
      connections.last.add(_info);
      async.flushMicrotasks();

      demand.hold();
      expect(connections.opened.map((c) => c.live), [false, true]);

      demand.release();
      async.elapse(const Duration(seconds: 2));
      expect(connections.opened, hasLength(2), reason: 'still in the delay');
      async.elapse(const Duration(seconds: 2));
      expect(connections.opened.map((c) => c.live), [false, true, false]);
      source.dispose();
    });
  });

  test(
    'a monitor flicked away and back within the delay reconnects nothing',
    () {
      fakeAsync((async) {
        final connections = _Connections();
        final demand = RtsLiveDemand()..hold();
        final source = RtsRealtimeSource(connections.connect, demand: demand);

        source.fetch();
        demand.release();
        async.elapse(const Duration(seconds: 1));
        demand.hold();
        async.elapse(const Duration(seconds: 5));

        expect(connections.opened, hasLength(1));
        source.dispose();
      });
    },
  );

  test('the old connection keeps the feed until the new one speaks', () {
    fakeAsync((async) {
      final connections = _Connections();
      final demand = RtsLiveDemand();
      final source = RtsRealtimeSource(connections.connect, demand: demand);

      source.fetch();
      final old = connections.last;
      old.add(_info);
      async.flushMicrotasks();

      demand.hold();
      final next = connections.last;
      expect(old.hasListener, isTrue, reason: 'no gap while the new one opens');

      next.add(_info);
      async.flushMicrotasks();
      expect(old.hasListener, isFalse, reason: 'handed over on its greeting');
      expect(next.hasListener, isTrue);
      source.dispose();
    });
  });

  test('timestampOf is null → event-recency freshness, not payload age', () {
    final source = RtsRealtimeSource(
      ({required live}) => const Stream<SseEvent>.empty(),
      demand: RtsLiveDemand(),
    );

    expect(source.timestampOf(source.decode('{"ts": 1}')), isNull);
    source.dispose();
  });
}
