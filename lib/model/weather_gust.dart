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

  static fromJson(Map<String, dynamic> json) {}
}
