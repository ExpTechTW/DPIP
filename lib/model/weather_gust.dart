import 'package:json_annotation/json_annotation.dart';

part 'weather_gust.g.dart';

@JsonSerializable()
class WeatherGust {
  /// 陣風
  final double mph;

  /// 陣風
  final double kph;

  const WeatherGust({
    required this.mph,
    required this.kph,
  });

  factory WeatherGust.fromJson(Map<String, dynamic> json) => _$weatherGustFromJson(json);

  Map<String, dynamic> toJson() => _$weatherGustToJson(this);
}
