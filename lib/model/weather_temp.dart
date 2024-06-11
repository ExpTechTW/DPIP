import 'package:json_annotation/json_annotation.dart';

part 'weather_temp.g.dart';

@JsonSerializable()
class WeatherTemp {
  /// 天氣溫度攝氏
  final double c;

  /// 天氣溫度華氏
  final double f;

  const WeatherTemp({
    required this.c,
    required this.f,
  });

  factory WeatherTemp.fromJson(Map<String, dynamic> json) => _$weatherTempFromJson(json);

  Map<String, dynamic> toJson() => _$weatherTempToJson(this);
}
