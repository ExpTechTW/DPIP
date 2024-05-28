// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'weather_precip.g.dart';

@JsonSerializable()
class weatherPrecip {
  /// 降水
  final double mm;

  /// 降水
  @JsonKey(name: 'in')
  final double precipin;

  const weatherPrecip({
    required this.mm,
    required this.precipin,
  });

  factory weatherPrecip.fromJson(Map<String, dynamic> json) => _$weatherPrecipFromJson(json);

  Map<String, dynamic> toJson() => _$weatherPrecipToJson(this);
}
