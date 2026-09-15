import 'package:dpip/features/weather/domain/weather_realtime.dart';

final class CurrentWeatherWidgetSnapshot {
  const CurrentWeatherWidgetSnapshot({
    this.schemaVersion = 1,
    required this.regionCode,
    required this.regionName,
    required this.observationTime,
    required this.stationName,
    required this.weather,
    required this.weatherCode,
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
      'temperature': temperature,
      'humidity': humidity,
      'rain': rain,
    };
  }
}

CurrentWeatherWidgetSnapshot createCurrentWeatherWidgetSnapshot({
  required String regionCode,
  required String regionName,
  required WeatherRealtime weather,
}) {
  return CurrentWeatherWidgetSnapshot(
    regionCode: regionCode,
    regionName: regionName,
    observationTime: weather.time,
    stationName: weather.station.name,
    weather: weather.data.weather,
    weatherCode: weather.data.weatherCode,
    temperature: weather.data.temperature,
    humidity: weather.data.humidity,
    rain: weather.data.rain,
  );
}
