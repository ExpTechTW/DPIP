/// The RTS-specific view over a realtime channel: typed getters plus the one
/// rule a consumer must respect — [isMissingHistory] (a replay polling past
/// retention) is not the same as the feed being broken, and [status] is what
/// tells a caller whether the last snapshot is still safe to present as
/// current.
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
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';
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

class _FakeRtsSource extends RealtimeSource<Rts> {
  Result<Rts> next = Ok(Rts());
  @override
  Future<Result<Rts>> fetch() async => next;
  @override
  DateTime? timestampOf(Rts value) => null;
}

Future<void> pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeElapsed elapsed;
  late _FakeRtsSource source;
  late RealtimeChannel<Rts> channel;
  late RtsRealtimeController controller;

  setUp(() {
    elapsed = _FakeElapsed();
    source = _FakeRtsSource();
    channel = RealtimeChannel<Rts>(
      source: source,
      clock: _FakeClock(DateTime.utc(2026, 1, 1)),
      elapsed: elapsed,
      ticker: _FakeTicker(),
      config: RealtimeConfig.rts,
    );
    controller = RtsRealtimeController(channel);
  });

  tearDown(() {
    controller.dispose();
  });

  test(
    'seeds from the channel state at construction (connecting, no data)',
    () {
      expect(controller.status, RealtimeStatus.connecting);
      expect(controller.rts, isNull);
      expect(controller.stations, isEmpty);
      expect(controller.isLive, isFalse);
    },
  );

  test('rebuilds and exposes the payload once a fetch lands', () async {
    final rts = Rts(
      stations: {'11DFDBC': RtsStation(intensity: 3.0, alert: true)},
      time: 1700000000000,
    );
    source.next = Ok(rts);
    var notified = false;
    controller.addListener(() => notified = true);

    await channel.refreshNow();
    await pump();

    expect(notified, isTrue);
    expect(controller.isLive, isTrue);
    expect(controller.rts, rts);
    expect(controller.stations['11DFDBC']!.intensity, 3.0);
    expect(controller.stations['11DFDBC']!.alert, isTrue);
  });

  test('isStale reflects the channel status once data has aged', () async {
    source.next = Ok(Rts());
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

  test(
    'isMissingHistory is true only when the last failure is NotFoundFailure',
    () async {
      source.next = const Err(
        NotFoundFailure('nothing recorded that far back'),
      );
      await channel.refreshNow();
      await pump();
      expect(controller.isMissingHistory, isTrue);

      source.next = const Err(NetworkFailure('boom'));
      await channel.refreshNow();
      await pump();
      expect(controller.isMissingHistory, isFalse);
    },
  );
}
