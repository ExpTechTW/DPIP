import 'dart:async';

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

class _ControlledSource implements ServerTimeSource {
  final requests = <Completer<Result<int>>>[];

  @override
  Future<Result<int>> serverTimeMs() {
    final request = Completer<Result<int>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  final device = DateTime.utc(2026, 1, 1, 0, 0, 0);

  test('exposes calibrated time and calibrated-minus-device offset', () async {
    final clock = ServerClock(
      _FakeClock(device),
      _FakeElapsed(),
      _FakeSource(
        device.add(const Duration(seconds: 5)).millisecondsSinceEpoch,
      ),
    );
    await clock.sync();
    AppTime.install(clock);

    expect(AppTime.isSynced, isTrue);
    expect(AppTime.utc, device.add(const Duration(seconds: 5)));
    expect(AppTime.calibratedTimeOffset, const Duration(seconds: 5));
    expect(AppTime.utc8, device.add(const Duration(hours: 8, seconds: 5)));
    // UTC+8 wall-clock fields (Taipei), independent of the device timezone.
    expect(AppTime.utc8.hour, 8);
  });

  test('deduplicates concurrent sync calls', () async {
    final source = _ControlledSource();
    final clock = ServerClock(_FakeClock(device), _FakeElapsed(), source);
    AppTime.install(clock);

    final first = AppTime.sync();
    final second = AppTime.sync();

    expect(source.requests, hasLength(1));
    expect(second, same(first));

    source.requests.single.complete(
      Ok(device.add(const Duration(seconds: 5)).millisecondsSinceEpoch),
    );
    await Future.wait([first, second]);

    expect(AppTime.isSynced, isTrue);
    expect(AppTime.calibratedTimeOffset, const Duration(seconds: 5));
  });
}
