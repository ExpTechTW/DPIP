import 'package:json_annotation/json_annotation.dart';

part 'weather_vis.g.dart';

@JsonSerializable()
class WeatherVisibility {
  /// 能見度公里
  final double km;

  /// 能見度英里
  final double miles;

  const WeatherVisibility({
    required this.km,
    required this.miles,
  });

  factory WeatherVisibility.fromJson(Map<String, dynamic> json) => _$WeatherVisibilityFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherVisibilityToJson(this);
}
