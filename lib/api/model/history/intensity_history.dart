import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/utils/parser.dart';
import 'package:freezed_annotation/freezed_annotationdart';

part 'intensity_history.g.dart';

@JsonSerializable()
class IntensityHistoryAddition {
  final int id;
  final int serial;
  final Map<String, List<int>> area;
  final int max;

  @JsonKey(name: 'final', fromJson: parseBoolishInt)
  final bool isFinal;

  IntensityHistoryAddition({
    required this.id,
    required this.serial,
    required this.area,
    required this.max,
    required this.isFinal,
  });

  factory IntensityHistoryAddition.fromJson(Map<String, dynamic> json) => _$IntensityHistoryAdditionFromJson(json);

  Map<String, dynamic> toJson() => _$IntensityHistoryAdditionToJson(this);
}

@JsonSerializable()
class IntensityHistory extends History {
  final IntensityHistoryAddition addition;

  IntensityHistory({
    required super.id,
    required super.status,
    required super.type,
    required super.icon,
    required super.author,
    required super.time,
    required super.text,
    required super.area,
    required this.addition,
  });

  factory IntensityHistory.fromJson(Map<String, dynamic> json) => _$IntensityHistoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IntensityHistoryToJson(this);
}
