import 'package:json_annotation/json_annotation.dart';

import 'package:dpip/utils/parser.dart';

part 'weather_schema.g.dart';

@JsonSerializable()
class RealtimeWeatherStation {
  final String name;
  final String county;
  final String town;
  final double altitude;
  final String lat;
  final String lng;
  final double distance;

  RealtimeWeatherStation({
    required this.name,
    required this.county,
    required this.town,
    required this.altitude,
    required this.lat,
    required this.lng,
    required this.distance,
  });

  factory RealtimeWeatherStation.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherStationFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherStationToJson(this);
}

@JsonSerializable()
class RealtimeWeatherWind {
  final String direction;
  @JsonKey(fromJson: parseDouble)
  final double speed;

  RealtimeWeatherWind({required this.direction, required this.speed});

  factory RealtimeWeatherWind.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherWindFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherWindToJson(this);
}

@JsonSerializable()
class RealtimeWeatherAir {
  @JsonKey(fromJson: parseDouble)
  final double temperature;
  @JsonKey(fromJson: parseDouble)
  final double pressure;
  @JsonKey(fromJson: parseDouble, name: 'relative_humidity')
  final double relativeHumidity;

  RealtimeWeatherAir({required this.temperature, required this.pressure, required this.relativeHumidity});

  factory RealtimeWeatherAir.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherAirFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherAirToJson(this);
}

@JsonSerializable()
class RealtimeWeatherWeatherData {
  final String weather;
  final RealtimeWeatherWind wind;
  final RealtimeWeatherAir air;
  final int weatherCode;

  RealtimeWeatherWeatherData({required this.weather, required this.wind, required this.air, required this.weatherCode});

  factory RealtimeWeatherWeatherData.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherWeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherWeatherDataToJson(this);
}

@JsonSerializable()
class RealtimeWeatherTemperatureData {
  @JsonKey(fromJson: parseDouble)
  final double temperature;
  final int time;

  RealtimeWeatherTemperatureData({required this.temperature, required this.time});

  factory RealtimeWeatherTemperatureData.fromJson(Map<String, dynamic> json) =>
      _$RealtimeWeatherTemperatureDataFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherTemperatureDataToJson(this);
}

@JsonSerializable()
class RealtimeWeatherDaily {
  final RealtimeWeatherTemperatureData high;
  final RealtimeWeatherTemperatureData low;

  RealtimeWeatherDaily({required this.high, required this.low});

  factory RealtimeWeatherDaily.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherDailyFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherDailyToJson(this);
}

@JsonSerializable()
class RealtimeWeatherWeather {
  final String id;
  final RealtimeWeatherStation station;
  final RealtimeWeatherWeatherData data;
  final RealtimeWeatherDaily daily;

  RealtimeWeatherWeather({required this.id, required this.station, required this.data, required this.daily});

  factory RealtimeWeatherWeather.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherWeatherFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherWeatherToJson(this);
}

@JsonSerializable()
class RealtimeWeatherRainData {
  final String now;
  @JsonKey(name: '10m')
  final String tenMinutes;
  @JsonKey(name: '1h')
  final String oneHour;
  @JsonKey(name: '3h')
  final String threeHours;
  @JsonKey(name: '6h')
  final String sixHours;
  @JsonKey(name: '12h')
  final String twelveHours;
  @JsonKey(name: '24h')
  final String twentyFourHours;
  @JsonKey(name: '2d')
  final String twoDays;
  @JsonKey(name: '3d')
  final String threeDays;

  RealtimeWeatherRainData({
    required this.now,
    required this.tenMinutes,
    required this.oneHour,
    required this.threeHours,
    required this.sixHours,
    required this.twelveHours,
    required this.twentyFourHours,
    required this.twoDays,
    required this.threeDays,
  });

  factory RealtimeWeatherRainData.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherRainDataFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherRainDataToJson(this);
}

@JsonSerializable()
class RealtimeWeatherRain {
  final String id;
  final RealtimeWeatherStation station;
  final RealtimeWeatherRainData data;

  RealtimeWeatherRain({required this.id, required this.station, required this.data});

  factory RealtimeWeatherRain.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherRainFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherRainToJson(this);
}

@JsonSerializable()
class RealtimeWeather {
  final RealtimeWeatherWeather weather;
  final RealtimeWeatherRain rain;

  RealtimeWeather({required this.weather, required this.rain});

  factory RealtimeWeather.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherToJson(this);
}
