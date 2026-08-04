import 'package:dpip/features/earthquake/data/report_repository_impl.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartialEarthquakeReport', () {
    final json = <String, dynamic>{
      'id': '115053-2026-0731-005836',
      'lat': 23.1,
      'lon': 121.36,
      'depth': 20.2,
      'loc': '臺東縣政府北北東方  44.1  公里 (位於臺東縣成功鎮)',
      'mag': 4.7,
      'time': 1785430716000,
      'int': 4,
      'trem': 0,
      'md5': 'CA8BE086DEBDBEE92136F6D903D6713D',
    };

    test('fromJson round-trip', () {
      final report = PartialEarthquakeReport.fromJson(json);
      expect(report.id, '115053-2026-0731-005836');
      expect(report.magnitude, 4.7);
      expect(report.intensity, 4);
      expect(report.isLocalFelt, isFalse);
      expect(report.hasNumber, isTrue);
      expect(report.number, '115053');
      expect(report.serial, '115053');
      expect(report.shortLocation, '臺東縣成功鎮');
      expect(PartialEarthquakeReport.fromJson(report.toJson()), report);
    });

    test('…000 serial is local-felt, not a numbered report', () {
      final report = PartialEarthquakeReport.fromJson({
        ...json,
        'id': '115000-2026-0731-005836',
      });
      expect(report.serial, '115000');
      expect(report.isLocalFelt, isTrue);
      expect(report.hasNumber, isFalse);
      expect(report.number, isNull);
    });

    test('parseReportList skips junk rows', () {
      final list = ReportRepositoryImpl.parseReportList([
        json,
        'nope',
        {'id': 1},
      ]);
      expect(list, hasLength(1));
      expect(list.single.id, json['id']);
    });
  });
}
