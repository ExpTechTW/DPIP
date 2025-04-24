import "package:json_annotation/json_annotation.dart";
import "package:maplibre_gl/maplibre_gl.dart";

part "eew_info.g.dart";

@JsonSerializable()
class EewInfo {
  /// 地震速報時間
  final int time;

  /// 地震震央預估經度
  @JsonKey(name: "lon")
  final double longitude;

  /// 地震震央預估緯度
  @JsonKey(name: "lat")
  final double latitude;

  /// 地震預估深度
  final double depth;

  /// 地震預估芮氏規模
  @JsonKey(name: "mag")
  final double magnitude;

  /// 地震預估位置
  @JsonKey(name: "loc")
  final String location;

  /// 地震預估最大震度
  final int max;

  const EewInfo({
    required this.time,
    required this.longitude,
    required this.latitude,
    required this.depth,
    required this.magnitude,
    required this.location,
    required this.max,
  });

  LatLng get latlng => LatLng(latitude, longitude);

  factory EewInfo.fromJson(Map<String, dynamic> json) => _$EewInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EewInfoToJson(this);
}
