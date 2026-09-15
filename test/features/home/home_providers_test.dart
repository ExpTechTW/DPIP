import 'package:dpip/features/home/home_providers.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
