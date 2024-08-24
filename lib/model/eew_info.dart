import "package:json_annotation/json_annotation.dart";

part "eew_info.g.dart";

@JsonSerializable()
class EewInfo {
  /// 地震速報時間
  final int time;

  /// 地震震央預估經度
  final double lon;

  /// 地震震央預估緯度
  final double lat;

  /// 地震預估深度
  final double depth;

  /// 地震預估芮氏規模
  final double mag;

  /// 地震預估位置
  final String loc;

  /// 地震預估最大震度
  final int max;

  const EewInfo({
    required this.time,
    required this.lon,
    required this.lat,
    required this.depth,
    required this.mag,
    required this.loc,
    required this.max,
  });

  factory EewInfo.fromJson(Map<String, dynamic> json) => _$EewInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EewInfoToJson(this);
}
