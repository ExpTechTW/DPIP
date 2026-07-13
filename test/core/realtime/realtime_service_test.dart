import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 1, 1);
}

class _FakeElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _CountingServerTimeSource implements ServerTimeSource {
  int calls = 0;
  @override
  Future<Result<int>> serverTimeMs() async {
    calls++;
    return const Ok(0);
  }
}

class _FakeTicker implements Ticker {
  void Function()? _onTick;
  int startCount = 0;
  final _FakeTickerHandle handle = _FakeTickerHandle();

  @override
  TickerHandle start(Duration interval, void Function() onTick) {
    _onTick = onTick;
    startCount++;
    handle.cancelled = false;
    return handle;
  }

  void fire() => _onTick?.call();
}

class _FakeTickerHandle implements TickerHandle {
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
}

/// Records the lifecycle calls it receives (with its id) into a shared log, so
/// the fan-out order across channels is observable.
class _RecordingChannel implements RealtimeChannelBase {
  _RecordingChannel(this.id, this.log);
  final String id;
  final List<String> log;

  @override
  void start() => log.add('$id:start');
  @override
  void pause() => log.add('$id:pause');
  @override
  void resume() => log.add('$id:resume');
  @override
  void recomputeStatus() => log.add('$id:recompute');
  @override
  Future<void> refreshNow() async => log.add('$id:refresh');
  @override
  void dispose() => log.add('$id:dispose');
}

void main() {
  late RealtimeService service;
  late List<String> log;
  late _FakeTicker ticker;
  late _CountingServerTimeSource source;
  late _RecordingChannel a;
  late _RecordingChannel b;

  setUp(() {
    log = [];
    ticker = _FakeTicker();
    source = _CountingServerTimeSource();
    service = RealtimeService(
      ServerClock(_FixedClock(), _FakeElapsed(), source),
      ticker: ticker,
    );
    a = _RecordingChannel('a', log);
    b = _RecordingChannel('b', log);
    service.register(a);
    service.register(b);
  });

  test('startAll starts every channel', () {
    service.startAll();
    expect(log, ['a:start', 'b:start']);
  });

  test('onBackground pauses every channel', () {
    service.onBackground();
    expect(log, ['a:pause', 'b:pause']);
  });

  test('onForeground recomputes ALL channels before resuming ANY', () {
    service.onForeground();
    // Recompute-all-first is the anti-"stale-as-live" ordering; the whole thing
    // runs synchronously (no await), so a slow clock sync cannot stall resume.
    expect(log, ['a:recompute', 'b:recompute', 'a:resume', 'b:resume']);
  });

  test('dispose disposes every channel', () {
    service.dispose();
    expect(log, ['a:dispose', 'b:dispose']);
  });

  test('startAll runs a periodic clock sync; onBackground halts it', () async {
    service.startAll();
    expect(ticker.startCount, 1, reason: 'clock-sync ticker started');

    ticker.fire(); // 60s elapsed
    await Future<void>.value(); // let the fire-and-forget sync() microtask run
    expect(source.calls, 1, reason: 'a tick re-anchors the clock');

    service.onBackground();
    expect(
      ticker.handle.cancelled,
      isTrue,
      reason: 'sync paused in background',
    );
  });

  test('onForeground syncs immediately and restarts the ticker', () async {
    service.startAll();
    service.onBackground(); // cancels the ticker
    ticker.startCount = 0; // reset to observe the restart

    service.onForeground();
    await Future<void>.value();
    expect(source.calls, greaterThanOrEqualTo(1), reason: 'immediate resync');
    expect(ticker.startCount, 1, reason: 'periodic sync restarted');
  });
}
