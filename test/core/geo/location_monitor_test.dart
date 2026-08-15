import 'dart:async';

import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two townships far enough apart that moving between them is a real region
/// change, resolved by nearest-centroid.
const _tainanCode = '710';
const _taipeiCode = '100';
const _tainanFix = (lat: 23.026, lng: 120.257);
const _taipeiFix = (lat: 25.032, lng: 121.518);

TownDirectory _directory() => TownDirectory.fromJson({
  _taipeiCode: {
    'city': '臺北市',
    'town': '中正區',
    'lat': 25.032,
    'lng': 121.518,
    'cityLevel': '市',
    'townLevel': '區',
  },
  _tainanCode: {
    'city': '臺南市',
    'town': '永康區',
    'lat': 23.026,
    'lng': 120.257,
    'cityLevel': '市',
    'townLevel': '區',
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionStore regions;
  late StreamController<GpsFix> positions;
  late DeviceLocationReporter reporter;
  late LocationService location;

  setUp(() async {
    final settings = SettingsStore.inMemory({});
    regions = RegionStore(settings);
    // Broadcast so a recovery-driven `reporter.restart()` can re-subscribe (a
    // single-subscription stream throws on the second listen).
    positions = StreamController<GpsFix>.broadcast();
    reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      settings: settings,
      onMoved: (fix) async => true,
    );
    location = LocationService(
      _directory(),
      isAvailable: () async => true,
      fix: () async => null,
    );
  });

  tearDown(() async {
    reporter.dispose();
    if (!positions.isClosed) await positions.close();
  });

  test('the current township follows the device as it moves', () async {
    final monitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regions,
    )..start();
    reporter.start();
    await pumpEventQueue();

    positions.add((lat: _tainanFix.lat, lng: _tainanFix.lng));
    await pumpEventQueue();
    expect(
      regions.currentCode,
      _tainanCode,
      reason: 'the first fix should publish the township it lands in',
    );

    // Travelling to another county must re-publish — before this existed the
    // township was resolved once at launch and never again, so the app kept
    // naming (and alerting for) wherever it started.
    positions.add((lat: _taipeiFix.lat, lng: _taipeiFix.lng));
    await pumpEventQueue();
    expect(regions.currentCode, _taipeiCode);

    monitor.dispose();
  });

  test('a move inside the same township does not churn listeners', () async {
    final monitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regions,
    )..start();
    reporter.start();
    await pumpEventQueue();

    var notifications = 0;
    regions.addListener(() => notifications++);

    positions.add((lat: _tainanFix.lat, lng: _tainanFix.lng));
    await pumpEventQueue();
    expect(notifications, 1);

    // A different coordinate, same township — no region change to announce.
    positions.add((lat: _tainanFix.lat + 0.001, lng: _tainanFix.lng + 0.001));
    await pumpEventQueue();
    expect(notifications, 1);

    monitor.dispose();
  });

  test('fixes stop being tracked once the monitor is disposed', () async {
    final monitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regions,
    )..start();
    reporter.start();
    await pumpEventQueue();

    positions.add((lat: _tainanFix.lat, lng: _tainanFix.lng));
    await pumpEventQueue();
    monitor.dispose();

    positions.add((lat: _taipeiFix.lat, lng: _taipeiFix.lng));
    await pumpEventQueue();
    expect(regions.currentCode, _tainanCode);
  });

  test('GPS loss clears the township so 所在地 degrades to nationwide', () async {
    var available = true;
    final location = LocationService(
      _directory(),
      isAvailable: () async => available,
      fix: () async => _tainanFix,
      status: () async =>
          available ? LocationStatus.ready : LocationStatus.serviceOff,
    );
    final monitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regions,
    )..start();
    reporter.start();
    await pumpEventQueue();

    positions.add((lat: _tainanFix.lat, lng: _tainanFix.lng));
    await pumpEventQueue();
    expect(regions.currentCode, _tainanCode);

    // Services off → the monitor re-checks on resume and must not keep the
    // last-known township as the current one (the backdrop would frame it).
    available = false;
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await pumpEventQueue();
    expect(regions.currentCode, isNull);

    monitor.dispose();
  });

  test('GPS returning re-resolves the current township', () async {
    var available = false;
    final location = LocationService(
      _directory(),
      isAvailable: () async => available,
      fix: () async => _taipeiFix,
      status: () async =>
          available ? LocationStatus.ready : LocationStatus.serviceOff,
    );
    final monitor = LocationMonitor(
      location: location,
      reporter: reporter,
      regions: regions,
    )..start();
    reporter.start();
    await pumpEventQueue();
    expect(regions.currentCode, isNull);

    // Recovery re-resolves 所在地 instead of leaving it nationwide.
    available = true;
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await pumpEventQueue();
    expect(regions.currentCode, _taipeiCode);

    monitor.dispose();
  });
}
