/// `homeProviders` is a list of lazy create closures. Nothing in the list
/// runs until a widget reads the controller, so a test has to ask for each
/// one or the closures stay uncovered.
library;

import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/current_weather_widget_coordinator.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS callback forwards region and weather to Widget publish', () async {
    final weather = _weather();
    String? publishedRegionCode;
    WeatherRealtime? publishedWeather;
    final callback = createCurrentWeatherWidgetCallback(
      platform: TargetPlatform.iOS,
      publish: ({required regionCode, required weather}) async {
        publishedRegionCode = regionCode;
        publishedWeather = weather;
      },
    );

    expect(callback, isNotNull);

    await callback!('660', weather);

    expect(publishedRegionCode, '660');
    expect(publishedWeather, same(weather));
  });

  test('Widget callback is enabled for iOS and Android', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      final callback = createCurrentWeatherWidgetCallback(
        platform: platform,
        publish: _unusedPublish,
      );

      expect(callback, isNotNull, reason: '$platform has a home-screen Widget');
    }
  });

  test('Widget callback is disabled where there is no home-screen Widget', () {
    for (final platform in TargetPlatform.values.where(
      (platform) =>
          platform != TargetPlatform.iOS && platform != TargetPlatform.android,
    )) {
      final callback = createCurrentWeatherWidgetCallback(
        platform: platform,
        publish: _unusedPublish,
      );

      expect(
        callback,
        isNull,
        reason: '$platform has no home-screen Widget to publish to',
      );
    }
  });

  // The wiring the app actually runs: the Home callback → the real coordinator
  // → the real publisher → the writer. An adapter test on its own would pass
  // with the coordinator unplugged, which is the state this replaced.
  test(
    'an Android Home update reaches the writer as a source-tagged snapshot',
    () async {
      final regions = RegionStore(
        SettingsStore.inMemory({
          'home.savedRegionCodes': ['660'],
        }),
      );
      final writer = _RecordingWriter();
      final coordinator = CurrentWeatherWidgetCoordinator(
        regions,
        _directoryWithXitun(),
        CurrentWeatherWidgetPublisher(writer),
        time: () => (
          calibratedNow: DateTime.utc(2026, 9, 16, 4),
          calibratedTimeOffset: const Duration(minutes: -5),
        ),
        isTimeSynced: () => true,
        syncTime: () async {},
      );
      regions.select(2);

      final callback = createCurrentWeatherWidgetCallback(
        platform: TargetPlatform.android,
        publish: coordinator.publish,
      );

      await callback!('660', _weather());

      expect(writer.writes, hasLength(1));
      expect(writer.writes.single.kind, WidgetSnapshotKind.currentWeather);
      final decoded =
          jsonDecode(writer.writes.single.json) as Map<String, dynamic>;
      expect(decoded['sourceIdentifier'], 'region:660');
      expect(decoded['regionCode'], '660');
    },
  );

  test('an Android Home update is ignored when the selection has moved', () async {
    // A late callback for a region the user has already left must not publish:
    // the Widget would otherwise show the town the app was on a moment ago.
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['660', '661'],
      }),
    );
    final writer = _RecordingWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      regions,
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
      time: () => (
        calibratedNow: DateTime.utc(2026, 9, 16, 4),
        calibratedTimeOffset: Duration.zero,
      ),
      isTimeSynced: () => true,
      syncTime: () async {},
    );
    regions.select(2);

    final callback = createCurrentWeatherWidgetCallback(
      platform: TargetPlatform.android,
      publish: coordinator.publish,
    );

    await callback!('999', _weather());

    expect(writer.writes, isEmpty);
  });

  testWidgets(
    'an Android selection change preserves the previous widget snapshot',
    (tester) async {
      final regions = RegionStore(
        SettingsStore.inMemory({
          'home.savedRegionCodes': ['660', '661'],
        }),
      );
      final directory = _directoryWithXitun();
      final writer = _RecordingWriter();
      final coordinator = CurrentWeatherWidgetCoordinator(
        regions,
        directory,
        CurrentWeatherWidgetPublisher(writer),
        time: () => (
          calibratedNow: DateTime.utc(2026, 9, 16, 4),
          calibratedTimeOffset: Duration.zero,
        ),
        isTimeSynced: () => true,
        syncTime: () async {},
      );
      regions.select(2);
      final location = LocationService(
        directory,
        isAvailable: () async => false,
        fix: () async => null,
        lastKnown: () async => null,
        status: () async => LocationStatus.denied,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CurrentWeatherWidgetSync>.value(value: coordinator),
            Provider<MeteorWeatherRepository>.value(value: _Weather()),
            Provider<RainHourTrendRepository>.value(value: _Hours()),
            ChangeNotifierProvider<RegionStore>.value(value: regions),
            Provider<TownDirectory>.value(value: directory),
            Provider<LocationService>.value(value: location),
            ...homeProviders(),
          ],
          child: Builder(
            builder: (context) {
              context.read<HomeWeatherController>();
              return const SizedBox();
            },
          ),
        ),
      );
      await coordinator.publish(regionCode: '660', weather: _weather());
      final cached = writer.currentWeatherSnapshots['region:660'];
      expect(cached, isNotNull);

      // Run the real provider wiring and the controller's invalidation callback.
      // No replacement observation arrives: an offline selection change must not
      // erase the snapshot a desktop widget still uses for the previous town.
      regions.select(3);
      await tester.pump();
      expect(writer.currentWeatherSnapshots['region:660'], cached);
      expect(writer.clears, isEmpty);
      expect(writer.blanketClears, 0);

      regions.select(0);
      await tester.pump();
      expect(writer.currentWeatherSnapshots['region:660'], cached);
      expect(writer.clears, isEmpty);
      expect(writer.blanketClears, 0);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  test('an iOS selection change still clears the whole kind', () async {
    final writer = _RecordingWriter();
    final coordinator = CurrentWeatherWidgetCoordinator(
      RegionStore(
        SettingsStore.inMemory({
          'home.savedRegionCodes': ['660'],
        }),
      ),
      _directoryWithXitun(),
      CurrentWeatherWidgetPublisher(writer),
      time: () => (
        calibratedNow: DateTime.utc(2026, 9, 16, 4),
        calibratedTimeOffset: Duration.zero,
      ),
      isTimeSynced: () => true,
      syncTime: () async {},
    );

    final invalidate = createCurrentWeatherWidgetInvalidatedCallback(
      platform: TargetPlatform.iOS,
      clear: coordinator.clear,
    );
    await invalidate!();

    expect(writer.blanketClears, 1);
    expect(writer.clears, isEmpty);
  });

  test('iOS invalidation callback invokes Widget clear once', () async {
    var clearCallCount = 0;
    final callback = createCurrentWeatherWidgetInvalidatedCallback(
      platform: TargetPlatform.iOS,
      clear: () async {
        clearCallCount += 1;
      },
    );

    expect(callback, isNotNull);

    await callback!();

    expect(clearCallCount, 1);
  });

  test('invalidation callback is disabled where there is no Widget', () {
    for (final platform in TargetPlatform.values.where(
      (platform) =>
          platform != TargetPlatform.iOS && platform != TargetPlatform.android,
    )) {
      final callback = createCurrentWeatherWidgetInvalidatedCallback(
        platform: platform,
        clear: _unusedClear,
      );

      expect(callback, isNull, reason: '$platform must not clear iOS Widgets');
    }
  });

  testWidgets('each home provider builds its controller', (tester) async {
    final store = RegionStore(SettingsStore.inMemory());
    const directory = TownDirectory({});
    final location = LocationService(
      directory,
      isAvailable: () async => false,
      fix: () async => null,
      lastKnown: () async => null,
      status: () async => LocationStatus.denied,
    );

    late HomeSheetExtent extent;
    late HomeResetSignal reset;
    late MapCameraHandoff camera;
    late MapStationHandoff stations;
    late HomeWeatherController weather;
    late HomeActiveEventsController events;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CurrentWeatherWidgetSync>.value(value: _WidgetSync()),
          Provider<MeteorWeatherRepository>.value(value: _Weather()),
          Provider<RainHourTrendRepository>.value(value: _Hours()),
          ChangeNotifierProvider<RegionStore>.value(value: store),
          Provider<TownDirectory>.value(value: directory),
          Provider<LocationService>.value(value: location),
          Provider<EventRepository>.value(value: _Events()),
          ...homeProviders(),
        ],
        child: Builder(
          builder: (context) {
            extent = context.read<HomeSheetExtent>();
            reset = context.read<HomeResetSignal>();
            camera = context.read<MapCameraHandoff>();
            stations = context.read<MapStationHandoff>();
            weather = context.read<HomeWeatherController>();
            events = context.read<HomeActiveEventsController>();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(extent.value, HomeSheetExtent.rest);
    expect(weather.areaCode, isNull);
    expect(events.events, isEmpty);
    reset.fire();
    expect(camera.homeBounds, isNull);
    expect(stations, isNotNull);
  });
}

/// One township, enough for the coordinator to build a snapshot.
TownDirectory _directoryWithXitun() => TownDirectory.fromJson({
  '660': {
    'city': '臺中',
    'town': '西屯',
    'lat': 24.18,
    'lng': 120.64,
    'cityLevel': '市',
    'townLevel': '區',
  },
});

Future<void> _unusedPublish({
  required String regionCode,
  required WeatherRealtime weather,
}) async {}

Future<void> _unusedClear() async {}

WeatherRealtime _weather() => WeatherRealtime(
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
    rain: 0,
    wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
    gust: WeatherWind(speed: 3, beaufort: 2),
  ),
);

/// Records what the coordinator asked the platform to store.
class _RecordingWriter implements WidgetSnapshotWriter {
  final writes = <({WidgetSnapshotKind kind, String json})>[];
  final clears = <({WidgetSnapshotKind kind, String? source})>[];
  final currentWeatherSnapshots = <String, String>{};
  int blanketClears = 0;

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    writes.add((kind: kind, json: json));
    if (kind == WidgetSnapshotKind.currentWeather && sourceIdentifier != null) {
      currentWeatherSnapshots[sourceIdentifier] = json;
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear({
    required WidgetSnapshotKind kind,
    String? sourceIdentifier,
  }) async {
    if (sourceIdentifier == null) {
      blanketClears += 1;
      currentWeatherSnapshots.clear();
    } else {
      clears.add((kind: kind, source: sourceIdentifier));
      currentWeatherSnapshots.remove(sourceIdentifier);
    }
    return const Ok(null);
  }
}

class _WidgetSync implements CurrentWeatherWidgetSync {
  final published = <String>[];
  int blanketClears = 0;

  @override
  Future<void> publish({
    required String regionCode,
    required WeatherRealtime weather,
  }) async {
    published.add(regionCode);
  }

  @override
  Future<void> clear() async {
    blanketClears += 1;
  }
}

class _Weather implements MeteorWeatherRepository {
  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(null);

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(const WeatherForecast(updateTime: 0, forecast: []));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _Hours implements RainHourTrendRepository {
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend.dry(startUtc: DateTime.utc(2026, 1, 15)));
}

class _Events implements EventRepository {
  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      const Ok([]);
}
