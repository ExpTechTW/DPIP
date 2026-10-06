/// `homeProviders` is a list of lazy create closures. Nothing in the list
/// runs until a widget reads the controller, so a test has to ask for each
/// one or the closures stay uncovered.
library;

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
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:flutter/foundation.dart';
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

  test('Widget callback is enabled for iOS', () {
    final callback = createCurrentWeatherWidgetCallback(
      platform: TargetPlatform.iOS,
      publish: _unusedPublish,
    );

    expect(callback, isNotNull);
  });

  test('Widget callback is disabled for every non-iOS platform', () {
    for (final platform in TargetPlatform.values.where(
      (platform) => platform != TargetPlatform.iOS,
    )) {
      final callback = createCurrentWeatherWidgetCallback(
        platform: platform,
        publish: _unusedPublish,
      );

      expect(
        callback,
        isNull,
        reason: '$platform must not publish iOS Widgets',
      );
    }
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

  test('invalidation callback is disabled for every non-iOS platform', () {
    for (final platform in TargetPlatform.values.where(
      (platform) => platform != TargetPlatform.iOS,
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

class _WidgetSync implements CurrentWeatherWidgetSync {
  @override
  Future<void> publish({
    required String regionCode,
    required WeatherRealtime weather,
  }) async {}

  @override
  Future<void> clear() async {}
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
