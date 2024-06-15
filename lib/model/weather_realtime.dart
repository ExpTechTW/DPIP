// ignore_for_file: non_constant_identifier_names

import 'package:dpip/model/weather_air.dart';
import 'package:dpip/model/weather_feel.dart';
import 'package:dpip/model/weather_gust.dart';
import 'package:dpip/model/weather_precip.dart';
import 'package:dpip/model/weather_pressure.dart';
import 'package:dpip/model/weather_temp.dart';
import 'package:dpip/model/weather_vis.dart';
import 'package:dpip/model/weather_wind.dart';
import 'package:json_annotation/json_annotation.dart';

part 'weather_realtime.g.dart';

@JsonSerializable()
class WeatherRealtime {
  /// 天氣更新時間
  final double update;

  /// 天氣溫度
  final WeatherTemp temp;

  /// 天氣狀態
  final double condition;

  /// 天氣溫度
  final WeatherWind wind;

  /// 大氣壓力
  final WeatherPressure pressure;

  /// 降水
  final WeatherPrecip precip;

  /// 天氣相對溼度
  final double humidity;

  /// 天氣體感溫度
  final WeatherFeel feel;

  /// 能見度
  final WeatherVisibility vis;

  /// 天氣紫外線
  final double uv;

  /// 陣風
  final WeatherGust gust;

  /// 天氣
  final double cloud;

  /// 天氣
  @JsonKey(name: 'is_day')
  final double isDay;

  /// 空氣
  final WeatherAir air;

  const WeatherRealtime({
    required this.update,
    required this.temp,
    required this.condition,
    required this.wind,
    required this.pressure,
    required this.precip,
    required this.humidity,
    required this.feel,
    required this.vis,
    required this.uv,
    required this.gust,
    required this.cloud,
    required this.isDay,
    required this.air,
  });

  factory WeatherRealtime.fromJson(Map<String, dynamic> json) => _$WeatherRealtimeFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherRealtimeToJson(this);
}
