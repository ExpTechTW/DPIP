import 'package:json_annotation/json_annotation.dart';

part 'weather_precip.g.dart';

@JsonSerializable()
class weatherPrecip {
  /// 降水
  final double precipmm;

  /// 降水
  final double precipin;

  const weatherPrecip({
    required this.precipmm,
    required this.precipin,
  });

  factory weatherPrecip.fromJson(Map<String, dynamic> json) => _$weatherPrecipFromJson(json);

  Map<String, dynamic> toJson() => _$weatherPrecipToJson(this);
}
