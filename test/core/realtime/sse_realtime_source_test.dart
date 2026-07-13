import 'dart:async';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

/// A concrete [SseRealtimeSource] over `String` payloads (decode = identity),
/// throwing on the sentinel `'bad'` so decode-failure resilience is testable.
class _TestSseSource extends SseRealtimeSource<String> {
  _TestSseSource({
    required super.connect,
    SseLiveness? liveness,
    super.elapsed,
    super.delay,
  }) : super(
         liveness: liveness ?? const SseLiveness.connectionOpen(),
         label: 'test',
       );

  @override
  String decode(String data) {
    if (data == 'bad') throw const FormatException('bad');
    return data;
  }

  @override
  DateTime? timestampOf(String value) => null;
}

/// Drives a [SseRealtimeSource] with a controllable connection factory, a
/// manually-completed reconnect delay, and a fake monotonic clock.
class _Harness {
  _Harness({SseLiveness? liveness}) {
    source = _TestSseSource(
      connect: _connect,
      liveness: liveness,
      elapsed: elapsed,
      delay: _delay,
    );
  }

  final connects = <StreamController<SseEvent>>[];
  final delays = <Completer<void>>[];
  final elapsed = _FakeElapsed();
  late final _TestSseSource source;

  Stream<SseEvent> _connect() {
    final controller = StreamController<SseEvent>();
    connects.add(controller);
    return controller.stream;
  }

  Future<void> _delay(Duration _) {
    final completer = Completer<void>();
    delays.add(completer);
    return completer.future;
  }

  StreamController<SseEvent> get current => connects.last;
}

void main() {
  group('SseRealtimeSource — connection-open liveness (EEW)', () {
    test(
      'connects lazily on first fetch; Err until the first snapshot',
      () async {
        final h = _Harness();
        expect(h.connects, isEmpty);

        final first = await h.source.fetch();
        expect(first.isOk, isFalse, reason: 'no data yet');
        expect(
          h.connects,
          hasLength(1),
          reason: 'first fetch opened the stream',
        );

        h.current.add(const SseEvent(data: 'a'));
        await pumpEventQueue();
        expect((await h.source.fetch()).valueOrNull, 'a');
      },
    );

    test('stays Ok while the connection is open but silent', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();

      // No further events (an EEW-quiet period) — still live because open.
      expect((await h.source.fetch()).valueOrNull, 'a');
      expect((await h.source.fetch()).valueOrNull, 'a');
      expect(h.connects, hasLength(1), reason: 'no reconnect churn while open');
    });

    test('metadata and empty-default frames are not a snapshot', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current
        ..add(const SseEvent(name: 'info', data: '{"location":"x"}'))
        ..add(const SseEvent(data: '')); // default but empty
      await pumpEventQueue();
      expect((await h.source.fetch()).isOk, isFalse);

      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'a');
    });

    test('a drop ages to Err, then reconnects after the backoff', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'a');

      await h.current.close(); // server closed the stream
      await pumpEventQueue();
      expect((await h.source.fetch()).isOk, isFalse, reason: 'disconnected');
      expect(
        h.connects,
        hasLength(1),
        reason: 'fetch must not itself reconnect',
      );
      expect(h.delays, hasLength(1), reason: 'reconnect scheduled');

      h.delays.last.complete(); // backoff elapses
      await pumpEventQueue();
      expect(h.connects, hasLength(2), reason: 'reopened');

      h.current.add(const SseEvent(data: 'b'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'b');
    });

    test('a decode failure keeps the last good payload', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();
      h.current.add(const SseEvent(data: 'bad')); // decode throws
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'a');
      expect(
        h.connects,
        hasLength(1),
        reason: 'bad frame must not drop the link',
      );
    });

    test('dispose stops reconnection', () async {
      final h = _Harness();
      await h.source.fetch();
      await h.current.close();
      await pumpEventQueue();

      h.source.dispose();
      h.delays.last.complete(); // would reconnect if not disposed
      await pumpEventQueue();

      expect(h.connects, hasLength(1), reason: 'no reconnect after dispose');
      expect((await h.source.fetch()).isOk, isFalse);
    });
  });

  group('SseRealtimeSource — event-recency liveness (continuous feed)', () {
    test('goes Err when no event arrives within the window', () async {
      final h = _Harness(
        liveness: const SseLiveness.eventRecency(Duration(seconds: 2)),
      );
      await h.source.fetch();

      h.elapsed.value = const Duration(seconds: 10);
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'a', reason: 'fresh event');

      h.elapsed.value = const Duration(seconds: 13); // 3s later, past 2s window
      expect((await h.source.fetch()).isOk, isFalse, reason: 'frozen feed');

      h.elapsed.value = const Duration(seconds: 14);
      h.current.add(const SseEvent(data: 'b'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'b', reason: 'refreshed');
    });
  });
}
