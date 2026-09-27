/// [Clock] is the wall-clock testability seam: production code depends on the
/// abstraction, [SystemClock] is its only real-time implementation, and every
/// realtime test in this suite substitutes its own [Clock] instead of calling
/// `DateTime.now()` directly.
library;

import 'package:dpip/core/realtime/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  test('SystemClock.now reflects the real wall clock', () {
    const clock = SystemClock();
    final before = DateTime.now();
    final reading = clock.now();
    final after = DateTime.now();

    expect(reading.isBefore(before), isFalse);
    expect(reading.isAfter(after), isFalse);
  });

  test('Clock is a narrow seam any fake can satisfy', () {
    final fixed = DateTime.utc(2020);
    final Clock clock = _FixedClock(fixed);
    expect(clock.now(), fixed);
  });
}
