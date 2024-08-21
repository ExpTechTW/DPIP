import 'package:json_annotation/json_annotation.dart';

part 'rain.g.dart';

@JsonSerializable()
class RainStation {
  final String type = "rain_station";

  final String id;

  final StationInfo station;

  final RainData data;

  const RainStation({
    required this.id,
    required this.station,
    required this.data,
  });

  factory RainStation.fromJson(Map<String, dynamic> json) => _$RainStationFromJson(json);

  Map<String, dynamic> toJson() => _$RainStationToJson(this);
}

@JsonSerializable()
class StationInfo {
  final String name;
  final String county;
  final String town;
  final double altitude;
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
class RainData {
  @JsonKey(name: 'now', defaultValue: 0.0)
  final double now;
  @JsonKey(name: '10m', defaultValue: 0.0)
  final double tenMinutes;
  @JsonKey(name: '1h', defaultValue: 0.0)
  final double oneHour;
  @JsonKey(name: '3h', defaultValue: 0.0)
  final double threeHours;
  @JsonKey(name: '6h', defaultValue: 0.0)
  final double sixHours;
  @JsonKey(name: '12h', defaultValue: 0.0)
  final double twelveHours;
  @JsonKey(name: '24h', defaultValue: 0.0)
  final double twentyFourHours;
  @JsonKey(name: '2d', defaultValue: 0.0)
  final double twoDays;
  @JsonKey(name: '3d', defaultValue: 0.0)
  final double threeDays;

  const RainData({
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

  factory RainData.fromJson(Map<String, dynamic> json) => _$RainDataFromJson(json);

  Map<String, dynamic> toJson() => _$RainDataToJson(this);
}
