import 'package:json_annotation/json_annotation.dart';

part 'weather_pressure.g.dart';

@JsonSerializable()
class weatherPressure {
  /// 大氣壓力
  final int pressuremb;

  /// 大氣壓力
  final int pressurein;

  const weatherPressure({
    required this.pressuremb,
    required this.pressurein,
  });

  static fromJson(Map<String, dynamic> json) {}
}
