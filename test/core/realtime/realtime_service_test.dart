import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 1, 1);
}

class _FakeServerTimeSource implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async => const Ok(0);
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
  late _RecordingChannel a;
  late _RecordingChannel b;

  setUp(() {
    log = [];
    service = RealtimeService(
      ServerClock(_FixedClock(), _FakeServerTimeSource()),
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
}
