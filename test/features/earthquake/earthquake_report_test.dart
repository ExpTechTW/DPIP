import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EarthquakeReport', () {
    final json = <String, dynamic>{
      'id': '115053-2026-0731-005836',
      'lat': 23.1,
      'lon': 121.36,
      'depth': 20.2,
      'loc': '臺東縣政府北北東方  44.1  公里 (位於臺東縣成功鎮)',
      'mag': 4.7,
      'time': 1785430716000,
      'trem': 0,
      'list': {
        '臺東縣': {
          'int': 4,
          'town': {
            '成功鎮': {'lon': 121.36, 'lat': 23.1, 'int': 4},
            '長濱鄉': {'lon': 121.4, 'lat': 23.3, 'int': 3},
          },
        },
      },
    };

    test('fromJson round-trip', () {
      final report = EarthquakeReport.fromJson(json);
      expect(report.id, '115053-2026-0731-005836');
      expect(report.magnitude, 4.7);
      expect(report.isLocalFelt, isFalse);
      expect(report.hasNumber, isTrue);
      expect(report.number, '115053');
      expect(report.shortLocation, '臺東縣成功鎮');
      expect(report.maxIntensity, 4);
      expect(report.list['臺東縣']?.town['成功鎮']?.intensity, 4);
      expect(EarthquakeReport.fromJson(report.toJson()), report);
    });

    test('…000 serial is local-felt, not a numbered report', () {
      final report = EarthquakeReport.fromJson({
        ...json,
        'id': '115000-2026-0731-005836',
      });
      expect(report.isLocalFelt, isTrue);
      expect(report.hasNumber, isFalse);
      expect(report.number, isNull);
    });

    test('reportUrl and reportImageUrl are derived from id/time/magnitude', () {
      final report = EarthquakeReport.fromJson(json);
      expect(
        report.reportUrl.toString(),
        'https://scweb.cwa.gov.tw/zh-tw/earthquake/details/2026073100583647053',
      );
      expect(
        report.reportImageUrl.toString(),
        'https://scweb.cwa.gov.tw/webdata/OLDEQ/202607/2026073100583647053_H.png',
      );
    });
  });
}
