import "package:json_annotation/json_annotation.dart";

part "rts_intensity.g.dart";

@JsonSerializable()
class RtsIntensity {
  /// 郵遞區號
  final int code;

  /// 震度
  final int i;

  RtsIntensity({required this.code, required this.i});

  factory RtsIntensity.fromJson(dynamic json) => _$RtsIntensityFromJson(json);

  Map<String, dynamic> toJson() => _$RtsIntensityToJson(this);
}
