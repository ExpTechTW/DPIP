import 'package:json_annotation/json_annotation.dart';

import 'package:dpip/api/model/station_intensity.dart';

part 'area_intensity.g.dart';

@JsonSerializable()
class AreaIntensity {
  /// 區域最大觀測震度
  @JsonKey(name: 'int')
  final int intensity;

  /// 區域內測站觀測資料
  final Map<String, StationIntensity> town;

  AreaIntensity({required this.intensity, required this.town});

  factory AreaIntensity.fromJson(Map<String, dynamic> json) => _$AreaIntensityFromJson(json);

  Map<String, dynamic> toJson() => _$AreaIntensityToJson(this);
}
