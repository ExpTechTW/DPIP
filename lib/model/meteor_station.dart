import 'package:json_annotation/json_annotation.dart';

part 'meteor_station.g.dart';

@JsonSerializable()
class MeteorStation {
  @JsonKey(name: 'station')
  final MeteorStationInfo station;

  @JsonKey(name: 'time')
  final List<String> time;

  @JsonKey(name: 'temperature')
  final List<double> temperature;

  @JsonKey(name: 'wind_speed')
  final List<double> windSpeed;

  @JsonKey(name: 'precipitation')
  final List<double> precipitation;

  @JsonKey(name: 'humidity')
  final List<double> humidity;

  @JsonKey(name: 'pressure')
  final List<double> pressure;

  @JsonKey(name: 'wind_direction')
  final List<double> windDirection;

  MeteorStation({
    required this.station,
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.precipitation,
    required this.humidity,
    required this.pressure,
    required this.windDirection,
  });

  factory MeteorStation.fromJson(Map<String, dynamic> json) => _$MeteorStationFromJson(json);
  Map<String, dynamic> toJson() => _$MeteorStationToJson(this);
}

@JsonSerializable()
class MeteorStationInfo {
  final String name;
  final String county;
  final String town;
  final int altitude;
  final double lat;
  final double lng;

  MeteorStationInfo({
    required this.name,
    required this.county,
    required this.town,
    required this.altitude,
    required this.lat,
    required this.lng,
  });

  factory MeteorStationInfo.fromJson(Map<String, dynamic> json) => _$MeteorStationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$MeteorStationInfoToJson(this);
}
