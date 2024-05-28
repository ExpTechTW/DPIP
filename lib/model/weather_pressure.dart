import 'package:json_annotation/json_annotation.dart';

part 'weather_pressure.g.dart';

@JsonSerializable()
class weatherPressure {
  /// 大氣壓力
  final double pressuremb;

  /// 大氣壓力
  final double pressurein;

  const weatherPressure({
    required this.pressuremb,
    required this.pressurein,
  });

  factory weatherPressure.fromJson(Map<String, dynamic> json) => _$weatherPressureFromJson(json);

  Map<String, dynamic> toJson() => _$weatherPressureToJson(this);
}
