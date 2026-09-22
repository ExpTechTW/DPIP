import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';

void main() {
  group('currentWeatherWidgetCondition', () {
    test('maps weather code families and phenomena', () {
      const cases = <int, CurrentWeatherWidgetCondition>{
        100: .clear,
        200: .cloudy,
        300: .overcast,
        101: .fog,
        102: .fog,
        105: .fog,
        103: .thunderstorm,
        104: .thunderstorm,
        114: .thunderstorm,
        115: .thunderstorm,
        116: .thunderstorm,
        117: .thunderstorm,
        118: .thunderstorm,
        119: .thunderstorm,
        106: .rain,
        107: .rain,
        111: .rain,
        113: .rain,
        108: .snow,
        109: .snow,
        110: .snow,
        112: .snow,
      };

      for (final MapEntry(key: code, value: condition) in cases.entries) {
        expect(
          currentWeatherWidgetCondition(code),
          condition,
          reason: 'weather code $code',
        );
      }
    });

    test('returns unknown for invalid or unsupported codes', () {
      for (final code in [0, -1, 420]) {
        expect(
          currentWeatherWidgetCondition(code),
          CurrentWeatherWidgetCondition.unknown,
          reason: 'weather code $code',
        );
      }
    });

    test('phenomenon takes precedence over the weather family', () {
      const cases = <int, CurrentWeatherWidgetCondition>{
        106: .rain,
        214: .thunderstorm,
        305: .fog,
      };

      for (final MapEntry(key: code, value: condition) in cases.entries) {
        expect(
          currentWeatherWidgetCondition(code),
          condition,
          reason: 'weather code $code',
        );
      }
    });
  });

  test('creates a current weather widget snapshot from realtime weather', () {
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
        weather: '多雲時雨',
        weatherCode: 214,
        temperature: 28.4,
        humidity: 76,
        rain: 0.0,
        wind: WeatherWind(direction: '北', speed: 1.5, beaufort: 1),
        gust: WeatherWind(speed: 3.0, beaufort: 2),
      ),
    );

    final snapshot = createCurrentWeatherWidgetSnapshot(
      sourceIdentifier: 'current-location',
      regionCode: '660',
      regionName: '西屯區',
      weather: weather,
      isNight: false,
      nextDayNightTransitionTime: 1_789_562_700,
      calibratedTimeOffsetMilliseconds: -300_000,
    );

    expect(snapshot.schemaVersion, 6);
    expect(snapshot.sourceIdentifier, 'current-location');
    expect(snapshot.regionCode, '660');
    expect(snapshot.regionName, '西屯區');
    expect(snapshot.observationTime, 1789398000);
    expect(snapshot.stationName, '西屯');
    expect(snapshot.weather, '多雲時雨');
    expect(snapshot.weatherCode, 214);
    expect(snapshot.condition, CurrentWeatherWidgetCondition.thunderstorm);
    expect(snapshot.isNight, isFalse);
    expect(snapshot.nextDayNightTransitionTime, 1_789_562_700);
    expect(snapshot.calibratedTimeOffsetMilliseconds, -300_000);
    expect(snapshot.temperature, 28.4);
    expect(snapshot.humidity, 76);
    expect(snapshot.rain, 0.0);
    expect(snapshot.windDirection, '北');
    expect(snapshot.windSpeed, 1.5);

    final json = jsonEncode(snapshot.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['schemaVersion'], 6);
    expect(decoded['sourceIdentifier'], 'current-location');
    expect(decoded['regionCode'], '660');
    expect(decoded['condition'], 'thunderstorm');
    expect(decoded['isNight'], isFalse);
    expect(decoded['nextDayNightTransitionTime'], 1_789_562_700);
    expect(decoded['calibratedTimeOffsetMilliseconds'], -300_000);
    expect(decoded['temperature'], 28.4);
    expect(decoded['windDirection'], '北');
    expect(decoded['windSpeed'], 1.5);
  });

  test('serializes condition name and preserves nullable weather values', () {
    const snapshot = CurrentWeatherWidgetSnapshot(
      sourceIdentifier: 'current-location',
      regionCode: '660',
      regionName: '西屯區',
      observationTime: 1789398000,
      stationName: '西屯',
      weather: '多雲',
      weatherCode: 200,
      condition: .cloudy,
      isNight: true,
      nextDayNightTransitionTime: 1_789_562_700,
      calibratedTimeOffsetMilliseconds: 300_000,
      temperature: null,
      humidity: null,
      rain: null,
      windDirection: null,
      windSpeed: null,
    );

    expect(snapshot.isNight, isTrue);
    expect(snapshot.nextDayNightTransitionTime, 1_789_562_700);

    final json = jsonEncode(snapshot.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded, {
      'schemaVersion': 6,
      'sourceIdentifier': 'current-location',
      'regionCode': '660',
      'regionName': '西屯區',
      'observationTime': 1789398000,
      'stationName': '西屯',
      'weather': '多雲',
      'weatherCode': 200,
      'condition': 'cloudy',
      'isNight': true,
      'nextDayNightTransitionTime': 1_789_562_700,
      'calibratedTimeOffsetMilliseconds': 300_000,
      'temperature': null,
      'humidity': null,
      'rain': null,
      'windDirection': null,
      'windSpeed': null,
    });
  });
}
