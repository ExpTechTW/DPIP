import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  group('RealtimeState', () {
    test('connecting() seed has no data', () {
      const state = RealtimeState<int>.connecting();
      expect(state.status, RealtimeStatus.connecting);
      expect(state.hasData, isFalse);
      expect(state.ageAt(DateTime.utc(2026)), isNull);
    });

    test(
      'equal when status/data/dataTime match — age is computed, not stored',
      () {
        final a = RealtimeState<int>(
          status: RealtimeStatus.live,
          data: 7,
          dataTime: t0,
        );
        final b = RealtimeState<int>(
          status: RealtimeStatus.live,
          data: 7,
          dataTime: t0,
        );
        // Two states are equal regardless of when they're observed.
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
        expect(
          a.ageAt(t0.add(const Duration(seconds: 5))),
          const Duration(seconds: 5),
        );
      },
    );

    test('differs when a field differs', () {
      final base = RealtimeState<int>(
        status: RealtimeStatus.live,
        data: 7,
        dataTime: t0,
      );
      expect(base, isNot(base.copyWith(status: RealtimeStatus.stale)));
      expect(base, isNot(base.copyWith(data: 8)));
      expect(base, isNot(base.copyWith(consecutiveFailures: 1)));
    });

    test('copyWith preserves untouched fields and can set nullables', () {
      final base = RealtimeState<int>(
        status: RealtimeStatus.live,
        data: 7,
        dataTime: t0,
        fetchedAt: t0,
        consecutiveFailures: 0,
      );
      final failed = base.copyWith(
        status: RealtimeStatus.stale,
        lastFailure: const TimeoutFailure('slow'),
        consecutiveFailures: 2,
      );
      expect(failed.data, 7); // retained across the failure
      expect(failed.dataTime, t0);
      expect(failed.status, RealtimeStatus.stale);
      expect(failed.lastFailure, isA<TimeoutFailure>());
      expect(failed.consecutiveFailures, 2);
    });
  });
}
