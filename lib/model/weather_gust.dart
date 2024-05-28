import 'package:json_annotation/json_annotation.dart';

part 'weather_gust.g.dart';

@JsonSerializable()
class weatherGust {
  /// 陣風
  final int mph;

  /// 陣風
  final int kph;

  const weatherGust({
    required this.mph,
    required this.kph,
  });

  factory weatherGust.fromJson(Map<String, dynamic> json) => _$weatherGustFromJson(json);

  Map<String, dynamic> toJson() => _$weatherGustToJson(this);
}
