import 'dart:async';
import 'dart:typed_data';

import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/eew_live_activity_data.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/data/eew_live_activity_publisher.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final towns = TownDirectory.fromJson({
    '970': {
      'city': '花蓮',
      'town': '花蓮',
      'lat': 23.9817,
      'lng': 121.6040,
      'cityLevel': '縣',
      'townLevel': '市',
    },
    '407': {
      'city': '臺中',
      'town': '西屯',
      'lat': 24.1658,
      'lng': 120.6337,
      'cityLevel': '市',
      'townLevel': '區',
    },
  });
  const table = SeismicTravelTimeTable({
    0: [(p: 0, r: 0, s: 0), (p: 0.4, r: 2, s: 0.703)],
  });

  RegionStore regions() => RegionStore(
    SettingsStore.inMemory({
      'home.savedRegionCodes': ['970', '407'],
    }),
  )..select(2); // the first saved township, 970

  EewLiveActivityPublisher publisher(
    _RecordingData data, {
    int appBuild = 426000900,
    GpsFix? lastFix,
    Stream<GpsFix>? fixes,
    RegionStore? regionStore,
    bool enabled = true,
  }) => EewLiveActivityPublisher(
    data: data,
    table: Future.value(table),
    appBuild: appBuild,
    lastFix: () async => lastFix,
    fixes: fixes ?? const Stream.empty(),
    regions: regionStore ?? regions(),
    towns: towns,
    enabled: enabled,
  );

  test('writes the table when the stored copy is from another build', () async {
    final data = _RecordingData(storedVersion: 426000800);
    publisher(data).start();
    await pumpEventQueue();

    expect(data.tables, hasLength(1));
    expect(data.tables.single.version, 426000900);
    expect(data.tables.single.bytes.sublist(0, 4), 'DPSW'.codeUnits);
  });

  test('leaves the table alone when this build already wrote it', () async {
    final data = _RecordingData(storedVersion: 426000900);
    publisher(data).start();
    await pumpEventQueue();

    expect(data.tables, isEmpty);
  });

  test('an unknown build always rewrites the table', () async {
    final data = _RecordingData(storedVersion: 0);
    publisher(data, appBuild: 0).start();
    await pumpEventQueue();

    expect(data.tables, hasLength(1));
  });

  test('a table that cannot be packed is not written', () async {
    final data = _RecordingData();
    EewLiveActivityPublisher(
      data: data,
      table: Future.value(const SeismicTravelTimeTable({})),
      appBuild: 1,
      lastFix: () async => null,
      fixes: const Stream.empty(),
      regions: regions(),
      towns: towns,
      enabled: true,
    ).start();
    await pumpEventQueue();

    expect(data.tables, isEmpty);
  });

  test('publishes the last fix, then every new one', () async {
    final data = _RecordingData();
    final fixes = StreamController<GpsFix>();
    addTearDown(fixes.close);
    publisher(
      data,
      lastFix: (lat: 23.97, lng: 121.60),
      fixes: fixes.stream,
    ).start();
    await pumpEventQueue();
    fixes.add((lat: 24.0, lng: 121.62));
    await pumpEventQueue();

    expect(data.fixes, [(lat: 23.97, lng: 121.60), (lat: 24.0, lng: 121.62)]);
  });

  test('no cached fix writes no fix, so a stored one is kept', () async {
    final data = _RecordingData();
    publisher(data).start();
    await pumpEventQueue();

    expect(data.fixes, isEmpty);
  });

  test('publishes the selected township and follows the selection', () async {
    final data = _RecordingData();
    final store = regions();
    final subject = publisher(data, regionStore: store)..start();
    addTearDown(subject.dispose);
    await pumpEventQueue();

    expect(data.towns, [(code: '970', lat: 23.9817, lng: 121.6040)]);

    store.select(3); // 407
    store.select(3); // unchanged: not written again
    store.select(0); // 全國: no township
    await pumpEventQueue();

    expect(data.towns, [
      (code: '970', lat: 23.9817, lng: 121.6040),
      (code: '407', lat: 24.1658, lng: 120.6337),
      null,
    ]);
  });

  test('stops following the selection once disposed', () async {
    final data = _RecordingData();
    final store = regions();
    publisher(data, regionStore: store)
      ..start()
      ..dispose()
      ..dispose();
    store.select(3);
    await pumpEventQueue();

    expect(data.towns, hasLength(1));
  });

  test('does nothing off iOS, and starts only once', () async {
    final data = _RecordingData();
    publisher(data, enabled: false).start();
    await pumpEventQueue();
    expect(data.calls, 0);

    final twice = _RecordingData();
    publisher(twice)
      ..start()
      ..start();
    await pumpEventQueue();
    expect(twice.tables, hasLength(1));
    expect(twice.towns, hasLength(1));
  });
}

final class _RecordingData implements EewLiveActivityData {
  _RecordingData({this.storedVersion});

  final int? storedVersion;
  final tables = <({Uint8List bytes, int version})>[];
  final fixes = <GpsFix>[];
  final towns = <({String code, double lat, double lng})?>[];
  int calls = 0;

  @override
  Future<int?> travelTimeVersion() async {
    calls++;
    return storedVersion;
  }

  @override
  Future<bool> writeTravelTime(Uint8List table, {required int version}) async {
    calls++;
    tables.add((bytes: table, version: version));
    return true;
  }

  @override
  Future<bool> writeFix({required double lat, required double lng}) async {
    calls++;
    fixes.add((lat: lat, lng: lng));
    return true;
  }

  @override
  Future<bool> writeTown(({String code, double lat, double lng})? town) async {
    calls++;
    towns.add(town);
    return true;
  }
}
