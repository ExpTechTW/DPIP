import 'package:dpip/util/parser.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rts_station.g.dart';

@JsonSerializable()
class RtsStation {
  /// 地動加速度
  final double pga;

  /// 地動速度
  final double pgv;

  /// 即時震度
  final double i;

  /// 衰減震度
  final double I;

  /// 測站是否觸發
  @JsonKey(fromJson: parseBoolishInt)
  final bool? alert;

  RtsStation({
    required this.pga,
    required this.pgv,
    required this.i,
    required this.I,
    this.alert,
  });

  factory RtsStation.fromJson(dynamic json) => _$RtsStationFromJson(json);

  Map<String, dynamic> toJson() => _$RtsStationToJson(this);
}
