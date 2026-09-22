import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/current_weather_widget_coordinator.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default clock adapters sync before publishing calibrated time',
    () async {
      final deviceNow = DateTime.utc(2026, 9, 16, 4);
      final source = _ControlledTimeSource();
      AppTime.install(
        ServerClock(_FakeClock(deviceNow), _FakeElapsed(), source),
      );
      final regions = RegionStore(
        SettingsStore.inMemory({
          'home.savedRegionCodes': ['660'],
        }),
      );
      final writer = _FakeWidgetSnapshotWriter();
      final coordinator = CurrentWeatherWidgetCoordinator(
        regions,
        _directoryWithXitun(),
        CurrentWeatherWidgetPublisher(writer),
      );
      regions.select(2);

      final publish = coordinator.publish(
        regionCode: '660',
        weather: _weather(),
      );

      expect(source.requests, hasLength(1));
      expect(writer.writeCallCount, 0);

      source.requests.single.complete(
        Ok(deviceNow.add(const Duration(minutes: 3)).millisecondsSinceEpoch),
      );
      await publish;

      expect(writer.writeCallCount, 1);
      final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;
      expect(decoded['calibratedTimeOffsetMilliseconds'], 180_000);
    },
  );

  test('already synced publishes immediately with calibrated offset', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660'],
      }),
    );
    final directory = _directoryWithXitun();
    final writer = _FakeWidgetSnapshotWriter();
    var syncCallCount = 0;
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      directory,
      CurrentWeatherWidgetPublisher(writer),
      time: () => (
        calibratedNow: DateTime.utc(2026, 9, 16, 4),
        calibratedTimeOffset: const Duration(minutes: -5),
      ),
      isTimeSynced: () => true,
      syncTime: () async {
        syncCallCount += 1;
      },
    );

    regions.select(2);

    await coordinator.publish(regionCode: '660', weather: _weather());

    expect(syncCallCount, 0);
    expect(writer.writeCallCount, 1);
    expect(writer.writtenKind, WidgetSnapshotKind.currentWeather);
    expect(writer.writtenSourceIdentifier, 'region:660');

    final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], 6);
    expect(decoded['sourceIdentifier'], 'region:660');
    expect(decoded['regionCode'], '660');
    expect(decoded['regionName'], '西屯區');
    expect(decoded['stationName'], '西屯');
    expect(decoded['weather'], '多雲');
    expect(decoded['isNight'], isA<bool>());
    expect(decoded['nextDayNightTransitionTime'], isA<int>());
    expect(decoded['calibratedTimeOffsetMilliseconds'], -300_000);
    expect(decoded['temperature'], 28.4);
    expect(decoded['windDirection'], '北');
    expect(decoded['windSpeed'], 1.5);
  });

  test('waits for initial sync then publishes exactly once', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660'],
      }),
    );
    final writer = _FakeWidgetSnapshotWriter();
    final sync = Completer<void>();
    var isSynced = false;
    var timeCallCount = 0;
    var syncCallCount = 0;
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
      time: () {
        timeCallCount += 1;
        return (
          calibratedNow: DateTime.utc(2026, 9, 16, 4),
          calibratedTimeOffset: const Duration(minutes: 3),
        );
      },
      isTimeSynced: () => isSynced,
      syncTime: () {
        syncCallCount += 1;
        return sync.future;
      },
    );
    regions.select(2);

    final publish = coordinator.publish(regionCode: '660', weather: _weather());

    expect(syncCallCount, 1);
    expect(timeCallCount, 0);
    expect(writer.writeCallCount, 0);

    isSynced = true;
    sync.complete();
    await publish;

    expect(timeCallCount, 1);
    expect(writer.writeCallCount, 1);
    final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;
    expect(decoded['calibratedTimeOffsetMilliseconds'], 180_000);
  });

  test('does not publish when initial sync fails', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660'],
      }),
    );
    final writer = _FakeWidgetSnapshotWriter();
    var timeCallCount = 0;
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
      time: () {
        timeCallCount += 1;
        return (
          calibratedNow: DateTime.utc(2026, 9, 16, 4),
          calibratedTimeOffset: Duration.zero,
        );
      },
      isTimeSynced: () => false,
      syncTime: () async {},
    );
    regions.select(2);

    await coordinator.publish(regionCode: '660', weather: _weather());

    expect(timeCallCount, 0);
    expect(writer.writeCallCount, 0);
  });

  test('does not publish when region changes while sync is pending', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660', '100'],
      }),
    );
    final writer = _FakeWidgetSnapshotWriter();
    final sync = Completer<void>();
    var isSynced = false;
    var timeCallCount = 0;
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
      time: () {
        timeCallCount += 1;
        return (
          calibratedNow: DateTime.utc(2026, 9, 16, 4),
          calibratedTimeOffset: Duration.zero,
        );
      },
      isTimeSynced: () => isSynced,
      syncTime: () => sync.future,
    );
    regions.select(2);

    final publish = coordinator.publish(regionCode: '660', weather: _weather());
    regions.select(3);
    isSynced = true;
    sync.complete();
    await publish;

    expect(regions.selectedCode, '100');
    expect(timeCallCount, 0);
    expect(writer.writeCallCount, 0);
  });

  test('does not publish when the selected region does not match', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660', '100'],
      }),
    );
    final writer = _FakeWidgetSnapshotWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
    );

    regions.select(3);

    await coordinator.publish(regionCode: '660', weather: _weather());

    expect(regions.selectedCode, '100');
    expect(writer.called, isFalse);
  });

  test('does not publish when the selected town is unknown', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660'],
      }),
    );
    final writer = _FakeWidgetSnapshotWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      TownDirectory.fromJson(const {}),
      CurrentWeatherWidgetPublisher(writer),
    );

    regions.select(2);

    await coordinator.publish(regionCode: '660', weather: _weather());

    expect(writer.called, isFalse);
  });

  test('clear delegates to the current weather writer path', () async {
    final regions = RegionStore(SettingsStore.inMemory());
    final writer = _FakeWidgetSnapshotWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
    );

    await coordinator.clear();

    expect(writer.clearCallCount, 1);
    expect(writer.clearedKind, WidgetSnapshotKind.currentWeather);
  });
}

TownDirectory _directoryWithXitun() {
  return TownDirectory.fromJson({
    '660': {
      'city': '臺中',
      'town': '西屯',
      'lat': 24.18,
      'lng': 120.64,
      'cityLevel': '市',
      'townLevel': '區',
    },
  });
}

WeatherRealtime _weather() {
  return WeatherRealtime(
    id: 'C0X160',
    station: const WeatherRealtimeStation(
      name: '西屯',
      latitude: 24.18,
      longitude: 120.64,
      altitude: 85,
      distance: 1.2,
    ),
    time: 1789398000,
    data: const WeatherRealtimeData(
      weather: '多雲',
      weatherCode: 200,
      temperature: 28.4,
      humidity: 76,
      rain: 0.0,
      wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
      gust: WeatherWind(speed: 3.0, beaufort: 2),
    ),
  );
}

final class _FakeWidgetSnapshotWriter implements WidgetSnapshotWriter {
  bool called = false;
  int writeCallCount = 0;
  WidgetSnapshotKind? writtenKind;
  String? writtenJson;
  String? writtenSourceIdentifier;
  int clearCallCount = 0;
  WidgetSnapshotKind? clearedKind;

  @override
  Future<Result<void>> clear({required WidgetSnapshotKind kind}) async {
    clearCallCount += 1;
    clearedKind = kind;
    return const Ok(null);
  }

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    called = true;
    writeCallCount += 1;
    writtenKind = kind;
    writtenJson = json;
    writtenSourceIdentifier = sourceIdentifier;

    return const Ok(null);
  }
}

final class _FakeClock implements Clock {
  _FakeClock(this.current);

  final DateTime current;

  @override
  DateTime now() => current;
}

final class _FakeElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

final class _ControlledTimeSource implements ServerTimeSource {
  final requests = <Completer<Result<int>>>[];

  @override
  Future<Result<int>> serverTimeMs() {
    final request = Completer<Result<int>>();
    requests.add(request);
    return request.future;
  }
}
