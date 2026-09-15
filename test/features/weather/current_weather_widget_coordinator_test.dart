import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/current_weather_widget_coordinator.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes a snapshot for the matching selected region', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660'],
      }),
    );
    final directory = _directoryWithXitun();
    final writer = _FakeWidgetSnapshotWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      directory,
      CurrentWeatherWidgetPublisher(writer),
    );

    regions.select(2);

    await coordinator.publish(regionCode: '660', weather: _weather());

    expect(writer.called, isTrue);
    expect(writer.writtenKind, WidgetSnapshotKind.currentWeather);

    final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], 1);
    expect(decoded['regionCode'], '660');
    expect(decoded['regionName'], '西屯區');
    expect(decoded['stationName'], '西屯');
    expect(decoded['weather'], '多雲');
    expect(decoded['temperature'], 28.4);
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
  WidgetSnapshotKind? writtenKind;
  String? writtenJson;
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
  }) async {
    called = true;
    writtenKind = kind;
    writtenJson = json;

    return const Ok(null);
  }
}
