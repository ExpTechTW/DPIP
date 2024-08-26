import "package:json_annotation/json_annotation.dart";
import "package:maplibre_gl/maplibre_gl.dart";

part "station_info.g.dart";

@JsonSerializable()
class StationInfo {
  /// 測站郵遞區號 (地區編號)
  final int code;

  /// 測站經度
  @JsonKey(name: "lon")
  final double longitude;

  /// 測站緯度
  @JsonKey(name: "lat")
  final double latitude;

  /// 測站安裝時間
  final String time;

  StationInfo({required this.code, required this.longitude, required this.latitude, required this.time});

  LatLng get latlng => LatLng(latitude, longitude);

  factory StationInfo.fromJson(dynamic json) => _$StationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StationInfoToJson(this);
}
