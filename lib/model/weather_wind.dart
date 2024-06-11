import 'package:json_annotation/json_annotation.dart';

part 'weather_wind.g.dart';

@JsonSerializable()
class WeatherWind {
  /// mph
  final double mph;

  /// kph
  final double kph;

  /// 度數
  final double degree;

  /// 風向
  @JsonKey(name: 'dir')
  final String direction;

  const WeatherWind({
    required this.mph,
    required this.kph,
    required this.degree,
    required this.direction,
  });

  factory WeatherWind.fromJson(Map<String, dynamic> json) => _$weatherWindFromJson(json);

  Map<String, dynamic> toJson() => _$weatherWindToJson(this);
}
