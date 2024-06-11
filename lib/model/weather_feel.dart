import 'package:json_annotation/json_annotation.dart';

part 'weather_feel.g.dart';

@JsonSerializable()
class WeatherFeel {
  /// 天氣體感溫度攝氏
  final double c;

  /// 天氣體感溫度華氏
  final double f;

  const WeatherFeel({
    required this.c,
    required this.f,
  });

  factory WeatherFeel.fromJson(Map<String, dynamic> json) => _$WeatherFeelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherFeelToJson(this);
}
