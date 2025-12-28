import 'package:dpip/api/model/station_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'station.g.dart';

@JsonSerializable()
class Station {
  /// 測站種類
  final String net;

  /// 測站資訊
  final List<StationInfo> info;

  /// 測站是否運作
  final bool work;

  Station({required this.net, required this.info, required this.work});

  factory Station.fromJson(Map<String, dynamic> json) =>
      _$StationFromJson(json);

  Map<String, dynamic> toJson() => _$StationToJson(this);
}
