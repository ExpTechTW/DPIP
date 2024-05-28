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
class weatherRealtime {
  /// 天氣更新時間
  final int update;

  /// 天氣溫度
  final weatherTemp temp;

  /// 天氣狀態
  final int condition;

  /// 天氣溫度
  final weatherWind wind;

  /// 大氣壓力
  final weatherPressure pressure;

  /// 降水
  final weatherPrecip precip;

  /// 天氣相對溼度
  final int humidity;

  /// 天氣體感溫度
  final weatherFeel feel;

  /// 天氣體感溫度
  final weatherVis vis;

  /// 天氣紫外線
  final int uv;

  /// 陣風
  final weatherGust gust;

  /// 天氣
  final int cloud;

  /// 天氣
  final int isday;

  /// 空氣
  final weatherAir air;

  const weatherRealtime({
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
    required this.isday,
    required this.air,
  });

  factory weatherRealtime.fromJson(Map<String, dynamic> json) => _$weatherRealtimeFromJson(json);

  Map<String, dynamic> toJson() => _$weatherRealtimeToJson(this);
}
