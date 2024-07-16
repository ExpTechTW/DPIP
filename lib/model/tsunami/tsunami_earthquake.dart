import 'package:json_annotation/json_annotation.dart';

part 'tsunami_earthquake.g.dart';

@JsonSerializable()
class TsunamiEarthquake {
  /// - 地震發生時間
  ///
  /// 範例
  /// ```
  /// "1712102280000"
  /// ```
  final int time;

  /// - 震央經度
  ///
  /// 範例
  /// ```
  /// 121.67
  /// ```
  final double lon;

  /// - 震央緯度
  ///
  /// 範例：
  /// ```
  /// 23.77
  /// ```
  final double lat;

  /// - 震源深度
  ///
  /// 範例：
  /// ```
  /// 15.5
  /// ```
  final double depth;

  /// - 地震規模
  ///
  /// 範例
  /// ```
  /// 7.3
  /// ```
  final double mag;

  /// - 地震位置描述
  ///
  /// 範例
  /// ```
  /// "花蓮縣中部外海"
  /// ```
  final String loc;

  /// - 地震資訊發布單位
  ///
  /// 範例
  /// ```
  /// "cwa"
  /// ```
  final String author;

  TsunamiEarthquake({
    required this.time,
    required this.lon,
    required this.lat,
    required this.depth,
    required this.mag,
    required this.loc,
    required this.author,
  });

  factory TsunamiEarthquake.fromJson(Map<String, dynamic> json) => _$TsunamiEarthquakeFromJson(json);

  Map<String, dynamic> toJson() => _$TsunamiEarthquakeToJson(this);
}
