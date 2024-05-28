import 'package:json_annotation/json_annotation.dart';

part 'weather_wind.g.dart';

@JsonSerializable()
class weatherWind {
  /// mph
  final double mph;

  /// kph
  final double kph;

  /// 度數
  final double degree;

  /// 風向
  final String dir;

  const weatherWind({
    required this.mph,
    required this.kph,
    required this.degree,
    required this.dir,
  });

  factory weatherWind.fromJson(Map<String, dynamic> json) => _$weatherWindFromJson(json);

  Map<String, dynamic> toJson() => _$weatherWindToJson(this);
}
