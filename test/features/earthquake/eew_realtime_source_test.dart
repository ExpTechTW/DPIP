import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter_test/flutter_test.dart';

/// A source with a never-emitting connection: these tests exercise the pure
/// mapping ([EewRealtimeSource.decode]) and freshness overrides, not the
/// transport (covered by `test/core/realtime/sse_realtime_source_test.dart`).
/// An empty list is calm; a body that is not a list of alerts must throw,
/// because treating it as no alert would clear one that is still in progress.
EewRealtimeSource _source({bool cwaOnly = false}) => EewRealtimeSource(
  () => const Stream<SseEvent>.empty(),
  cwaOnly: () => cwaOnly,
);

Eew _eew({int serial = 1}) => Eew(
  agency: 'cwa',
  id: '113000',
  serial: serial,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 1700000000000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: 'Test',
    max: 4,
  ),
);

void main() {
  test('decode parses the SSE data: payload — same JSON as the GET', () {
    final source = _source();
    expect(source.decode('[]'), isEmpty);

    // The exact wire shape the endpoint streams (author/eq/final wire names).
    final payload = jsonEncode([
      {
        'author': 'cwa',
        'id': '113000',
        'serial': 3,
        'status': 1,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.2,
          'loc': '花蓮縣',
          'max': 4,
        },
      },
    ]);
    final eews = source.decode(payload);
    expect(eews, hasLength(1));
    expect(eews.single.agency, 'cwa');
    expect(eews.single.serial, 3);
    expect(eews.single.isFinal, isFalse); // final: 0 -> false
    expect(eews.single.info.location, '花蓮縣');
  });

  test('JMA is dropped unconditionally, and cwaOnly drops every other '
      'non-CWA alert, case-insensitively, reading fresh each decode', () {
    final payload = jsonEncode([
      {
        'author': 'cwa',
        'id': 'a',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'CWA event',
          'max': 4,
        },
      },
      {
        // Mixed case on purpose — the wire value is lowercase in practice,
        // but the filter must not silently miss a differently-cased one.
        'author': 'CWA',
        'id': 'b',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'CWA event, mixed case',
          'max': 4,
        },
      },
      {
        'author': 'jma',
        'id': 'c',
        'serial': 1,
        'status': 0,
        'final': 0,
        'eq': {
          'time': 1700000000000,
          'lon': 121.5,
          'lat': 24.0,
          'depth': 10.0,
          'mag': 5.0,
          'loc': 'JMA event',
          'max': 4,
        },
      },
    ]);

    final unfiltered = _source().decode(payload);
    expect(
      unfiltered.map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason: 'cwaOnly off — every agency but JMA passes through',
    );

    var enabled = false;
    final source = EewRealtimeSource(
      () => const Stream<SseEvent>.empty(),
      cwaOnly: () => enabled,
    );
    expect(
      source.decode(payload).map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason: 'still off — the closure has not flipped yet, JMA still dropped',
    );

    enabled = true;
    expect(
      source.decode(payload).map((e) => e.id),
      unorderedEquals(['a', 'b']),
      reason:
          'flipping the same closure (mirroring EewCwaOnlySettings.enabled '
          'changing) must be reflected on the very next decode',
    );
  });

  test('a payload that is not a list of alerts is not turned into none', () {
    // An empty list is the calm answer. A truncated or reshaped body is not:
    // swallowing it would clear a live alert.
    expect(() => _source().decode(''), throwsFormatException);
    expect(
      () => _source().decode('{"author":"cwa"}'),
      throwsA(isA<TypeError>()),
    );
    expect(() => _source().decode('[{}]'), throwsA(anything));
  });

  test('timestampOf is null → the channel uses connection/fetch-freshness', () {
    expect(_source().timestampOf([_eew()]), isNull);
  });

  test('sameData compares alert content, not list identity', () {
    final source = _source();
    expect(source.sameData(const [], const []), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 1)]), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 2)]), isFalse);
    expect(source.sameData(const [], [_eew()]), isFalse);
  });

  group('REST fallback while the stream is down', () {
    late _Fallback f;

    setUp(() => f = _Fallback());
    tearDown(() => f.source.dispose());

    test(
      'no poll while the stream answers, or in its first seconds down',
      () async {
        await f.source.fetch(); // opens the stream
        f.stream.add(const SseEvent(data: '[]'));
        await pumpEventQueue();
        f.at(const Duration(seconds: 30));
        expect((await f.source.fetch()).isOk, isTrue);
        expect(f.polls, isEmpty, reason: 'a live stream needs no fallback');

        await f.stream.close(); // the stream drops
        await pumpEventQueue();
        f.at(const Duration(seconds: 31));
        expect((await f.source.fetch()).isOk, isFalse);
        f.at(const Duration(seconds: 33));
        await f.source.fetch();
        expect(f.polls, isEmpty, reason: 'an ordinary reconnect costs nothing');

        f.at(const Duration(seconds: 34));
        await f.source.fetch();
        expect(f.polls, hasLength(1), reason: 'past the grace: poll');
      },
    );

    test('a polled alert arrives, filtered like a streamed one, flagged as '
        'fallback', () async {
      await f.downFor(EewRealtimeSource.fallbackGrace);
      expect(f.polls, hasLength(1));
      f.polls.single.complete([_wire('cwa', 'a'), _wire('jma', 'b')]);
      await pumpEventQueue();

      final result = await f.source.fetch();
      expect(result.valueOrNull?.map((e) => e.id), [
        'a',
      ], reason: 'JMA dropped');
      expect(f.source.servingFallback, isTrue);

      f.cwaOnly = true;
      f.at(f.now + EewRealtimeSource.fallbackInterval);
      await f.source.fetch();
      f.polls.last.complete([_wire('cwa', 'a'), _wire('scdzj', 'c')]);
      await pumpEventQueue();
      expect((await f.source.fetch()).valueOrNull?.map((e) => e.id), [
        'a',
      ], reason: 'cwaOnly applies to a polled list too');
    });

    test('polls once per interval, never two at a time', () async {
      await f.downFor(EewRealtimeSource.fallbackGrace);
      expect(f.polls, hasLength(1));

      // The first poll hangs past the interval: no second one stacks on it.
      f.at(f.now + const Duration(seconds: 12));
      await f.source.fetch();
      expect(f.polls, hasLength(1));

      f.polls.single.complete(const []);
      await pumpEventQueue();
      await f.source.fetch(); // 12 s since the last send: due
      expect(f.polls, hasLength(2));
      f.polls.last.complete(const []);
      await pumpEventQueue();

      f.at(f.now + const Duration(seconds: 9));
      await f.source.fetch();
      expect(f.polls, hasLength(2), reason: 'not yet an interval since');
      f.at(f.now + const Duration(seconds: 1));
      await f.source.fetch();
      expect(f.polls, hasLength(3));
    });

    test(
      'a snapshot is answered with for the hold, then the source fails',
      () async {
        await f.downFor(EewRealtimeSource.fallbackGrace);
        f.polls.single.complete([_wire('cwa', 'a')]);
        await pumpEventQueue();
        final landed = f.now;

        // Every later poll fails: the snapshot is served until the hold runs
        // out, and then the channel is told the truth.
        f.at(landed + EewRealtimeSource.fallbackHold);
        expect((await f.source.fetch()).isOk, isTrue);
        f.polls.last.completeError(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        );
        await pumpEventQueue();
        f.at(
          landed + EewRealtimeSource.fallbackHold + const Duration(seconds: 1),
        );
        expect((await f.source.fetch()).isOk, isFalse);
        expect(f.source.servingFallback, isFalse);
      },
    );

    test(
      'the stream coming back stops polling and discards a poll in flight',
      () async {
        await f.downFor(EewRealtimeSource.fallbackGrace);
        final inFlight = f.polls.single;

        f.reconnect();
        await pumpEventQueue();
        f.stream.add(const SseEvent(data: '[]'));
        await pumpEventQueue();
        final streamed = await f.source.fetch();
        expect(streamed.valueOrNull, isEmpty);
        expect(f.source.servingFallback, isFalse);

        inFlight.complete([_wire('cwa', 'late')]); // lands after the stream
        await pumpEventQueue();
        f.at(f.now + const Duration(minutes: 1));
        expect((await f.source.fetch()).valueOrNull, isEmpty);
        expect(
          f.polls,
          hasLength(1),
          reason: 'no polling while the stream is up',
        );
      },
    );

    test('pausing for the background ends the fallback', () async {
      await f.downFor(EewRealtimeSource.fallbackGrace);
      f.polls.single.complete([_wire('cwa', 'a')]);
      await pumpEventQueue();
      expect((await f.source.fetch()).isOk, isTrue);

      f.source
        ..pause()
        ..resume();
      expect(
        (await f.source.fetch()).isOk,
        isFalse,
        reason: 'a snapshot from before the background is not an answer',
      );
      expect(f.source.servingFallback, isFalse);
    });

    test('without a poll the source is the stream alone', () async {
      final source = EewRealtimeSource(
        () => const Stream<SseEvent>.empty(),
        cwaOnly: () => false,
        elapsed: f.elapsed,
        delay: (_) => Completer<void>().future,
      );
      addTearDown(source.dispose);
      f.at(const Duration(minutes: 5));
      expect((await source.fetch()).isOk, isFalse);
      expect(source.servingFallback, isFalse);
    });
  });
}

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

Map<String, dynamic> _wire(String author, String id) => {
  'author': author,
  'id': id,
  'serial': 1,
  'status': 0,
  'final': 0,
  'eq': {
    'time': 1700000000000,
    'lon': 121.5,
    'lat': 24.0,
    'depth': 10.0,
    'mag': 5.0,
    'loc': 'test',
    'max': 4,
  },
};

/// An EEW source whose stream, clock, reconnect delay and fallback polls are
/// all driven by hand.
class _Fallback {
  _Fallback() {
    source = EewRealtimeSource(
      () {
        final controller = StreamController<SseEvent>();
        streams.add(controller);
        return controller.stream;
      },
      cwaOnly: () => cwaOnly,
      poll: () {
        final completer = Completer<List<dynamic>>();
        polls.add(completer);
        return completer.future;
      },
      elapsed: elapsed,
      delay: (_) {
        final completer = Completer<void>();
        reconnects.add(completer);
        return completer.future;
      },
    );
  }

  late final EewRealtimeSource source;
  final elapsed = _FakeElapsed();
  final streams = <StreamController<SseEvent>>[];
  final polls = <Completer<List<dynamic>>>[];
  final reconnects = <Completer<void>>[];
  bool cwaOnly = false;

  StreamController<SseEvent> get stream => streams.last;
  Duration get now => elapsed.value;
  void at(Duration t) => elapsed.value = t;

  /// Opens the stream, drops it, and fetches across [down] of outage.
  Future<void> downFor(Duration down) async {
    await source.fetch();
    await stream.close();
    await pumpEventQueue();
    await source.fetch(); // the outage starts here
    at(now + down);
    await source.fetch();
  }

  /// Lets the queued reconnect fire.
  void reconnect() => reconnects.last.complete();
}
