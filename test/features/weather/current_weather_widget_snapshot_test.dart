import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';

void main() {
  test('creates a current weather widget snapshot', () {
    final weather = WeatherRealtime(
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

    final snapshot = createCurrentWeatherWidgetSnapshot(
      regionCode: '660',
      regionName: '西屯區',
      weather: weather,
    );

    expect(snapshot.schemaVersion, 1);
    expect(snapshot.regionCode, '660');
    expect(snapshot.regionName, '西屯區');
    expect(snapshot.observationTime, 1789398000);
    expect(snapshot.stationName, '西屯');
    expect(snapshot.weather, '多雲');
    expect(snapshot.weatherCode, 200);
    expect(snapshot.temperature, 28.4);
    expect(snapshot.humidity, 76);
    expect(snapshot.rain, 0.0);

    final json = jsonEncode(snapshot.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], 1);
    expect(decoded['regionCode'], '660');
    expect(decoded['temperature'], 28.4);
  });

  test('preserves null weather values', () {
    final weather = WeatherRealtime(
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
        temperature: null,
        humidity: null,
        rain: null,
        wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
        gust: WeatherWind(speed: 3.0, beaufort: 2),
      ),
    );

    final snapshot = createCurrentWeatherWidgetSnapshot(
      regionCode: '660',
      regionName: '西屯區',
      weather: weather,
    );

    expect(snapshot.temperature, isNull);
    expect(snapshot.humidity, isNull);
    expect(snapshot.rain, isNull);

    final json = jsonEncode(snapshot.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['temperature'], isNull);
    expect(decoded['humidity'], isNull);
    expect(decoded['rain'], isNull);
  });
}
