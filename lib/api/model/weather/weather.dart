import 'package:json_annotation/json_annotation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/utils/geojson.dart';

part 'weather.g.dart';

@JsonSerializable()
class WeatherStation {
  String get type => 'weather_station';

  final String id;

  final StationInfo station;

  final WeatherData data;

  final DailyTemperature daily;

  const WeatherStation({required this.id, required this.station, required this.data, required this.daily});

  factory WeatherStation.fromJson(Map<String, dynamic> json) => _$WeatherStationFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherStationToJson(this);

  GeoJsonFeatureBuilder toFeatureBuilder() {
    return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        .setGeometry(station.latlng.toGeoJsonCoordinates())
        .setProperty('id', id)
        .setProperty('name', station.name)
        .setProperty('county', station.county)
        .setProperty('town', station.town)
        .setProperty('temperature', data.air.temperature)
        .setProperty('relative_humidity', data.air.relativeHumidity)
        .setProperty('wind_direction', data.wind.direction)
        .setProperty('wind_speed', data.wind.speed)
        .setProperty('icon', windIcon(data.wind.speed));
  }
  String windIcon(double speed) {
    if (speed < 3.4) return 'wind-1';
    if (speed < 8.0) return 'wind-2';
    if (speed < 13.9) return 'wind-3';
    if (speed < 32.7) return 'wind-4';
    return 'wind-5';
  }
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

  LatLng get latlng => LatLng(lat, lng);
}

@JsonSerializable()
class WeatherData {
  final String weather;
  final Wind wind;
  final AirCondition air;

  const WeatherData({required this.weather, required this.wind, required this.air});

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);
}

@JsonSerializable()
class Wind {
  final int direction;
  final double speed;

  const Wind({required this.direction, required this.speed});

  factory Wind.fromJson(Map<String, dynamic> json) => _$WindFromJson(json);

  Map<String, dynamic> toJson() => _$WindToJson(this);
}

@JsonSerializable()
class AirCondition {
  final double temperature;
  final double pressure;
  @JsonKey(name: 'relative_humidity')
  final int relativeHumidity;

  const AirCondition({required this.temperature, required this.pressure, required this.relativeHumidity});

  factory AirCondition.fromJson(Map<String, dynamic> json) => _$AirConditionFromJson(json);

  Map<String, dynamic> toJson() => _$AirConditionToJson(this);
}

@JsonSerializable()
class DailyTemperature {
  final TemperatureRecord high;
  final TemperatureRecord low;

  const DailyTemperature({required this.high, required this.low});

  factory DailyTemperature.fromJson(Map<String, dynamic> json) => _$DailyTemperatureFromJson(json);

  Map<String, dynamic> toJson() => _$DailyTemperatureToJson(this);
}

@JsonSerializable()
class TemperatureRecord {
  final double temperature;
  final int time;

  const TemperatureRecord({required this.temperature, required this.time});

  factory TemperatureRecord.fromJson(Map<String, dynamic> json) => _$TemperatureRecordFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureRecordToJson(this);
}
