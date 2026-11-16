/// The live EEW and RTS feeds on one shared SSE connection.
///
/// `sse_mux_test.dart` pins the mux on its own; this pins the two real
/// sources on it, because the failure that matters is between them: a feed
/// whose own reconnect, pause or change of speed opened a second socket, or
/// took the other feed's down with it, passes every test that looks at one
/// feed at a time. Every frame here is a fixture built the way the server
/// builds it — `base64(gzip(json))`, named for its topic — and the connection
/// is a fake: nothing touches the network.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/network/sse_mux.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/data/rts_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:flutter_test/flutter_test.dart';

/// Origin of the fixture event; the reducer's clock is pinned just after it,
/// so the alert is well inside its time on screen.
const _origin = 1790537600000;

const _retry = SseEvent(retry: Duration(seconds: 3));
const _info = SseEvent(
  name: 'info',
  data: '{"location":"lb-tpe1","topics":["eq.eew.v1","trem.rts.v1"]}',
);

String _pack(Object json) =>
    base64.encode(gzip.encode(utf8.encode(jsonEncode(json))));

SseEvent _eewFrame(List<Map<String, dynamic>> alerts) =>
    SseEvent(name: EarthquakeApi.eewTopic, data: _pack(alerts));

SseEvent _rtsFrame(Map<String, dynamic> frame) =>
    SseEvent(name: EarthquakeApi.rtsTopic, data: _pack(frame));

Map<String, dynamic> _alert(String id, {int serial = 1}) => {
  'author': 'cwa',
  'id': id,
  'serial': serial,
  'status': 0,
  'final': 0,
  'eq': {
    'time': _origin,
    'lon': 121.5,
    'lat': 23.9,
    'depth': 10.0,
    'mag': 5.8,
    'loc': '花蓮縣近海',
    'max': 4,
  },
  'time': _origin + 15000,
};

/// One physical connection the mux opened.
class _Link {
  _Link(this.topics, {required this.live});

  final List<String> topics;
  final bool live;
  bool cancelled = false;
  late final controller = StreamController<SseEvent>(
    onCancel: () => cancelled = true,
  );

  void greet() => controller
    ..add(_retry)
    ..add(_info);
}

class _Opener {
  final links = <_Link>[];

  Stream<SseEvent> call(List<String> topics, {required bool live}) {
    final link = _Link(topics, live: live);
    links.add(link);
    return link.controller.stream;
  }

  List<_Link> get open => [
    for (final link in links)
      if (!link.cancelled) link,
  ];
}

void main() {
  late _Opener opener;
  late RtsLiveDemand demand;
  late EewRealtimeSource eew;
  late RtsRealtimeSource rts;

  /// Reconnect and settle delays, completed by hand.
  late List<Completer<void>> delays;

  Future<void> delay(Duration _) {
    final completer = Completer<void>();
    delays.add(completer);
    return completer.future;
  }

  Future<void> elapseDelays() async {
    final pending = [...delays];
    delays.clear();
    for (final completer in pending) {
      completer.complete();
    }
    await pumpEventQueue();
  }

  setUp(() {
    opener = _Opener();
    delays = [];
    demand = RtsLiveDemand();
    final mux = SseMux(opener.call);
    eew = EewRealtimeSource(
      mux.topic(EarthquakeApi.eewTopic, snapshot: true).connect,
      cwaOnly: () => false,
      delay: delay,
      now: () =>
          DateTime.fromMillisecondsSinceEpoch(_origin + 20000, isUtc: true),
    );
    rts = RtsRealtimeSource(
      mux.topic(EarthquakeApi.rtsTopic).connect,
      demand: demand,
      sleepDelay: Duration.zero,
      delay: delay,
    );
  });

  tearDown(() {
    eew.dispose();
    rts.dispose();
  });

  /// Both feeds polled once, as the channels do on start.
  Future<void> start() async {
    await eew.fetch();
    await rts.fetch();
    await pumpEventQueue();
  }

  test('the two topics are named as the server names them', () {
    expect(EarthquakeApi.eewTopic, 'eq.eew.v1');
    expect(EarthquakeApi.rtsTopic, 'trem.rts.v1');
  });

  test('both feeds share one connection that asks for both topics', () async {
    await start();

    expect(opener.links, hasLength(1));
    expect(opener.links.single.topics, ['eq.eew.v1', 'trem.rts.v1']);
    expect(opener.links.single.live, isFalse, reason: 'asleep by default');
  });

  test('each feed inflates and decodes only its own topic', () async {
    await start();
    opener.links.single
      ..greet()
      ..controller.add(_eewFrame([_alert('115001')]))
      ..controller.add(
        _rtsFrame({
          'ts': _origin + 5000,
          'stations': {
            '11DFDBC': {'i': 4.6, 'pga': 38.2, 'alert': 1},
          },
        }),
      );
    await pumpEventQueue();

    final alerts = (await eew.fetch()).valueOrNull;
    expect(alerts, hasLength(1));
    expect(alerts!.single.id, '115001');
    expect(alerts.single.info.location, '花蓮縣近海');

    final frame = (await rts.fetch()).valueOrNull;
    expect(frame?.time, _origin + 5000);
    expect(frame?.stations['11DFDBC']?.alert, isTrue);
  });

  test('every EEW frame is the whole list: the next one replaces it', () async {
    await start();
    final link = opener.links.single
      ..greet()
      ..controller.add(_eewFrame([_alert('115001'), _alert('115002')]));
    await pumpEventQueue();
    expect((await eew.fetch()).valueOrNull, hasLength(2));

    link.controller.add(_eewFrame([_alert('115002', serial: 2)]));
    await pumpEventQueue();
    final alerts = (await eew.fetch()).valueOrNull;
    expect(alerts, hasLength(1));
    expect(alerts!.single.serial, 2);

    link.controller.add(_eewFrame([]));
    await pumpEventQueue();
    expect((await eew.fetch()).valueOrNull, isEmpty);
  });

  test('a ping keeps both feeds connected; close ends both, and they come '
      'back on one new connection', () async {
    await start();
    final link = opener.links.single
      ..greet()
      ..controller.add(_eewFrame([]))
      ..controller.add(const SseEvent.comment('ping 1790537637'));
    await pumpEventQueue();
    expect((await eew.fetch()).isOk, isTrue);
    expect((await rts.fetch()).isOk, isTrue, reason: 'asleep and calm');

    link.controller.add(const SseEvent(name: 'close', data: 'restarting'));
    await pumpEventQueue();
    expect(link.cancelled, isTrue);
    expect((await eew.fetch()).isOk, isFalse);
    expect((await rts.fetch()).isOk, isFalse);

    await elapseDelays(); // each feed's reconnect backoff
    expect(opener.links, hasLength(2));
    expect(opener.open, hasLength(1));

    // The EEW snapshot comes with the new connection's greeting.
    opener.links.last
      ..greet()
      ..controller.add(_eewFrame([_alert('115003')]));
    await pumpEventQueue();
    expect((await eew.fetch()).valueOrNull?.single.id, '115003');
    expect((await rts.fetch()).isOk, isTrue);
  });

  test('the monitor opening switches the one connection to live without '
      'dropping EEW', () async {
    await start();
    final asleep = opener.links.single
      ..greet()
      ..controller.add(_eewFrame([_alert('115001')]));
    await pumpEventQueue();

    demand.hold();
    await pumpEventQueue();
    expect(opener.links, hasLength(2));
    final live = opener.links.last;
    expect(live.live, isTrue);
    expect((await eew.fetch()).isOk, isTrue, reason: 'mid-handover');

    live
      ..greet()
      ..controller.add(_eewFrame([_alert('115001')]))
      ..controller.add(_rtsFrame({'ts': _origin + 6000, 'stations': {}}));
    await pumpEventQueue();
    expect(asleep.cancelled, isTrue);
    expect(opener.open, [live]);
    expect((await eew.fetch()).valueOrNull?.single.id, '115001');
    expect((await rts.fetch()).valueOrNull?.time, _origin + 6000);

    // The monitor closes: back to one sleeping connection.
    demand.release();
    await pumpEventQueue();
    expect(opener.links, hasLength(3));
    expect(opener.links.last.live, isFalse);
    opener.links.last.greet();
    await pumpEventQueue();
    expect(opener.open, [opener.links.last]);
    expect(delays, isEmpty, reason: 'no feed saw a drop to reconnect from');
  });

  test('background closes the one connection; foreground opens one', () async {
    await start();
    final link = opener.links.single..greet();
    await pumpEventQueue();

    eew.pause();
    rts.pause();
    await pumpEventQueue();
    expect(link.cancelled, isTrue);
    expect(opener.open, isEmpty);

    eew.resume();
    rts.resume();
    await start();
    expect(opener.links, hasLength(2));
    expect(opener.open, hasLength(1));
  });

  test('a network change replaces the one connection with one', () async {
    await start();
    final link = opener.links.single..greet();
    await pumpEventQueue();

    eew.networkChanged();
    rts.networkChanged();
    await pumpEventQueue();
    expect(link.cancelled, isTrue);

    await elapseDelays(); // each feed's 1–2 s settle
    expect(opener.links, hasLength(2));
    expect(opener.open, hasLength(1));
  });
}
