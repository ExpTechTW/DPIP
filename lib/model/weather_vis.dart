import 'package:json_annotation/json_annotation.dart';

part 'weather_vis.g.dart';

@JsonSerializable()
class weatherVis {
  /// 能見度公里
  final int km;

  /// 能見度英里
  final int miles;

  const weatherVis({
    required this.km,
    required this.miles,
  });

  factory weatherVis.fromJson(Map<String, dynamic> json) => _$weatherVisFromJson(json);

  Map<String, dynamic> toJson() => _$weatherVisToJson(this);
}
