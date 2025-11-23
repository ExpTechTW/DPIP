import 'package:dpip/utils/serialization.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weather_schema.g.dart';

@JsonSerializable()
class RealtimeWeatherStation {
  final String name;
  final double lat;
  final double lon;
  final double altitude;
  final double distance;

  RealtimeWeatherStation({
    required this.name,
    required this.lat,
    required this.lon,
    required this.altitude,
    required this.distance,
  });

  factory RealtimeWeatherStation.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherStationFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherStationToJson(this);
}

@JsonSerializable()
class RealtimeWeatherWind {
  final String direction;
  final double speed;
  final int beaufort;

  RealtimeWeatherWind({required this.direction, required this.speed, required this.beaufort});

  factory RealtimeWeatherWind.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherWindFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherWindToJson(this);
}

@JsonSerializable()
class RealtimeWeatherGust {
  final double speed;
  final int beaufort;

  RealtimeWeatherGust({required this.speed, required this.beaufort});

  factory RealtimeWeatherGust.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherGustFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherGustToJson(this);
}

@JsonSerializable()
class RealtimeWeatherData {
  final String weather;
  final int weatherCode;
  final double temperature;
  final double humidity;
  final double rain;
  final RealtimeWeatherWind wind;
  final RealtimeWeatherGust gust;
  final double visibility;
  final double pressure;
  final double sunshine;

  RealtimeWeatherData({
    required this.weather,
    required this.weatherCode,
    required this.temperature,
    required this.humidity,
    required this.rain,
    required this.wind,
    required this.gust,
    required this.visibility,
    required this.pressure,
    required this.sunshine,
  });

  factory RealtimeWeatherData.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherDataToJson(this);
}

@JsonSerializable()
class RealtimeWeather {
  final String id;
  final RealtimeWeatherStation station;
  final int time;
  final RealtimeWeatherData data;

  RealtimeWeather({
    required this.id,
    required this.station,
    required this.time,
    required this.data,
  });

  factory RealtimeWeather.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherToJson(this);
}
