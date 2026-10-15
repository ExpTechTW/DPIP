import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

/// A [Random] whose `nextDouble` the test sets — 0 is the shortest spread,
/// just under 1 the longest.
class _FixedRandom implements Random {
  double next = 0.5;
  @override
  double nextDouble() => next;
  @override
  int nextInt(int max) => (next * max).floor();
  @override
  bool nextBool() => next >= 0.5;
}

/// A concrete [SseRealtimeSource] over `String` payloads (decode = identity),
/// throwing on the sentinel `'bad'` so decode-failure resilience is testable.
class _TestSseSource extends SseRealtimeSource<String> {
  _TestSseSource({
    required super.connect,
    SseLiveness? liveness,
    super.elapsed,
    super.delay,
    super.random,
  }) : super(
         liveness: liveness ?? const SseLiveness.connectionOpen(),
         label: 'test',
       );

  /// Exposes the protected swap to the tests.
  void swap() => renew();

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
/// A source that overrides the byte hook, so a test can tell which path a
/// compressed frame took: the default routes bytes through [decode].
class _BytesSseSource extends _TestSseSource {
  _BytesSseSource({
    required super.connect,
    super.liveness,
    super.elapsed,
    super.delay,
    super.random,
  });

  @override
  String decodeBytes(Uint8List utf8Json) => 'bytes:${utf8.decode(utf8Json)}';
}

class _Harness {
  _Harness({SseLiveness? liveness, bool bytesSource = false}) {
    source = bytesSource
        ? _BytesSseSource(
            connect: _connect,
            liveness: liveness,
            elapsed: elapsed,
            delay: _delay,
            random: random,
          )
        : _TestSseSource(
            connect: _connect,
            liveness: liveness,
            elapsed: elapsed,
            delay: _delay,
            random: random,
          );
  }

  final connects = <StreamController<SseEvent>>[];
  final delays = <Completer<void>>[];

  /// The duration each [delays] entry was asked to wait.
  final waits = <Duration>[];
  final elapsed = _FakeElapsed();
  final random = _FixedRandom();
  late final _TestSseSource source;

  Stream<SseEvent> _connect() {
    final controller = StreamController<SseEvent>();
    connects.add(controller);
    return controller.stream;
  }

  Future<void> _delay(Duration wait) {
    final completer = Completer<void>();
    delays.add(completer);
    waits.add(wait);
    return completer.future;
  }

  /// Drops the current connection and lets the queued reconnect fire,
  /// leaving the new connection open but silent.
  Future<void> dropAndReconnect() async {
    await current.close();
    await pumpEventQueue();
    delays.last.complete();
    await pumpEventQueue();
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

    test('stays Ok through silence up to the limit, and no further', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();

      // No further events (an EEW-quiet period) — still live while the
      // silence is one a healthy stream can produce between two pings.
      h.elapsed.value = sseSilenceLimit;
      expect((await h.source.fetch()).valueOrNull, 'a');
      expect(h.connects, hasLength(1), reason: 'no reconnect churn while open');
      expect(h.delays, isEmpty);

      // One tick past it, the socket is presumed half-open: a handover or a
      // NAT timeout that never sent a FIN. Not live, and replaced.
      final old = h.current;
      h.elapsed.value = sseSilenceLimit + const Duration(seconds: 1);
      expect((await h.source.fetch()).isOk, isFalse, reason: 'dead, not calm');
      expect(old.hasListener, isFalse, reason: 'the dead socket is released');
      expect(h.delays, hasLength(1), reason: 'a reconnect is queued');
      expect(
        (await h.source.fetch()).isOk,
        isFalse,
        reason: 'still not live until the new connection speaks',
      );

      h.delays.single.complete();
      await pumpEventQueue();
      expect(h.connects, hasLength(2));
      h.current.add(const SseEvent(data: 'b'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'b');
    });

    test('a server ping keeps a quiet connection alive', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();

      // Pings land every interval; the data never changes.
      for (var i = 1; i <= 5; i++) {
        h.elapsed.value = sseServerPingInterval * i;
        h.current.add(const SseEvent.comment('ping'));
        await pumpEventQueue();
        expect((await h.source.fetch()).valueOrNull, 'a');
      }
      expect(h.connects, hasLength(1));
      expect(h.delays, isEmpty);
    });

    test('a ping is not a payload', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent.comment('ping'));
      await pumpEventQueue();
      expect(
        (await h.source.fetch()).isOk,
        isFalse,
        reason: 'connected, but nothing to report yet',
      );
    });

    test('a connection that opens and never speaks is replaced', () async {
      final h = _Harness();
      await h.source.fetch();
      expect(h.connects, hasLength(1));

      h.elapsed.value = sseSilenceLimit + const Duration(seconds: 1);
      await h.source.fetch();
      expect(h.connects.single.hasListener, isFalse);
      expect(h.delays, hasLength(1));
    });

    test('the silence limit is two ping intervals and then some', () {
      // Two, because the LB hub can push a ping out to almost two intervals
      // after the last byte; any tighter and a healthy quiet stream is torn
      // down. Pinned so a change to either number is a deliberate one.
      expect(sseSilenceLimit, sseServerPingInterval * 2.2);
      expect(const SseLiveness.connectionOpen().silenceLimit, sseSilenceLimit);
    });

    test('a compressed frame reaches decodeBytes, never decode', () async {
      final h = _Harness(bytesSource: true);
      await h.source.fetch();
      final packed = base64.encode(gzip.encode(utf8.encode('shaken')));
      h.current.add(SseEvent(name: 'g', data: packed));
      await Future<void>.delayed(Duration.zero);
      final result = await h.source.fetch();
      expect(result.valueOrNull, 'bytes:shaken');
    });

    test(
      'an empty compressed frame is metadata, not an empty snapshot',
      () async {
        final h = _Harness(bytesSource: true);
        await h.source.fetch();
        final packed = base64.encode(gzip.encode(utf8.encode('')));
        h.current.add(SseEvent(name: 'g', data: packed));
        await Future<void>.delayed(Duration.zero);
        expect((await h.source.fetch()).isOk, isFalse);
      },
    );

    test('decompresses a compressed payload (event: g, base64 gzip)', () async {
      final h = _Harness();
      await h.source.fetch();
      // What `compress=1` sends: event name "g", data = base64(gzip(json)).
      final packed = base64.encode(gzip.encode(utf8.encode('shaken')));
      h.current.add(SseEvent(name: 'g', data: packed));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'shaken');
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

    test(
      'backoff steps 1s, 2s, then the server hint, each spread ±50%',
      () async {
        final h = _Harness();
        await h.source.fetch();

        h.random.next = 0.5; // the middle of the spread: the plain schedule
        for (var i = 0; i < 4; i++) {
          await h.dropAndReconnect();
        }
        expect(h.waits, const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3), // the default `retry:` hint caps it
          Duration(seconds: 3),
        ]);

        h.random.next = 0;
        await h.dropAndReconnect();
        expect(
          h.waits.last,
          const Duration(milliseconds: 1500),
          reason: '-50%',
        );

        h.random.next = 0.999;
        await h.dropAndReconnect();
        expect(
          h.waits.last,
          const Duration(milliseconds: 4497),
          reason: 'just under +50%',
        );
      },
    );

    test(
      'a delivering connection resets the backoff to the first step',
      () async {
        final h = _Harness();
        await h.source.fetch();
        h.random.next = 0;
        await h.dropAndReconnect();
        await h.dropAndReconnect();
        expect(h.waits, const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
        ]);

        h.current.add(const SseEvent(data: 'a')); // the new connection speaks
        await pumpEventQueue();
        await h.dropAndReconnect();
        expect(h.waits.last, const Duration(milliseconds: 500));
      },
    );

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

    test(
      'a frozen connection is also replaced once past the silence limit',
      () async {
        final h = _Harness(
          liveness: const SseLiveness.eventRecency(
            Duration(seconds: 2),
            silenceLimit: Duration(seconds: 30),
          ),
        );
        await h.source.fetch();
        h.current.add(const SseEvent(data: 'a'));
        await pumpEventQueue();

        h.elapsed.value = const Duration(seconds: 30);
        await h.source.fetch();
        expect(h.delays, isEmpty, reason: 'stale, but not yet presumed dead');

        h.elapsed.value = const Duration(seconds: 31);
        await h.source.fetch();
        expect(h.connects.single.hasListener, isFalse);
        expect(h.delays, hasLength(1));
      },
    );
  });

  group('SseRealtimeSource — background pause', () {
    test('pause drops the connection and does not reconnect', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'a');

      h.source.pause();
      await pumpEventQueue();
      expect(h.current.hasListener, isFalse, reason: 'socket released');
      expect(
        h.delays,
        isEmpty,
        reason: 'a cancel is not a drop to recover from',
      );

      // A fetch while paused must not quietly re-open the connection.
      expect((await h.source.fetch()).isOk, isFalse);
      expect(h.connects, hasLength(1));
    });

    test('resume re-opens on the next fetch', () async {
      final h = _Harness();
      await h.source.fetch();
      h.current.add(const SseEvent(data: 'a'));
      await pumpEventQueue();

      h.source.pause();
      h.source.resume();
      expect(h.connects, hasLength(1), reason: 'the open is lazy, as on start');

      expect(
        (await h.source.fetch()).isOk,
        isFalse,
        reason: 'not yet reconnected',
      );
      expect(h.connects, hasLength(2), reason: 'the fetch re-opened it');

      h.current.add(const SseEvent(data: 'b'));
      await pumpEventQueue();
      expect((await h.source.fetch()).valueOrNull, 'b');
    });

    test('a reconnect already in flight cannot open a paused source', () async {
      final h = _Harness();
      await h.source.fetch();
      await h.current.close(); // the connection drops, scheduling a reconnect
      await pumpEventQueue();
      expect(h.delays, hasLength(1));

      h.source.pause();
      h.delays.single.complete(); // the backoff fires after the pause landed
      await pumpEventQueue();
      expect(h.connects, hasLength(1), reason: 'refused while paused');

      // ...and resuming still gets a connection, with the backoff reset.
      h.source.resume();
      await h.source.fetch();
      expect(h.connects, hasLength(2));
    });

    test('a backoff that outlives the pause cannot double-open', () async {
      final h = _Harness();
      await h.source.fetch();
      await h.current.close(); // drop → reconnect scheduled
      await pumpEventQueue();
      expect(h.delays, hasLength(1));

      // The whole background stint fits inside the backoff window: the timer is
      // still pending when the app comes back, so the reconnect it belongs to
      // and the reconnect `resume` re-arms are both live.
      h.source.pause();
      h.source.resume();

      h.delays.single.complete(); // the *stale* backoff fires, now unpaused
      await pumpEventQueue();
      await h.source.fetch(); // ...and the resumed lazy open fires too

      expect(
        h.connects,
        hasLength(2),
        reason: 'the stale backoff and the resume must not each open a socket',
      );
      expect(
        h.connects.where((c) => c.hasListener),
        hasLength(1),
        reason: 'an overwritten subscription is a leaked connection',
      );
    });
  });

  group('SseRealtimeSource — renew (a change of connection parameters)', () {
    test(
      'a swap that fails before its greeting falls back to a reconnect',
      () async {
        final h = _Harness();
        await h.source.fetch();
        h.current.add(const SseEvent(data: 'a'));
        await pumpEventQueue();
        final old = h.current;

        h.source.swap();
        final pending = h.current;
        await pending.close();
        await pumpEventQueue();

        // The old connection carries the old parameters: keeping it would leave
        // the change quietly unapplied, so it goes and a reconnect is queued.
        expect(old.hasListener, isFalse);
        expect(h.delays, hasLength(1));
        h.delays.single.complete();
        await pumpEventQueue();
        expect(h.connects, hasLength(3));
      },
    );

    test('a swap before the first fetch opens nothing', () async {
      final h = _Harness();
      h.source.swap();
      expect(h.connects, isEmpty);
    });

    test('a swap orphans a reconnect the old connection had queued', () async {
      final h = _Harness();
      await h.source.fetch();
      await h.current.close();
      await pumpEventQueue();
      expect(h.delays, hasLength(1), reason: 'a reconnect is waiting');

      h.source.swap();
      h.current.add(const SseEvent(name: 'info', data: '{}'));
      await pumpEventQueue();
      h.delays.single.complete();
      await pumpEventQueue();

      expect(h.connects, hasLength(2), reason: 'no third, stray connection');
    });
  });

  group('SseRealtimeSource — network change', () {
    test(
      'drops the connection at once and reopens after a 1–2 s settle',
      () async {
        final h = _Harness();
        await h.source.fetch();
        h.current.add(const SseEvent(data: 'a'));
        await pumpEventQueue();
        final old = h.current;

        h.random.next = 0.25;
        h.source.networkChanged();
        expect(old.hasListener, isFalse, reason: 'bound to the old network');
        expect(
          (await h.source.fetch()).isOk,
          isFalse,
          reason:
              'nothing vouches for the feed until the new connection speaks',
        );
        expect(h.waits.single, const Duration(milliseconds: 1250));
        expect(h.connects, hasLength(1), reason: 'not before the settle');

        h.delays.single.complete();
        await pumpEventQueue();
        expect(h.connects, hasLength(2));
        h.current.add(const SseEvent(data: 'b'));
        await pumpEventQueue();
        expect((await h.source.fetch()).valueOrNull, 'b');
      },
    );

    test('the settle spans 1 to 2 seconds', () async {
      final h = _Harness();
      await h.source.fetch();
      h.random.next = 0;
      h.source.networkChanged();
      h.random.next = 0.9999;
      h.source.networkChanged();
      expect(h.waits, const [
        Duration(seconds: 1),
        Duration(milliseconds: 1999),
      ]);
    });

    test('resets the backoff and orphans the one counting down', () async {
      final h = _Harness();
      await h.source.fetch();
      await h.dropAndReconnect();
      await h.dropAndReconnect();
      await h.current.close(); // a third drop: its backoff is now 3s
      await pumpEventQueue();
      expect(h.connects, hasLength(3));

      h.source.networkChanged();
      h.delays[h.delays.length - 2].complete(); // the old backoff fires late
      await pumpEventQueue();
      expect(
        h.connects,
        hasLength(3),
        reason: 'it belonged to the old network',
      );

      h.delays.last.complete(); // the settle
      await pumpEventQueue();
      expect(h.connects, hasLength(4));

      // The new connection fails before speaking: back to the first step.
      h.random.next = 0.5;
      await h.current.close();
      await pumpEventQueue();
      expect(h.waits.last, const Duration(seconds: 1));
    });

    test('changes in quick succession open one connection', () async {
      final h = _Harness();
      await h.source.fetch();
      h.source
        ..networkChanged() // Wi-Fi lost
        ..networkChanged(); // cellular up
      for (final delay in h.delays) {
        delay.complete();
      }
      await pumpEventQueue();
      expect(h.connects, hasLength(2));
      expect(h.connects.where((c) => c.hasListener), hasLength(1));
    });

    test('is ignored before the first fetch and while paused', () async {
      final h = _Harness();
      h.source.networkChanged();
      expect(h.delays, isEmpty);

      await h.source.fetch();
      h.source.pause();
      h.source.networkChanged();
      expect(h.delays, isEmpty, reason: 'resuming opens a fresh one anyway');
    });
  });

  group('SseRealtimeSource — named payload event', () {
    test(
      'a topic-named frame is read when that is the payload event',
      () async {
        final connects = <StreamController<SseEvent>>[];
        final source = _TopicSource(
          connect: () {
            final c = StreamController<SseEvent>();
            connects.add(c);
            return c.stream;
          },
        );
        await source.fetch();
        final packed = base64.encode(gzip.encode(utf8.encode('shaken')));
        connects.last
          ..add(SseEvent(name: 'g', data: packed))
          ..add(const SseEvent(name: 'trem.other.v1', data: 'x'));
        await pumpEventQueue();
        expect((await source.fetch()).isOk, isFalse, reason: 'not its topic');

        connects.last.add(SseEvent(name: 'trem.rts.v1', data: packed));
        await pumpEventQueue();
        expect((await source.fetch()).valueOrNull, 'shaken');
      },
    );
  });

  group('SseRealtimeSource — decoded elsewhere', () {
    late List<StreamController<SseEvent>> connects;
    late List<Completer<void>> delays;
    late _ElsewhereSource source;

    String packed(String text) => base64.encode(gzip.encode(utf8.encode(text)));
    void send(String text) =>
        connects.last.add(SseEvent(name: 'g', data: packed(text)));

    setUp(() {
      connects = [];
      delays = [];
      source = _ElsewhereSource(
        connect: () {
          final c = StreamController<SseEvent>();
          connects.add(c);
          return c.stream;
        },
        delay: (_) {
          final completer = Completer<void>();
          delays.add(completer);
          return completer.future;
        },
      );
    });

    test('a frame is the snapshot once its decode answers', () async {
      await source.fetch();
      send('shaken');
      await pumpEventQueue();
      expect(
        source.answers.single.data,
        packed('shaken'),
        reason: 'handed over exactly as it arrived, base64 and all',
      );
      expect((await source.fetch()).isOk, isFalse, reason: 'not answered');

      source.answers.single.answer.complete('shaken');
      await pumpEventQueue();
      expect((await source.fetch()).valueOrNull, 'shaken');
    });

    test('a late answer never replaces a newer frame', () async {
      await source.fetch();
      send('one');
      send('two');
      await pumpEventQueue();
      source.answers[1].answer.complete('two');
      await pumpEventQueue();
      source.answers[0].answer.complete('one');
      await pumpEventQueue();
      expect((await source.fetch()).valueOrNull, 'two');
    });

    test('nor one decoded here after the worker stepped aside', () async {
      await source.fetch();
      send('one');
      await pumpEventQueue();
      source.onThisIsolate = true;
      send('two');
      await pumpEventQueue();
      expect((await source.fetch()).valueOrNull, 'two');

      source.answers.single.answer.complete('one');
      await pumpEventQueue();
      expect((await source.fetch()).valueOrNull, 'two');
    });

    test('an answer after a drop does not revive the snapshot', () async {
      await source.fetch();
      send('before');
      await pumpEventQueue();
      await connects.last.close();
      await pumpEventQueue();
      delays.last.complete();
      await pumpEventQueue();
      connects.last.add(const SseEvent(name: 'info', data: '{}'));
      await pumpEventQueue();

      source.answers.single.answer.complete('before');
      await pumpEventQueue();
      expect(
        (await source.fetch()).isOk,
        isFalse,
        reason: 'a frame from the dropped connection is not current',
      );
    });

    test('nor after a pause', () async {
      await source.fetch();
      send('before');
      await pumpEventQueue();
      source
        ..pause()
        ..resume();
      await source.fetch();
      connects.last.add(const SseEvent(name: 'info', data: '{}'));
      await pumpEventQueue();

      source.answers.single.answer.complete('before');
      await pumpEventQueue();
      expect((await source.fetch()).isOk, isFalse);
    });

    test('an empty answer is metadata, not a snapshot', () async {
      await source.fetch();
      send('');
      await pumpEventQueue();
      source.answers.single.answer.complete(null);
      await pumpEventQueue();
      expect((await source.fetch()).isOk, isFalse);
    });

    test('a failed decode keeps the last good snapshot', () async {
      await source.fetch();
      send('a');
      send('bad');
      await pumpEventQueue();
      source.answers[0].answer.complete('a');
      source.answers[1].answer.completeError(const FormatException('bad'));
      await pumpEventQueue();
      expect((await source.fetch()).valueOrNull, 'a');
      expect(connects, hasLength(1), reason: 'a bad frame keeps the link');
    });
  });
}

/// Hands every compressed frame to a decode the test answers by hand — or,
/// while [onThisIsolate] is set, declines and lets the source decode it.
class _ElsewhereSource extends _TestSseSource {
  _ElsewhereSource({required super.connect, super.delay});

  final answers = <({String data, Completer<String?> answer})>[];
  bool onThisIsolate = false;

  @override
  Future<String?>? decodeElsewhere(String data) {
    if (onThisIsolate) return null;
    final answer = Completer<String?>();
    answers.add((data: data, answer: answer));
    return answer.future;
  }
}

class _TopicSource extends SseRealtimeSource<String> {
  _TopicSource({required super.connect})
    : super(label: 'topic', payloadEvent: 'trem.rts.v1');

  @override
  String decode(String data) => data;

  @override
  DateTime? timestampOf(String value) => null;
}
