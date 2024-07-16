import 'package:json_annotation/json_annotation.dart';

part 'tsunami_actual.g.dart';

@JsonSerializable()
class TsunamiActual {
  /// - 海嘯實測地區
  ///
  /// 範例
  /// ```
  /// "花蓮"
  /// ```
  final String name;

  /// - 海嘯實測地區編碼
  ///
  /// 範例
  /// ```
  /// "HL"
  /// ```
  final String id;

  /// - 海嘯實測地區緯度
  ///
  /// 範例
  /// ```
  /// 23.98
  /// ```
  final double lat;

  /// - 海嘯實測地區經度
  ///
  /// 範例
  /// ```
  /// 121.62
  /// ```
  final double lon;

  /// - 海嘯實測高度
  ///
  /// 範例
  /// ```
  /// 27
  /// ```
  @JsonKey(name: "wave_height")
  final int waveHeight;

  /// - 海嘯實際抵達時間
  ///
  /// 範例
  /// ```
  /// 1712104200000
  /// ```
  @JsonKey(name: "arrival_time")
  final int arrivalTime;

  TsunamiActual({
    required this.name,
    required this.id,
    required this.lat,
    required this.lon,
    required this.waveHeight,
    required this.arrivalTime,
  });

  factory TsunamiActual.fromJson(Map<String, dynamic> json) => _$TsunamiActualFromJson(json);

  Map<String, dynamic> toJson() => _$TsunamiActualToJson(this);
}
