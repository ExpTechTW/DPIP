import "package:json_annotation/json_annotation.dart";

part "tsunami_estimate.g.dart";

@JsonSerializable()
class TsunamiEstimate {
  /// - 海嘯預警地區
  ///
  /// 範例
  /// ```
  /// "東部沿海地區"
  /// ```
  final String area;

  /// - 海嘯預估抵達時間
  ///
  /// 範例
  /// ```
  /// 1712102340000
  /// ```
  @JsonKey(name: "arrival_time")
  final int arrivalTime;

  /// - 海嘯最高預估高度
  ///
  /// 範例
  /// ```
  /// 0
  /// ```
  @JsonKey(name: "wave_height")
  final int waveHeight;

  TsunamiEstimate({required this.area, required this.arrivalTime, required this.waveHeight});

  factory TsunamiEstimate.fromJson(Map<String, dynamic> json) => _$TsunamiEstimateFromJson(json);

  Map<String, dynamic> toJson() => _$TsunamiEstimateToJson(this);
}
