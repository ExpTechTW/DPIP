import 'package:dpip/core/weather/weather_code.dart';
import 'package:dpip/features/weather/domain/apparent_temperature.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';

enum CurrentWeatherWidgetCondition {
  clear,
  cloudy,
  overcast,
  rain,
  thunderstorm,
  snow,
  fog,
  unknown,
}

final class CurrentWeatherWidgetSnapshot {
  const CurrentWeatherWidgetSnapshot({
    this.schemaVersion = 7,
    required this.sourceIdentifier,
    required this.regionCode,
    required this.regionName,
    required this.observationTime,
    required this.stationName,
    required this.weather,
    required this.weatherCode,
    required this.condition,
    required this.isNight,
    required this.nextDayNightTransitionTime,
    required this.calibratedTimeOffsetMilliseconds,
    this.temperature,
    this.humidity,
    this.rain,
    this.windDirection,
    this.windSpeed,
    this.apparentTemperature,
  });

  final int schemaVersion;

  final String sourceIdentifier;

  final String regionCode;
  final String regionName;

  final int observationTime;

  final String stationName;

  final String weather;
  final int weatherCode;
  final CurrentWeatherWidgetCondition condition;
  final bool isNight;

  /// The next solar transition known when this snapshot was written.
  ///
  /// This is intentionally one transition, not an indefinite solar schedule.
  final int nextDayNightTransitionTime;

  /// Calibrated/server time minus device time, in milliseconds.
  ///
  /// Swift adds this value to a device-clock `Date` to reconstruct calibrated
  /// time, and subtracts it from calibrated deadlines for WidgetKit scheduling.
  final int calibratedTimeOffsetMilliseconds;

  final double? temperature;
  final int? humidity;
  final double? rain;
  final String? windDirection;
  final double? windSpeed;
  final double? apparentTemperature;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'sourceIdentifier': sourceIdentifier,
      'regionCode': regionCode,
      'regionName': regionName,
      'observationTime': observationTime,
      'stationName': stationName,
      'weather': weather,
      'weatherCode': weatherCode,
      'condition': condition.name,
      'isNight': isNight,
      'nextDayNightTransitionTime': nextDayNightTransitionTime,
      'calibratedTimeOffsetMilliseconds': calibratedTimeOffsetMilliseconds,
      'temperature': temperature,
      'humidity': humidity,
      'rain': rain,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'apparentTemperature': apparentTemperature,
    };
  }
}

CurrentWeatherWidgetCondition currentWeatherWidgetCondition(int code) {
  return switch (weatherConditionForCode(code)) {
    WeatherCondition.clear => CurrentWeatherWidgetCondition.clear,
    WeatherCondition.cloudy => CurrentWeatherWidgetCondition.cloudy,
    WeatherCondition.overcast => CurrentWeatherWidgetCondition.overcast,
    WeatherCondition.rain => CurrentWeatherWidgetCondition.rain,
    WeatherCondition.thunderstorm => CurrentWeatherWidgetCondition.thunderstorm,
    WeatherCondition.snow => CurrentWeatherWidgetCondition.snow,
    WeatherCondition.fog => CurrentWeatherWidgetCondition.fog,
    WeatherCondition.unknown => CurrentWeatherWidgetCondition.unknown,
  };
}

CurrentWeatherWidgetSnapshot createCurrentWeatherWidgetSnapshot({
  required String sourceIdentifier,
  required String regionCode,
  required String regionName,
  required WeatherRealtime weather,
  required bool isNight,
  required int nextDayNightTransitionTime,
  required int calibratedTimeOffsetMilliseconds,
}) {
  return CurrentWeatherWidgetSnapshot(
    sourceIdentifier: sourceIdentifier,
    regionCode: regionCode,
    regionName: regionName,
    observationTime: weather.time,
    stationName: weather.station.name,
    weather: weather.data.weather,
    weatherCode: weather.data.weatherCode,
    condition: currentWeatherWidgetCondition(weather.data.weatherCode),
    isNight: isNight,
    nextDayNightTransitionTime: nextDayNightTransitionTime,
    calibratedTimeOffsetMilliseconds: calibratedTimeOffsetMilliseconds,
    temperature: weather.data.temperature,
    humidity: weather.data.humidity,
    rain: weather.data.rain,
    windDirection: weather.data.wind.direction,
    windSpeed: weather.data.wind.speed,
    apparentTemperature: currentApparentTemperature(
      temperature: weather.data.temperature,
      humidity: weather.data.humidity,
      windSpeed: weather.data.wind.speed,
    ),
  );
}
