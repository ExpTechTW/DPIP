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

  factory weatherTemp.fromJson(Map<String, dynamic> json) => _$weatherTempFromJson(json);

  Map<String, dynamic> toJson() => _$weatherTempToJson(this);
}
