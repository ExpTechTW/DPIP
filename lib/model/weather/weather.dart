import "package:json_annotation/json_annotation.dart";

part "weather.g.dart";

@JsonSerializable()
class WeatherStation {
  final String type = "weather_station";

  final String id;

  final StationInfo station;

  final WeatherData data;

  final DailyTemperature daily;

  const WeatherStation({
    required this.id,
    required this.station,
    required this.data,
    required this.daily,
  });

  factory WeatherStation.fromJson(Map<String, dynamic> json) => _$WeatherStationFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherStationToJson(this);
}

@JsonSerializable()
class StationInfo {
  final String name;
  final String county;
  final String town;
  final int altitude;
  final double lat;
  final double lng;

  const StationInfo({
    required this.name,
    required this.county,
    required this.town,
    required this.altitude,
    required this.lat,
    required this.lng,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) => _$StationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StationInfoToJson(this);
}

@JsonSerializable()
class WeatherData {
  final String weather;
  final Wind wind;
  final AirCondition air;

  const WeatherData({
    required this.weather,
    required this.wind,
    required this.air,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);
}

@JsonSerializable()
class Wind {
  final int direction;
  final double speed;

  const Wind({
    required this.direction,
    required this.speed,
  });

  factory Wind.fromJson(Map<String, dynamic> json) => _$WindFromJson(json);

  Map<String, dynamic> toJson() => _$WindToJson(this);
}

@JsonSerializable()
class AirCondition {
  final double temperature;
  final double pressure;
  final int relative_humidity;

  const AirCondition({
    required this.temperature,
    required this.pressure,
    required this.relative_humidity,
  });

  factory AirCondition.fromJson(Map<String, dynamic> json) => _$AirConditionFromJson(json);

  Map<String, dynamic> toJson() => _$AirConditionToJson(this);
}

@JsonSerializable()
class DailyTemperature {
  final TemperatureRecord high;
  final TemperatureRecord low;

  const DailyTemperature({
    required this.high,
    required this.low,
  });

  factory DailyTemperature.fromJson(Map<String, dynamic> json) => _$DailyTemperatureFromJson(json);

  Map<String, dynamic> toJson() => _$DailyTemperatureToJson(this);
}

@JsonSerializable()
class TemperatureRecord {
  final double temperature;
  final int time;

  const TemperatureRecord({
    required this.temperature,
    required this.time,
  });

  factory TemperatureRecord.fromJson(Map<String, dynamic> json) => _$TemperatureRecordFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureRecordToJson(this);
}
