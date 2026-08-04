import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_list_page.dart';
import 'package:flutter_test/flutter_test.dart';

PartialEarthquakeReport _report(String id, int timeMs) =>
    PartialEarthquakeReport(
      id: id,
      longitude: 121,
      latitude: 23,
      location: '測試',
      depth: 10,
      magnitude: 4,
      intensity: 3,
      time: timeMs,
      trem: 0,
      md5: 'x',
    );

void main() {
  group('taipeiCalendarDay', () {
    test('UTC evening rolls to next Taipei calendar day', () {
      // 2026-08-03 17:00 UTC = 2026-08-04 01:00 Taipei
      final utc = DateTime.utc(2026, 8, 3, 17);
      expect(taipeiCalendarDay(utc), DateTime(2026, 8, 4));
    });
  });

  group('groupReportsByTaipeiDay', () {
    test('merges consecutive same-day rows, splits on day change', () {
      // Two on Aug 4 Taipei, one on Aug 3 Taipei.
      final a = _report(
        '1',
        DateTime.utc(2026, 8, 3, 20).millisecondsSinceEpoch,
      );
      final b = _report(
        '2',
        DateTime.utc(2026, 8, 3, 18).millisecondsSinceEpoch,
      );
      final c = _report(
        '3',
        DateTime.utc(2026, 8, 3, 10).millisecondsSinceEpoch,
      );
      final sections = groupReportsByTaipeiDay([a, b, c]);
      expect(sections, hasLength(2));
      expect(sections[0].day, DateTime(2026, 8, 4));
      expect(sections[0].reports.map((r) => r.id), ['1', '2']);
      expect(sections[1].day, DateTime(2026, 8, 3));
      expect(sections[1].reports.single.id, '3');
    });
  });
}
