import "package:dpip/model/rts/rts_intensity.dart";
import "package:dpip/model/rts/rts_station.dart";
import "package:json_annotation/json_annotation.dart";

part "rts.g.dart";

@JsonSerializable()
class Rts {
  /// 測站地動資料
  final Map<String, RtsStation> station;

  /// 地動區塊
  final Map<String, int> box;

  ///資料時間
  final int time;

  /// 震度列表
  @JsonKey(name: "int")
  final List<RtsIntensity> intensity;

  Rts({required this.station, required this.box, required this.time, required this.intensity});

  factory Rts.fromJson(dynamic json) => _$RtsFromJson(json);

  Map<String, dynamic> toJson() => _$RtsToJson(this);
}
