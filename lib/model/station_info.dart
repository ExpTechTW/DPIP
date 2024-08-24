import "package:json_annotation/json_annotation.dart";

part "station_info.g.dart";

@JsonSerializable()
class StationInfo {
  /// 測站郵遞區號 (地區編號)
  final int code;

  /// 測站經度
  final double lon;

  /// 測站緯度
  final double lat;

  /// 測站安裝時間
  final String time;

  StationInfo({required this.code, required this.lon, required this.lat, required this.time});

  factory StationInfo.fromJson(dynamic json) => _$StationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StationInfoToJson(this);
}
