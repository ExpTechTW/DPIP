import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements Clock {
  _FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}

class _FakeElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _FakeSource implements ServerTimeSource {
  _FakeSource(this.ms);
  final int ms;
  @override
  Future<Result<int>> serverTimeMs() async => Ok(ms);
}

void main() {
  final device = DateTime.utc(2026, 1, 1, 0, 0, 0);

  test('delegates to the installed clock; utc8 is utc + 8h', () async {
    final clock = ServerClock(
      _FakeClock(device),
      _FakeElapsed(),
      _FakeSource(device.millisecondsSinceEpoch),
    );
    await clock.sync();
    AppTime.install(clock);

    expect(AppTime.isSynced, isTrue);
    expect(AppTime.utc, device);
    expect(AppTime.utc8, device.add(const Duration(hours: 8)));
    // UTC+8 wall-clock fields (Taipei), independent of the device timezone.
    expect(AppTime.utc8.hour, 8);
  });
}
