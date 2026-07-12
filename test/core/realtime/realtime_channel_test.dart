import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

/// Monotonic time under test control — staleness is measured against this.
class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  void advance(Duration d) => value += d;
  @override
  Duration get elapsed => value;
}

class _FakeTicker implements Ticker {
  void Function()? _onTick;
  int startCount = 0;

  @override
  TickerHandle start(Duration interval, void Function() onTick) {
    _onTick = onTick;
    startCount++;
    return _FakeTickerHandle(this);
  }

  /// Simulates a poll interval elapsing.
  void fire() => _onTick?.call();
}

class _FakeTickerHandle implements TickerHandle {
  _FakeTickerHandle(this._ticker);
  final _FakeTicker _ticker;
  @override
  void cancel() => _ticker._onTick = null;
}

class _FakeSource extends RealtimeSource<int> {
  int fetchCount = 0;
  Result<int> next = const Ok(0);
  Completer<Result<int>>? pending;

  @override
  Future<Result<int>> fetch() async {
    fetchCount++;
    if (pending != null) return pending!.future;
    return next;
  }

  @override
  DateTime? timestampOf(int value) => null; // fetch-freshness
}

/// Flushes pending microtasks so broadcast emissions and unawaited fetches land.
Future<void> pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeClock clock;
  late _FakeElapsed elapsed;
  late _FakeTicker ticker;
  late _FakeSource source;
  late RealtimeChannel<int> channel;
  late List<RealtimeState<int>> events;
  late StreamSubscription<RealtimeState<int>> sub;

  setUp(() {
    clock = _FakeClock(DateTime.utc(2026, 1, 1, 12, 0, 0));
    elapsed = _FakeElapsed();
    ticker = _FakeTicker();
    source = _FakeSource();
    channel = RealtimeChannel<int>(
      source: source,
      clock: clock,
      elapsed: elapsed,
      ticker: ticker,
      config: RealtimeConfig.eew,
      label: 'test',
    );
    events = [];
    sub = channel.states.listen(events.add);
  });

  tearDown(() async {
    await sub.cancel();
    channel.dispose();
  });

  test('start emits the connecting seed', () async {
    channel.start();
    await pump();
    expect(events.first.status, RealtimeStatus.connecting);
  });

  test('successful fetch → live with data, exactly one emission', () async {
    source.next = const Ok(42);
    await channel.refreshNow();
    await pump();
    expect(events, hasLength(1));
    expect(events.single.status, RealtimeStatus.live);
    expect(channel.state.data, 42);
  });

  test('an identical successful fetch does not re-emit', () async {
    source.next = const Ok(42);
    await channel.refreshNow();
    await pump();
    final count = events.length;
    await channel.refreshNow(); // same data, same clock
    await pump();
    expect(events.length, count);
  });

  test('ages live → stale → offline when polls stop succeeding', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();
    expect(channel.state.status, RealtimeStatus.live);

    // Feed stops responding; monotonic time advances so status ages on its own.
    source.next = const Err(TimeoutFailure('down'));
    elapsed.advance(const Duration(seconds: 4)); // age 4s > staleAfter(3)
    ticker.fire();
    await pump();
    expect(channel.state.status, RealtimeStatus.stale);

    elapsed.advance(const Duration(seconds: 7)); // age 11s > offlineAfter(10)
    ticker.fire();
    await pump();
    expect(channel.state.status, RealtimeStatus.offline);
  });

  test('staleness is immune to a backward wall-clock jump', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();

    source.next = const Err(TimeoutFailure('down'));
    elapsed.advance(const Duration(seconds: 5)); // truly 5s old → stale
    // Wall clock jumps backward 1 minute; must NOT rescue the dead feed.
    clock.current = clock.current.subtract(const Duration(minutes: 1));
    ticker.fire();
    await pump();
    expect(channel.state.status, RealtimeStatus.stale);
  });

  test('a failed poll keeps the last data and counts failures', () async {
    source.next = const Ok(9);
    await channel.refreshNow();
    await pump();

    source.next = const Err(NetworkFailure('boom'));
    await channel.refreshNow();
    await pump();
    expect(channel.state.data, 9); // retained, never blanked
    expect(channel.state.lastFailure, isA<NetworkFailure>());
    expect(channel.state.consecutiveFailures, 1);

    source.next = const Ok(10);
    await channel.refreshNow();
    await pump();
    expect(channel.state.data, 10);
    expect(channel.state.consecutiveFailures, 0);
    expect(channel.state.lastFailure, isNull);
  });

  test('a slow poll is not stacked by the next tick', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();

    source.pending = Completer<Result<int>>(); // next fetch hangs
    ticker.fire();
    await pump();
    final countWhileInFlight = source.fetchCount;

    ticker.fire(); // fetch still in flight → must not start another
    await pump();
    expect(source.fetchCount, countWhileInFlight);

    source.pending!.complete(const Ok(1)); // let it finish for a clean teardown
    await pump();
  });

  test('refreshNow awaits an already in-flight poll', () async {
    final gate = Completer<Result<int>>();
    source.pending = gate;
    channel.start(); // immediate fetch hangs on the gate
    await pump();

    var done = false;
    final refresh = channel.refreshNow().then((_) => done = true);
    await pump();
    expect(done, isFalse); // still waiting on the in-flight fetch

    gate.complete(const Ok(7));
    await refresh;
    expect(done, isTrue);
    expect(channel.state.data, 7);
  });

  test('a fetch in flight across pause is discarded, not applied', () async {
    source.pending = Completer<Result<int>>();
    channel.start(); // immediate fetch hangs
    await pump();
    expect(channel.state.hasData, isFalse);

    channel.pause(); // invalidates the in-flight fetch (epoch bump)
    source.pending!.complete(const Ok(99)); // pre-pause fetch resolves late
    await pump();

    // Must NOT re-flip to live with the stale result.
    expect(channel.state.data, isNull);
    expect(channel.state.status, isNot(RealtimeStatus.live));
  });

  test('pause stops polling', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();
    final countAtPause = source.fetchCount;

    channel.pause();
    ticker.fire();
    await pump();
    expect(source.fetchCount, countAtPause);
  });

  test('resume recomputes status before refetching', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();
    channel.pause();

    elapsed.advance(const Duration(seconds: 20)); // long background gap
    final before = events.length;
    channel.resume();
    await pump();

    final after = events.skip(before).map((s) => s.status).toList();
    expect(after.first, RealtimeStatus.offline); // recompute precedes refetch
    expect(channel.state.status, RealtimeStatus.live); // then the refetch lands
  });

  test('multiple listeners share a single poll loop', () async {
    final a = <RealtimeState<int>>[];
    final b = <RealtimeState<int>>[];
    final subA = channel.states.listen(a.add);
    final subB = channel.states.listen(b.add);

    source.next = const Ok(1);
    channel.start();
    await pump();
    final afterStart = source.fetchCount;

    source.next = const Err(TimeoutFailure('x')); // avoid re-live churn
    ticker.fire();
    await pump();
    expect(
      source.fetchCount,
      afterStart + 1,
    ); // one fetch this tick, not per-listener
    expect(a.length, equals(b.length));
    expect(a, isNotEmpty);

    await subA.cancel();
    await subB.cancel();
  });

  test('dispose stops polling and closes the stream', () async {
    source.next = const Ok(1);
    channel.start();
    await pump();
    final fetches = source.fetchCount;
    final emissions = events.length;

    channel.dispose();
    ticker.fire();
    await channel.refreshNow();
    await pump();

    expect(source.fetchCount, fetches);
    expect(events.length, emissions);
  });
}
