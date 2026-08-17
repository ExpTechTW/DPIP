/// Regression coverage for the 強震監視器 demo's EEW card colour badge: it
/// must reflect [MonitorDemo]'s loaded magnitude/depth, not a hardcoded
/// placeholder that always reads intensity 0 regardless of how big the event is.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/data/monitor_demo.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeReports implements ReportRepository {
  _FakeReports(this.row);
  final PartialEarthquakeReport row;

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) async => Ok([row]);

  @override
  Future<Result<EarthquakeReport>> get(String id) => throw UnimplementedError();
}

PartialEarthquakeReport _report({
  required double magnitude,
  required double depth,
  required double longitude,
  required double latitude,
}) => PartialEarthquakeReport(
  id: 'demo-1',
  longitude: longitude,
  latitude: latitude,
  location: '測試地點',
  depth: depth,
  magnitude: magnitude,
  intensity: 0,
  time: DateTime.now().toUtc().millisecondsSinceEpoch,
  trem: 0,
  md5: '',
);

void main() {
  test("a demo event's EEW max is the epicentre's estimated intensity, not a "
      'hardcoded 0', () async {
    final report = _report(
      magnitude: 7.5,
      depth: 10,
      longitude: 121.7,
      latitude: 23.9,
    );
    await MonitorDemo.load(_FakeReports(report));

    final expected = Intensity.toScale(
      EewEstimator.locationInfo(
        mag: MonitorDemo.magnitude,
        depth: MonitorDemo.depth,
        epicenter: MonitorDemo.epicenter,
        user: MonitorDemo.epicenter,
      ).i,
    );
    expect(
      expected,
      greaterThan(0),
      reason: 'a M7.5/10km event must not read as intensity 0',
    );

    final source = DemoEewSource(_FakeReports(report));
    final alerts = (await source.fetch()).valueOrNull;
    expect(alerts, isNotNull);
    expect(
      alerts!.single.info.max,
      expected,
      reason:
          "the card's colour badge reads info.max — it must track the "
          'loaded magnitude/depth like every other consumer of this math',
    );
    source.dispose();
  });

  test('a small, distant demo event legitimately reads a low max — the fix '
      'computes the value, it does not force a nonzero one', () async {
    final report = _report(
      magnitude: 3.0,
      depth: 80,
      longitude: 121.7,
      latitude: 23.9,
    );
    await MonitorDemo.load(_FakeReports(report));

    final source = DemoEewSource(_FakeReports(report));
    final alerts = (await source.fetch()).valueOrNull;
    expect(alerts!.single.info.max, 0);
    source.dispose();
  });
}
