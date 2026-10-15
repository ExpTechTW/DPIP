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
  void advance(Duration d) => value += d;
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

  group('ServerClock sample window', () {
    /// A clock whose server answers [offsets] (ms, relative to the device) in
    /// turn, one per sync, with monotonic time advancing a minute per sync.
    Future<(ServerClock, _FakeElapsed)> synced(List<int> offsets) async {
      final elapsed = _FakeElapsed();
      final source = _FakeServerTimeSource();
      final clock = ServerClock(_FakeClock(device), elapsed, source);
      for (final offset in offsets) {
        source.result = Ok(
          device.millisecondsSinceEpoch + elapsed.value.inMilliseconds + offset,
        );
        await clock.sync();
        elapsed.advance(const Duration(minutes: 1));
      }
      return (clock, elapsed);
    }

    /// Calibrated time minus where a perfect server would put it.
    int errorMs(ServerClock clock, _FakeElapsed elapsed) =>
        clock.now().difference(device.add(elapsed.value)).inMilliseconds;

    test('averages the window without its highest and lowest sample', () async {
      final (clock, elapsed) = await synced([100, -300, 50, 400, 0]);
      // Sorted -300, 0, 50, 100, 400 → mean of 0, 50, 100.
      expect(errorMs(clock, elapsed), 50);
    });

    test(
      'one noisy sample no longer moves the clock by its full error',
      () async {
        final (clock, elapsed) = await synced([0, 0, 0, 0, 900]);
        expect(
          errorMs(clock, elapsed),
          0,
          reason: 'the outlier is the dropped maximum',
        );
      },
    );

    test('keeps only the last five samples', () async {
      final (clock, elapsed) = await synced([1500, 1500, 0, 0, 0, 0, 0]);
      expect(errorMs(clock, elapsed), 0);
    });

    test('follows a genuine step at once', () async {
      final (clock, elapsed) = await synced([0, 10, -10, 5, 30000]);
      expect(
        errorMs(clock, elapsed),
        30000,
        reason: '30 s away from every sample is a step, not noise',
      );
    });

    test('a sample near any one in the window is not a step', () async {
      // 1.9 s from the latest but within 2 s of it: averaged, not adopted.
      final (clock, elapsed) = await synced([0, 0, 0, 1900, 1900]);
      // Sorted 0, 0, 0, 1900, 1900 → mean of 0, 0, 1900.
      expect(errorMs(clock, elapsed), 633);
    });

    test('a failed sync leaves the window alone', () async {
      final elapsed = _FakeElapsed();
      final source = _FakeServerTimeSource()
        ..result = Ok(device.millisecondsSinceEpoch + 200);
      final clock = ServerClock(_FakeClock(device), elapsed, source);
      await clock.sync();
      source.result = const Err(TimeoutFailure('down'));
      await clock.sync();
      expect(clock.offset, const Duration(milliseconds: 200));
    });

    test('trimmedMean drops nothing below three samples', () {
      expect(ServerClock.trimmedMean([10]), 10);
      expect(ServerClock.trimmedMean([10, 21]), 16);
      expect(ServerClock.trimmedMean([1, 10, 1000]), 10);
    });
  });
}
