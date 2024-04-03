import 'package:json_annotation/json_annotation.dart';

part 'station_intensity.g.dart';

@JsonSerializable()
class StationIntensity {
  /// 測站經度
  final double lon;

  /// 測站緯度
  final double lat;

  /// 測站最大觀測震度
  @JsonKey(name: "int")
  final int intensity;

  StationIntensity(
      {required this.lon, required this.lat, required this.intensity});

  factory StationIntensity.fromJson(Map<String, dynamic> json) =>
      _$StationIntensityFromJson(json);

  Map<String, dynamic> toJson() => _$StationIntensityToJson(this);
}
