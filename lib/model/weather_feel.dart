import 'package:json_annotation/json_annotation.dart';

part 'weather_feel.g.dart';

@JsonSerializable()
class weatherFeel {
  /// 天氣體感溫度攝氏
  final int c;

  /// 天氣體感溫度華氏
  final int f;

  const weatherFeel({
    required this.c,
    required this.f,
  });

  factory weatherFeel.fromJson(Map<String, dynamic> json) => _$weatherFeelFromJson(json);

  Map<String, dynamic> toJson() => _$weatherFeelToJson(this);
}
