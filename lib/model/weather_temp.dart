import 'package:json_annotation/json_annotation.dart';

part 'weather_temp.g.dart';

@JsonSerializable()
class weatherTemp {
  /// 天氣溫度攝氏
  final int c;

  /// 天氣溫度華氏
  final int f;

  const weatherTemp({
    required this.c,
    required this.f,
  });

  static fromJson(Map<String, dynamic> json) {}
}
