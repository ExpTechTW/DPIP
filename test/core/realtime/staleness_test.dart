import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/staleness.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden/table tests for the safety-critical freshness classifier. The
/// boundaries decide whether a possibly-stale EEW alert is presented as live, so
/// they are pinned exactly — change a threshold deliberately.
void main() {
  const staleAfter = Duration(seconds: 3);
  const offlineAfter = Duration(seconds: 10);

  RealtimeStatus at({Duration? age, Duration sinceStart = Duration.zero}) =>
      classifyStatus(
        age: age,
        sinceStart: sinceStart,
        staleAfter: staleAfter,
        offlineAfter: offlineAfter,
      );

  group('classifyStatus — no data yet', () {
    test('within the connect window → connecting', () {
      expect(
        at(sinceStart: const Duration(seconds: 5)),
        RealtimeStatus.connecting,
      );
    });

    test('exactly at offlineAfter → still connecting (inclusive)', () {
      expect(
        at(sinceStart: const Duration(seconds: 10)),
        RealtimeStatus.connecting,
      );
    });

    test('past offlineAfter → offline (gave up)', () {
      expect(
        at(sinceStart: const Duration(seconds: 10, milliseconds: 1)),
        RealtimeStatus.offline,
      );
    });
  });

  group('classifyStatus — has data', () {
    test('fresh → live', () {
      expect(at(age: Duration.zero), RealtimeStatus.live);
    });

    test('age exactly staleAfter → live (inclusive)', () {
      expect(at(age: const Duration(seconds: 3)), RealtimeStatus.live);
    });

    test('just past staleAfter → stale', () {
      expect(
        at(age: const Duration(seconds: 3, milliseconds: 1)),
        RealtimeStatus.stale,
      );
    });

    test('age exactly offlineAfter → stale (inclusive)', () {
      expect(at(age: const Duration(seconds: 10)), RealtimeStatus.stale);
    });

    test('past offlineAfter → offline', () {
      expect(
        at(age: const Duration(seconds: 10, milliseconds: 1)),
        RealtimeStatus.offline,
      );
    });

    test(
      'negative age (future timestamp / clock anomaly) → stale, never live',
      () {
        expect(at(age: const Duration(seconds: -5)), RealtimeStatus.stale);
      },
    );
  });
}
