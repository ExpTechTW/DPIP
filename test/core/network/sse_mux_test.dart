/// The shared SSE stream: one connection for every live feed.
///
/// What fails quietly here is the connection count and the routing. A mux that
/// opened a socket per lease would pass every feed test and double the
/// server's connections; one that handed a feed another topic's frames would
/// decode RTS as an alert list; one that closed the socket while a feed still
/// listened would read as an outage on that feed alone. So each of those is
/// pinned against a fake opener, and the HTTP opener's URL is pinned against a
/// fake client — nothing here touches the network.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/sse_client.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/network/sse_mux.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:flutter_test/flutter_test.dart';

const _eew = 'eq.eew.v1';
const _rts = 'trem.rts.v1';

const _retry = SseEvent(retry: Duration(seconds: 3));
const _info = SseEvent(
  name: 'info',
  data: '{"location":"lb-tpe1","topics":["eq.eew.v1","trem.rts.v1"]}',
);
const _ping = SseEvent.comment('ping 1790537637');

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

/// One physical connection the mux opened.
class _Link {
  _Link(this.topics, {required this.live});

  final List<String> topics;
  final bool live;
  bool cancelled = false;
  late final controller = StreamController<SseEvent>(
    onCancel: () => cancelled = true,
  );

  /// The server's greeting: the retry hint, then `info`.
  void greet() => controller
    ..add(_retry)
    ..add(_info);
}

/// Records every connection the mux opens.
class _Opener {
  final links = <_Link>[];

  Stream<SseEvent> call(List<String> topics, {required bool live}) {
    final link = _Link(topics, live: live);
    links.add(link);
    return link.controller.stream;
  }
}

/// A feed's side of a lease: what it received, and whether it ended.
class _Feed {
  _Feed(Stream<SseEvent> stream) {
    subscription = stream.listen(
      events.add,
      onError: (Object error) => errors.add(error),
      onDone: () => done = true,
      cancelOnError: true,
    );
  }

  late final StreamSubscription<SseEvent> subscription;
  final events = <SseEvent>[];
  final errors = <Object>[];
  bool done = false;

  List<String?> get names => [
    for (final e in events) e.isComment ? ':${e.data}' : e.name,
  ];

  Future<void> cancel() => subscription.cancel();
}

SseEvent _frame(String topic, String data) => SseEvent(name: topic, data: data);

void main() {
  late _Opener opener;
  late _FakeElapsed elapsed;
  late SseMux mux;
  late SseMuxTopic eew;
  late SseMuxTopic rts;

  setUp(() {
    opener = _Opener();
    elapsed = _FakeElapsed();
    mux = SseMux(opener.call, elapsed: elapsed);
    eew = mux.topic(_eew, snapshot: true);
    rts = mux.topic(_rts);
  });

  group('one connection', () {
    test('two feeds share one connection that asks for every topic', () async {
      final a = _Feed(eew.connect());
      final b = _Feed(rts.connect());
      await pumpEventQueue();

      expect(opener.links, hasLength(1));
      expect(opener.links.single.topics, [_eew, _rts]);
      expect(opener.links.single.live, isFalse);
      await a.cancel();
      await b.cancel();
    });

    test('a feed that joins later rides the open connection', () async {
      final a = _Feed(eew.connect());
      await pumpEventQueue();
      opener.links.single.greet();
      await pumpEventQueue();

      final b = _Feed(rts.connect());
      await pumpEventQueue();
      expect(opener.links, hasLength(1));
      expect(b.names, [null, 'info'], reason: 'it is told it is connected');
      await a.cancel();
      await b.cancel();
    });

    test(
      'stays open while any feed listens, and closes after the last',
      () async {
        final a = _Feed(eew.connect());
        final b = _Feed(rts.connect());
        await pumpEventQueue();
        final link = opener.links.single;

        await a.cancel();
        await pumpEventQueue();
        expect(link.cancelled, isFalse);

        await b.cancel();
        await pumpEventQueue();
        expect(link.cancelled, isTrue);
      },
    );

    test('feeds leaving and coming back in one burst cost one connection '
        'each way', () async {
      final a = _Feed(eew.connect());
      final b = _Feed(rts.connect());
      await pumpEventQueue();
      // Background: every feed lets go in one synchronous pass.
      unawaited(a.cancel());
      unawaited(b.cancel());
      await pumpEventQueue();
      expect(opener.links.single.cancelled, isTrue);

      // Foreground: every feed comes back in one pass.
      final c = _Feed(eew.connect());
      final d = _Feed(rts.connect());
      await pumpEventQueue();
      expect(opener.links, hasLength(2));
      expect(opener.links.last.cancelled, isFalse);
      await c.cancel();
      await d.cancel();
    });
  });

  group('dispatch by event name', () {
    late _Feed a;
    late _Feed b;
    late _Link link;

    setUp(() async {
      a = _Feed(eew.connect());
      b = _Feed(rts.connect());
      await pumpEventQueue();
      link = opener.links.single;
    });

    tearDown(() async {
      await a.cancel();
      await b.cancel();
    });

    test(
      'each topic frame reaches only its own feed, data untouched',
      () async {
        link
          ..greet()
          ..controller.add(_frame(_eew, 'H4sI-eew'))
          ..controller.add(_frame(_rts, 'H4sI-rts'));
        await pumpEventQueue();

        expect(a.names, [null, 'info', _eew]);
        expect(a.events.last.data, 'H4sI-eew');
        expect(b.names, [null, 'info', _rts]);
        expect(b.events.last.data, 'H4sI-rts');
      },
    );

    test('the greeting, the retry hint and pings reach every feed', () async {
      link
        ..greet()
        ..controller.add(_ping);
      await pumpEventQueue();

      for (final feed in [a, b]) {
        expect(feed.events[0].retry, const Duration(seconds: 3));
        expect(feed.events[1].name, 'info');
        expect(feed.events[1].data, _info.data);
        expect(feed.events[2].isComment, isTrue);
      }
    });

    test('an unnamed frame carries only the retry hint, never a payload', () async {
      // A feed reads an unnamed frame as its own plain-JSON payload; on this
      // endpoint every payload is named, so a stray `data:` must not reach it.
      link.controller.add(
        const SseEvent(data: 'stray', retry: Duration(seconds: 5)),
      );
      await pumpEventQueue();

      for (final feed in [a, b]) {
        expect(feed.events.single.data, isEmpty);
        expect(feed.events.single.retry, const Duration(seconds: 5));
      }
    });

    test('unsubscribed reaches only the feed of that topic', () async {
      link.controller.add(
        const SseEvent(
          name: 'unsubscribed',
          data: '{"topic":"trem.rts.v1","reason":"quota exceeded"}',
        ),
      );
      await pumpEventQueue();

      expect(a.events, isEmpty);
      expect(b.names, ['unsubscribed']);
    });

    test('close reaches every feed and ends every lease, without waiting '
        'for the socket to end', () async {
      link.controller.add(const SseEvent(name: 'close', data: 'shutting down'));
      await pumpEventQueue();

      for (final feed in [a, b]) {
        expect(feed.names, ['close']);
        expect(feed.done, isTrue);
      }
      expect(link.cancelled, isTrue);
    });

    test('the end of the connection ends every lease', () async {
      await link.controller.close();
      await pumpEventQueue();

      for (final feed in [a, b]) {
        expect(feed.done, isTrue);
      }
    });

    test('a connection error reaches every feed', () async {
      link.controller.addError(StateError('reset'));
      await pumpEventQueue();

      for (final feed in [a, b]) {
        expect(feed.errors.single, isA<StateError>());
      }
    });

    test(
      'after a drop, the feeds coming back open one new connection',
      () async {
        await link.controller.close();
        await pumpEventQueue();

        a = _Feed(eew.connect());
        b = _Feed(rts.connect());
        await pumpEventQueue();
        expect(opener.links, hasLength(2));
      },
    );
  });

  group('a feed joining an open connection', () {
    test('hears the greeting and the latest snapshot, as from a fresh '
        'connection', () async {
      final a = _Feed(eew.connect());
      final b = _Feed(rts.connect());
      await pumpEventQueue();
      final link = opener.links.single
        ..greet()
        ..controller.add(_frame(_eew, 'old'))
        ..controller.add(_frame(_eew, 'new'))
        ..controller.add(_frame(_rts, 'frame'));
      await pumpEventQueue();

      // The EEW feed reconnects on its own while RTS holds the connection.
      await a.cancel();
      final again = _Feed(eew.connect());
      await pumpEventQueue();

      expect(opener.links, hasLength(1), reason: 'joined, not reopened');
      expect(again.names, [null, 'info', _eew]);
      expect(again.events.last.data, 'new', reason: 'replace, never append');
      expect(link.cancelled, isFalse);
      await again.cancel();
      await b.cancel();
    });

    test(
      'a stream topic is not replayed: its next frame is moments away',
      () async {
        final a = _Feed(eew.connect());
        final b = _Feed(rts.connect());
        await pumpEventQueue();
        opener.links.single
          ..greet()
          ..controller.add(_frame(_rts, 'stale'));
        await pumpEventQueue();

        await b.cancel();
        final again = _Feed(rts.connect());
        await pumpEventQueue();
        expect(again.names, [null, 'info']);
        await a.cancel();
        await again.cancel();
      },
    );

    test(
      'a connection silent past the limit is replaced, not joined',
      () async {
        final a = _Feed(eew.connect());
        final b = _Feed(rts.connect());
        await pumpEventQueue();
        final dead = opener.links.single..greet();
        await pumpEventQueue();

        // Half-open: nothing arrives, and the RTS feed gives up on it first.
        elapsed.value = sseSilenceLimit + const Duration(seconds: 1);
        await b.cancel();
        final again = _Feed(rts.connect());
        await pumpEventQueue();

        expect(dead.cancelled, isTrue);
        expect(
          a.done,
          isTrue,
          reason: 'the EEW feed reconnects to the new one',
        );
        expect(opener.links, hasLength(2));
        expect(again.done, isFalse);
        await again.cancel();
      },
    );
  });

  group('live mode', () {
    test('runs live while any feed asks, handed over without a gap', () async {
      final a = _Feed(eew.connect());
      final sleeping = _Feed(rts.connect());
      await pumpEventQueue();
      final asleep = opener.links.single..greet();
      await pumpEventQueue();

      // The monitor opens: the RTS feed renews its connection at live speed.
      final awake = _Feed(rts.connect(live: true));
      await pumpEventQueue();
      expect(opener.links, hasLength(2));
      final live = opener.links.last;
      expect(live.live, isTrue);
      expect(live.topics, [_eew, _rts]);
      expect(awake.events, isEmpty, reason: 'the asleep one cannot serve it');

      // Until the new one speaks, the old one still serves everyone.
      asleep.controller.add(_frame(_eew, 'during'));
      await pumpEventQueue();
      expect(a.events.last.data, 'during');
      expect(asleep.cancelled, isFalse);

      live
        ..greet()
        ..controller.add(_frame(_rts, 'every frame'));
      await pumpEventQueue();
      expect(asleep.cancelled, isTrue);
      expect(awake.names, [null, 'info', _rts]);
      expect(a.done, isFalse, reason: 'EEW never saw a drop');
      expect(a.names.last, 'info');

      await sleeping.cancel();
      await pumpEventQueue();
      expect(opener.links, hasLength(2), reason: 'still live: nothing to do');
      await a.cancel();
      await awake.cancel();
    });

    test('drops back to sleep once the last live feed lets go', () async {
      final a = _Feed(eew.connect());
      final awake = _Feed(rts.connect(live: true));
      await pumpEventQueue();
      expect(opener.links.single.live, isTrue);
      opener.links.single.greet();
      await pumpEventQueue();

      // The RTS feed renews asleep: the live connection serves the new lease
      // at once, and the switch happens when the live lease goes.
      final asleep = _Feed(rts.connect());
      await pumpEventQueue();
      expect(asleep.names, [null, 'info']);
      expect(opener.links, hasLength(1));

      await awake.cancel();
      await pumpEventQueue();
      expect(opener.links, hasLength(2));
      expect(opener.links.last.live, isFalse);
      opener.links.last.greet();
      await pumpEventQueue();
      expect(opener.links.first.cancelled, isTrue);
      expect(a.done, isFalse);
      await a.cancel();
      await asleep.cancel();
    });

    test('a connection that has not spoken yet is replaced outright', () async {
      final a = _Feed(eew.connect());
      await pumpEventQueue();
      final b = _Feed(rts.connect(live: true));
      await pumpEventQueue();

      expect(opener.links, hasLength(2));
      expect(opener.links.first.cancelled, isTrue);
      expect(opener.links.last.live, isTrue);
      opener.links.last.greet();
      await pumpEventQueue();
      expect(a.names, [null, 'info'], reason: 'it waited on the replacement');
      await a.cancel();
      await b.cancel();
    });

    test(
      'a failed handover ends every lease, so each feed reconnects',
      () async {
        final a = _Feed(eew.connect());
        final b = _Feed(rts.connect());
        await pumpEventQueue();
        final asleep = opener.links.single..greet();
        await pumpEventQueue();

        final awake = _Feed(rts.connect(live: true));
        await pumpEventQueue();
        opener.links.last.controller.addError(StateError('refused'));
        await pumpEventQueue();

        expect(asleep.cancelled, isTrue, reason: 'it has the old parameters');
        for (final feed in [a, b, awake]) {
          expect(feed.done, isTrue);
        }
      },
    );
  });

  group('SseMux.lb', () {
    late _StreamingApiClient client;
    late SseMux lb;

    setUp(() {
      client = _StreamingApiClient();
      lb = SseMux.lb(client);
    });

    test('opens /api/v1/sse on the LB tier with every topic, bounded by the '
        'server ping', () async {
      final a = _Feed(lb.topic(_eew, snapshot: true).connect());
      final b = _Feed(lb.topic(_rts).connect());
      await pumpEventQueue();

      final call = client.calls.single;
      expect(call.tier, ApiTier.lbApi);
      expect(call.path, ApiPaths.sse);
      expect(call.path, '/api/v1/sse');
      expect(call.query, {'topics': 'eq.eew.v1,trem.rts.v1'});
      expect(call.idleTimeout, sseSilenceLimit);
      expect(call.headers?['Accept'], 'text/event-stream');
      await a.cancel();
      await b.cancel();
    });

    test('asks for mode=live only while a feed wants every frame', () async {
      final a = _Feed(lb.topic(_rts).connect(live: true));
      await pumpEventQueue();
      expect(client.calls.single.query, {
        'topics': 'trem.rts.v1',
        'mode': 'live',
      });
      await a.cancel();
    });
  });
}

/// An [ApiClient] that records each stream it is asked to open and answers
/// with a body that never ends.
class _StreamingApiClient implements ApiClient {
  final calls =
      <
        ({
          ApiTier tier,
          String path,
          Map<String, dynamic>? query,
          Map<String, dynamic>? headers,
          Duration idleTimeout,
        })
      >[];

  @override
  Future<StreamedResponse> openStream(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Duration idleTimeout = Duration.zero,
  }) async {
    calls.add((
      tier: tier,
      path: path,
      query: query,
      headers: headers,
      idleTimeout: idleTimeout,
    ));
    return StreamedResponse(StreamController<Uint8List>().stream, () {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
