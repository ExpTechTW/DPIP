/// [ReplayClock] ticks 1:1 with real elapsed time from a fixed historical
/// start instant — the clock a replay session hands to both its RTS and EEW
/// sources so they poll the same simulated "now".
library;

import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeElapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

void main() {
  test('now() starts at exactly startAt', () {
    final elapsed = _FakeElapsed();
    final startAt = DateTime.utc(2026, 4, 3, 12);
    final clock = ReplayClock(startAt, elapsed: elapsed);

    expect(clock.now(), startAt);
  });

  test('now() advances 1:1 with the monotonic elapsed clock', () {
    final elapsed = _FakeElapsed();
    final startAt = DateTime.utc(2026, 4, 3, 12);
    final clock = ReplayClock(startAt, elapsed: elapsed);

    elapsed.value += const Duration(seconds: 30);
    expect(clock.now(), startAt.add(const Duration(seconds: 30)));

    elapsed.value += const Duration(minutes: 5);
    expect(clock.now(), startAt.add(const Duration(minutes: 5, seconds: 30)));
  });

  test('elapsed time from before construction is not counted', () {
    // The clock marks its own start from whatever the elapsed source already
    // reads (e.g. a process-wide Stopwatch started earlier) — only the delta
    // *since construction* should ever reach now().
    final elapsed = _FakeElapsed()..value = const Duration(hours: 1);
    final startAt = DateTime.utc(2026, 4, 3, 12);
    final clock = ReplayClock(startAt, elapsed: elapsed);

    expect(clock.now(), startAt);

    elapsed.value += const Duration(seconds: 1);
    expect(clock.now(), startAt.add(const Duration(seconds: 1)));
  });

  test('defaults to a real SystemElapsed when none is injected', () {
    final startAt = DateTime.utc(2026, 4, 3, 12);
    final clock = ReplayClock(startAt);

    // No fake to advance, so this only proves construction succeeds and
    // stays anchored near startAt an instant later — real time barely moves.
    final reading = clock.now();
    expect(reading.difference(startAt).inSeconds, 0);
  });
}
