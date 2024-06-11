// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'weather_pressure.g.dart';

@JsonSerializable()
class WeatherPressure {
  /// 大氣壓力
  final double mb;

  /// 大氣壓力
  @JsonKey(name: 'in')
  final double pressurein;

  const WeatherPressure({
    required this.mb,
    required this.pressurein,
  });

  factory WeatherPressure.fromJson(Map<String, dynamic> json) => _$WeatherPressureFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherPressureToJson(this);
}
