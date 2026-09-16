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
    this.schemaVersion = 3,
    required this.regionCode,
    required this.regionName,
    required this.observationTime,
    required this.stationName,
    required this.weather,
    required this.weatherCode,
    required this.condition,
    required this.isNight,
    required this.nextDayNightTransitionTime,
    this.temperature,
    this.humidity,
    this.rain,
  });

  final int schemaVersion;

  final String regionCode;
  final String regionName;

  final int observationTime;

  final String stationName;

  final String weather;
  final int weatherCode;
  final CurrentWeatherWidgetCondition condition;
  final bool isNight;
  final int nextDayNightTransitionTime;

  final double? temperature;
  final int? humidity;
  final double? rain;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'regionCode': regionCode,
      'regionName': regionName,
      'observationTime': observationTime,
      'stationName': stationName,
      'weather': weather,
      'weatherCode': weatherCode,
      'condition': condition.name,
      'isNight': isNight,
      'nextDayNightTransitionTime': nextDayNightTransitionTime,
      'temperature': temperature,
      'humidity': humidity,
      'rain': rain,
    };
  }
}

CurrentWeatherWidgetCondition currentWeatherWidgetCondition(int code) {
  if (code <= 0) {
    return CurrentWeatherWidgetCondition.unknown;
  }

  final suffix = code % 100;

  final phenomenon = switch (suffix) {
    1 || 2 || 5 => CurrentWeatherWidgetCondition.fog,
    3 ||
    4 ||
    14 ||
    15 ||
    16 ||
    17 ||
    18 ||
    19 => CurrentWeatherWidgetCondition.thunderstorm,
    6 || 7 || 11 || 13 => CurrentWeatherWidgetCondition.rain,
    8 || 9 || 10 || 12 => CurrentWeatherWidgetCondition.snow,
    _ => null,
  };

  if (phenomenon != null) {
    return phenomenon;
  }

  return switch (code ~/ 100) {
    1 => CurrentWeatherWidgetCondition.clear,
    2 => CurrentWeatherWidgetCondition.cloudy,
    3 => CurrentWeatherWidgetCondition.overcast,
    _ => CurrentWeatherWidgetCondition.unknown,
  };
}

CurrentWeatherWidgetSnapshot createCurrentWeatherWidgetSnapshot({
  required String regionCode,
  required String regionName,
  required WeatherRealtime weather,
  required bool isNight,
  required int nextDayNightTransitionTime,
}) {
  return CurrentWeatherWidgetSnapshot(
    regionCode: regionCode,
    regionName: regionName,
    observationTime: weather.time,
    stationName: weather.station.name,
    weather: weather.data.weather,
    weatherCode: weather.data.weatherCode,
    condition: currentWeatherWidgetCondition(weather.data.weatherCode),
    isNight: isNight,
    nextDayNightTransitionTime: nextDayNightTransitionTime,
    temperature: weather.data.temperature,
    humidity: weather.data.humidity,
    rain: weather.data.rain,
  );
}
