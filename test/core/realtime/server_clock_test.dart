import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
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
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _FakeServerTimeSource implements ServerTimeSource {
  Result<int> result = const Err(NetworkFailure('unset'));
  bool hang = false;

  @override
  Future<Result<int>> serverTimeMs() {
    if (hang) return Completer<Result<int>>().future; // never completes
    return Future<Result<int>>.value(result);
  }
}

void main() {
  final device = DateTime.utc(2026, 1, 1, 12, 0, 0);

  group('ServerClock', () {
    test('unsynced → device time (UTC), offset zero', () {
      final clock = ServerClock(
        _FakeClock(device),
        _FakeElapsed(),
        _FakeServerTimeSource(),
      );
      expect(clock.isSynced, isFalse);
      expect(clock.offset, Duration.zero);
      expect(clock.now(), device);
    });

    test('a successful sync anchors calibrated time to the server', () async {
      final source = _FakeServerTimeSource()
        ..result = Ok(device.millisecondsSinceEpoch + 5000); // server 5s ahead
      final clock = ServerClock(_FakeClock(device), _FakeElapsed(), source);

      await clock.sync();

      expect(clock.isSynced, isTrue);
      expect(clock.offset, const Duration(seconds: 5));
      expect(clock.now(), device.add(const Duration(seconds: 5)));
    });

    test(
      'now() advances monotonically and ignores device-clock jumps',
      () async {
        final elapsed = _FakeElapsed();
        final deviceClock = _FakeClock(device);
        final source = _FakeServerTimeSource()
          ..result = Ok(device.millisecondsSinceEpoch);
        final clock = ServerClock(deviceClock, elapsed, source);

        await clock.sync(); // anchor: server == device at mono 0
        expect(clock.now(), device);

        elapsed.value = const Duration(seconds: 10); // 10s of monotonic time
        expect(clock.now(), device.add(const Duration(seconds: 10)));

        // The device wall clock jumps back an hour (or a timezone edit) — the
        // monotonic anchor makes calibrated time immune to it.
        deviceClock.current = device.subtract(const Duration(hours: 1));
        expect(clock.now(), device.add(const Duration(seconds: 10)));
      },
    );

    test('a failed sync keeps the last anchor', () async {
      final source = _FakeServerTimeSource()
        ..result = Ok(device.millisecondsSinceEpoch + 5000);
      final clock = ServerClock(_FakeClock(device), _FakeElapsed(), source);
      await clock.sync();

      source.result = const Err(TimeoutFailure('down'));
      await clock.sync();

      expect(clock.isSynced, isTrue);
      expect(clock.offset, const Duration(seconds: 5));
      expect(clock.now(), device.add(const Duration(seconds: 5)));
    });

    test('sync is bounded by its timeout and degrades gracefully', () async {
      final source = _FakeServerTimeSource()..hang = true;
      final clock = ServerClock(_FakeClock(device), _FakeElapsed(), source);

      await clock.sync(timeout: const Duration(milliseconds: 20));

      expect(clock.isSynced, isFalse);
      expect(clock.offset, Duration.zero);
      expect(clock.now(), device);
    });
  });
}
