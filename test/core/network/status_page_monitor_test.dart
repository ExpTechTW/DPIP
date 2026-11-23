import 'package:dpip/core/network/status_page_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 23, 12);
int _unix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _summary(String level, {Duration age = Duration.zero}) => {
  'version': 1,
  'generated_at': _unix(_now.subtract(age)),
  'level': level,
  'since': _unix(_now.subtract(const Duration(hours: 1))),
  'services': const <Object?>[],
};

void main() {
  group('StatusSummary.parse', () {
    test('reads the level and the server timestamp', () {
      final s = StatusSummary.parse(_summary('partial'))!;
      expect(s.level, 'partial');
      expect(s.generatedAt, _now);
      expect(s.generatedAt.isUtc, isTrue);
      expect(s.isAbnormal, isTrue);
    });

    test('accepts an undecoded body', () {
      final s = StatusSummary.parse(
        '{"version":1,"generated_at":${_unix(_now)},"level":"outage",'
        '"since":0,"services":[]}',
      );
      expect(s?.level, 'outage');
    });

    test('only partial and outage are abnormal', () {
      for (final (level, abnormal) in [
        ('ok', false),
        ('unknown', false),
        ('partial', true),
        ('outage', true),
        ('something-new', false),
      ]) {
        expect(
          StatusSummary.parse(_summary(level))!.isAbnormal,
          abnormal,
          reason: level,
        );
      }
    });

    test('rejects what is not a summary', () {
      expect(StatusSummary.parse(null), isNull);
      expect(StatusSummary.parse('not json'), isNull);
      expect(StatusSummary.parse(const <Object?>[]), isNull);
      expect(StatusSummary.parse(const {'level': 'ok'}), isNull);
      expect(StatusSummary.parse({'generated_at': _unix(_now)}), isNull);
      expect(
        StatusSummary.parse({'level': 1, 'generated_at': _unix(_now)}),
        isNull,
      );
    });

    test('fresh only within maxAge either side of now', () {
      const maxAge = Duration(minutes: 10);
      bool fresh(Duration offset) => StatusSummary(
        level: 'partial',
        generatedAt: _now.subtract(offset),
      ).isFreshAt(_now, maxAge);
      expect(fresh(Duration.zero), isTrue);
      expect(fresh(const Duration(minutes: 10)), isTrue);
      expect(fresh(const Duration(minutes: 11)), isFalse);
      expect(fresh(const Duration(minutes: -11)), isFalse);
    });
  });

  group('StatusPageMonitor', () {
    late DateTime clock;
    late Object? reply;
    late int reads;

    StatusPageMonitor monitor() => StatusPageMonitor(
      fetch: () async {
        reads++;
        final r = reply;
        if (r is Exception) throw r;
        return r;
      },
      now: () => clock,
    );

    setUp(() {
      clock = _now;
      reply = null;
      reads = 0;
    });

    test('starts quiet, and lights while the page reports a problem', () async {
      final status = monitor();
      var notified = 0;
      status.addListener(() => notified++);
      expect(status.abnormal, isFalse);

      reply = _summary('ok');
      await status.refresh();
      expect(status.abnormal, isFalse);
      expect(notified, 0);

      reply = _summary('partial');
      await status.refresh();
      expect(status.abnormal, isTrue);
      expect(notified, 1);

      reply = _summary('outage');
      await status.refresh();
      expect(status.abnormal, isTrue);
      expect(notified, 1, reason: 'still abnormal — no new notification');

      reply = _summary('ok');
      await status.refresh();
      expect(status.abnormal, isFalse);
      expect(notified, 2);
      status.dispose();
    });

    test('a stale summary lights nothing', () async {
      final status = monitor();
      reply = _summary('outage', age: const Duration(minutes: 30));
      await status.refresh();
      expect(status.abnormal, isFalse);
      status.dispose();
    });

    test('a failed read keeps the last summary until it ages out', () async {
      final status = monitor();
      reply = _summary('partial');
      await status.refresh();
      expect(status.abnormal, isTrue);

      reply = Exception('offline');
      clock = _now.add(const Duration(minutes: 5));
      await status.refresh();
      expect(status.abnormal, isTrue);

      clock = _now.add(const Duration(minutes: 11));
      await status.refresh();
      expect(status.abnormal, isFalse);
      status.dispose();
    });

    test('an unreadable reply keeps the last summary', () async {
      final status = monitor();
      reply = _summary('partial');
      await status.refresh();
      reply = 'not json';
      await status.refresh();
      expect(status.abnormal, isTrue);
      status.dispose();
    });

    test('concurrent refreshes share one read', () async {
      final status = monitor();
      reply = _summary('ok');
      await Future.wait([status.refresh(), status.refresh()]);
      expect(reads, 1);
      status.dispose();
    });

    test('a read that lands after dispose does nothing', () async {
      final status = monitor();
      reply = _summary('partial');
      final pending = status.refresh();
      status.dispose();
      await pending;
      expect(status.abnormal, isFalse);
    });
  });
}
