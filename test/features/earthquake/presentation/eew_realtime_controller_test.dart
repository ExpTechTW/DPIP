/// The EEW-specific view over a realtime channel: [alerts] never surfaces
/// null (empty list when there is none), [primaryAlert] is the convenience a
/// banner reads without checking emptiness itself, and [status] is what a
/// consumer must check before treating [primaryAlert] as still current.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _FakeTicker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) =>
      _FakeTickerHandle();
}

class _FakeTickerHandle implements TickerHandle {
  @override
  void cancel() {}
}

class _FakeEewSource extends RealtimeSource<List<Eew>> {
  Result<List<Eew>> next = const Ok(<Eew>[]);
  @override
  Future<Result<List<Eew>>> fetch() async => next;
  @override
  DateTime? timestampOf(List<Eew> value) => null;
  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}

Eew _eew(String id) => Eew(
  agency: 'cwa',
  id: id,
  serial: 1,
  status: 1,
  isFinal: false,
  info: EewInfo(
    time: 1700000000000,
    longitude: 121.5,
    latitude: 24.0,
    depth: 10.0,
    magnitude: 5.0,
    location: '花蓮縣',
    max: 4,
  ),
);

Future<void> pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeElapsed elapsed;
  late _FakeEewSource source;
  late RealtimeChannel<List<Eew>> channel;
  late EewRealtimeController controller;

  setUp(() {
    elapsed = _FakeElapsed();
    source = _FakeEewSource();
    channel = RealtimeChannel<List<Eew>>(
      source: source,
      clock: _FakeClock(DateTime.utc(2026, 1, 1)),
      elapsed: elapsed,
      ticker: _FakeTicker(),
      config: RealtimeConfig.eew,
    );
    controller = EewRealtimeController(channel);
  });

  tearDown(() {
    controller.dispose();
  });

  test(
    'seeds from the channel state at construction (connecting, no alerts)',
    () {
      expect(controller.status, RealtimeStatus.connecting);
      expect(controller.alerts, isEmpty);
      expect(controller.primaryAlert, isNull);
      expect(controller.isLive, isFalse);
    },
  );

  test('rebuilds and exposes alerts once a fetch lands', () async {
    final alert = _eew('2026-eq-1');
    source.next = Ok([alert]);
    var notified = false;
    controller.addListener(() => notified = true);

    await channel.refreshNow();
    await pump();

    expect(notified, isTrue);
    expect(controller.isLive, isTrue);
    expect(controller.alerts, [alert]);
    expect(controller.primaryAlert, alert);
  });

  test(
    'primaryAlert is null when the feed is live but has no active alert',
    () async {
      source.next = const Ok(<Eew>[]);
      await channel.refreshNow();
      await pump();

      expect(controller.isLive, isTrue);
      expect(controller.alerts, isEmpty);
      expect(controller.primaryAlert, isNull);
    },
  );

  test(
    'primaryAlert is the first (most relevant) alert when several are active',
    () async {
      final first = _eew('first');
      final second = _eew('second');
      source.next = Ok([first, second]);

      await channel.refreshNow();
      await pump();

      expect(controller.primaryAlert, first);
    },
  );

  test('isStale reflects the channel status once data has aged', () async {
    source.next = const Ok(<Eew>[]);
    await channel.refreshNow();
    await pump();
    expect(controller.isLive, isTrue);

    source.next = const Err(TimeoutFailure('down'));
    elapsed.value += const Duration(seconds: 4);
    channel.recomputeStatus();
    await pump();

    expect(controller.isStale, isTrue);
    expect(controller.isLive, isFalse);
  });
}
