import 'package:json_annotation/json_annotation.dart';

part 'weather_air.g.dart';

@JsonSerializable()
class weatherAir {
  /// 空氣一氧化碳
  final double co;

  /// 空氣二氧化氮
  final double no2;

  /// 空氣臭氧
  final double o3;

  /// 空氣pm2.5
  final double pm25;

  /// 空氣pm10
  final double pm10;

  /// 空氣二氧化硫
  final double so2;

  /// 空氣
  final double gbdefraindex;

  /// 空氣
  final double usepaindex;

  const weatherAir({
    required this.co,
    required this.no2,
    required this.o3,
    required this.pm25,
    required this.pm10,
    required this.so2,
    required this.gbdefraindex,
    required this.usepaindex,
  });

  factory weatherAir.fromJson(Map<String, dynamic> json) => _$weatherAirFromJson(json);

  Map<String, dynamic> toJson() => _$weatherAirToJson(this);
}
