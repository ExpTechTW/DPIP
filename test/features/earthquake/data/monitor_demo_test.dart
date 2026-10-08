/// The debug monitor demo has to keep working when the catalogue is empty,
/// and a later poll must be a new serial rather than a second earthquake.
///
/// A missed empty-catalogue fallback would freeze the map on a blank event.
/// A sameData that compared the whole alert would treat the twelve-second
/// serial bump as the same frame, so the card would never refresh. The RTS
/// demo must still draw from the saved station directory when the refresh
/// fails, because that is the connection an earthquake has just degraded.
library;

import 'package:fake_async/fake_async.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/data/monitor_demo.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:flutter_test/flutter_test.dart';

PartialEarthquakeReport _row({
  String location = '花蓮縣近海',
  double magnitude = 5.4,
  double depth = 12,
}) => PartialEarthquakeReport(
  id: '115001-test',
  longitude: 121.6,
  latitude: 23.9,
  location: location,
  depth: depth,
  magnitude: magnitude,
  intensity: 4,
  time: 0,
  trem: 0,
  md5: 'md5',
);

class _Reports implements ReportRepository {
  _Reports(this.rows);

  List<PartialEarthquakeReport> rows;

  @override
  Future<Result<EarthquakeReport>> get(String id) async =>
      const Err(NoDataFailure('unused'));

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) async => Ok(rows);
}

class _Stations implements TremStationRepository {
  _Stations({this.savedDirectory, this.refreshDirectory});

  final Map<String, SeismicStation>? savedDirectory;
  final Result<Map<String, SeismicStation>>? refreshDirectory;

  @override
  Future<Result<Map<String, SeismicStation>>> refresh() async =>
      refreshDirectory ?? const Err(NetworkFailure('offline'));

  @override
  Future<Map<String, SeismicStation>?> saved() async => savedDirectory;
}

const _station = SeismicStation(id: 'A', latitude: 23.9, longitude: 121.6);

void main() {
  test('an empty catalogue leaves the Hualien fallback in place', () async {
    final before = MonitorDemo.origin;
    await MonitorDemo.load(_Reports(const []));

    expect(MonitorDemo.loaded, isFalse);
    expect(MonitorDemo.location, '花蓮縣');
    expect(MonitorDemo.epicenter.latitude, 23.8);
    expect(MonitorDemo.magnitude, 6.5);
    expect(MonitorDemo.origin, before);
  });

  test('a blank short place falls back to the full location string', () async {
    await MonitorDemo.load(_Reports([_row(location: '   ')]));

    expect(MonitorDemo.loaded, isTrue);
    expect(MonitorDemo.location, '   ');
    expect(MonitorDemo.magnitude, 5.4);
    expect(MonitorDemo.depth, 12);
  });

  test('the newest report replaces the fallback epicentre', () async {
    await MonitorDemo.load(_Reports([_row(location: '花蓮縣近海')]));

    expect(MonitorDemo.location, '花蓮縣近海');
    expect(MonitorDemo.epicenter.longitude, 121.6);
    expect(MonitorDemo.epicenter.latitude, 23.9);
  });

  test('the startup alert is one stable value, not a new serial', () async {
    final clock = DateTime.utc(2026, 10, 4);
    final source = StartupEewDemoSource(clock: () => clock);
    final first = (await source.fetch()).valueOrNull!;
    final second = (await source.fetch()).valueOrNull!;

    expect(first.single.info.time, clock.millisecondsSinceEpoch);
    expect(source.timestampOf(first), isNull);
    expect(source.sameData(null, null), isTrue);
    expect(source.sameData(null, first), isFalse);
    expect(source.sameData(first, const []), isFalse);
    expect(source.sameData(first, second), isTrue);
    expect(source.sameData(first, [first.single.copyWith(serial: 2)]), isFalse);
  });

  test('the demo EEW bumps its serial and ignores everything but that', () {
    fakeAsync((async) {
      final source = DemoEewSource(_Reports([_row(magnitude: 6.2)]));
      async.elapse(Duration.zero);

      final first = source.fetch();
      async.elapse(Duration.zero);
      late List<Eew> opened;
      first.then((result) => opened = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(opened.single.serial, 1);
      expect(opened.single.info.magnitude, 6.2);
      expect(source.timestampOf(opened), isNull);

      async.elapse(const Duration(seconds: 12));
      late List<Eew> next;
      source.fetch().then((result) => next = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(next.single.serial, 2);
      expect(source.sameData(opened, next), isFalse);
      expect(source.sameData(null, next), isFalse);
      expect(source.sameData(next, const []), isFalse);
      expect(source.sameData(next, next), isTrue);
      source.dispose();
    });
  });

  test('the RTS demo shakes the refreshed directory', () {
    fakeAsync((async) {
      // Keep frame timestamps in the same time domain as the periodic timer.
      final start = DateTime.utc(2026, 10, 8);
      final source = DemoRtsSource(
        stations: _Stations(refreshDirectory: const Ok({'A': _station})),
        clock: async.getClock(start).now,
      );
      async.elapse(Duration.zero);

      late Rts frame;
      source.fetch().then((result) => frame = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(frame.stations, contains('A'));
      expect(frame.time, start.millisecondsSinceEpoch);
      expect(source.timestampOf(frame), isNull);

      async.elapse(const Duration(seconds: 1));
      late Rts later;
      source.fetch().then((result) => later = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(later.time, isNot(frame.time));
      expect(later.time - frame.time, 1000);
      source.dispose();
    });
  });

  test('the RTS demo uses the saved directory when refresh fails', () {
    fakeAsync((async) {
      final source = DemoRtsSource(
        stations: _Stations(savedDirectory: const {'A': _station}),
      );
      async.elapse(Duration.zero);

      late Rts frame;
      source.fetch().then((result) => frame = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(frame.stations.keys, ['A']);
      source.dispose();
    });
  });

  test('the RTS demo stays calm when no directory exists', () {
    fakeAsync((async) {
      final source = DemoRtsSource(stations: _Stations());
      async.elapse(Duration.zero);

      late Rts frame;
      source.fetch().then((result) => frame = result.valueOrNull!);
      async.elapse(Duration.zero);
      expect(frame.stations, isEmpty);
      source.dispose();
    });
  });
}
