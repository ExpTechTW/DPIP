import 'package:json_annotation/json_annotation.dart';

part 'weather_precip.g.dart';

@JsonSerializable()
class weatherPrecip {
  /// 降水
  final int precipmm;

  /// 降水
  final int precipin;

  const weatherPrecip({
    required this.precipmm,
    required this.precipin,
  });

  static fromJson(Map<String, dynamic> json) {}
}
