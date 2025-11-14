import 'package:dpip/utils/parser.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weather_schema.g.dart';

@JsonSerializable()
class RealtimeWeatherStation {
  final String name;
  final String county;
  final String town;
  final double altitude;
  final double lat;
  final double lng;
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
  final double direction;
  final double speed;

  RealtimeWeatherWind({required this.direction, required this.speed});

  factory RealtimeWeatherWind.fromJson(Map<String, dynamic> json) => _$RealtimeWeatherWindFromJson(json);
  Map<String, dynamic> toJson() => _$RealtimeWeatherWindToJson(this);
}

@JsonSerializable()
class RealtimeWeatherAir {
  final double temperature;
  final double pressure;
  @JsonKey(name: 'relative_humidity')
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
  @JsonKey(fromJson: parseDouble)
  final double now;
  @JsonKey(name: '10m', fromJson: parseDouble)
  final double tenMinutes;
  @JsonKey(name: '1h', fromJson: parseDouble)
  final double oneHour;
  @JsonKey(name: '3h', fromJson: parseDouble)
  final double threeHours;
  @JsonKey(name: '6h', fromJson: parseDouble)
  final double sixHours;
  @JsonKey(name: '12h', fromJson: parseDouble)
  final double twelveHours;
  @JsonKey(name: '24h', fromJson: parseDouble)
  final double twentyFourHours;
  @JsonKey(name: '2d', fromJson: parseDouble)
  final double twoDays;
  @JsonKey(name: '3d', fromJson: parseDouble)
  final double threeDays;

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
