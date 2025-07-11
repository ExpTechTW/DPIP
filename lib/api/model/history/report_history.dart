import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:dpip/api/model/history/history.dart';

part 'report_history.g.dart';

@JsonSerializable()
class ReportHistoryAddition {
  final String id;

  ReportHistoryAddition({required this.id});

  factory ReportHistoryAddition.fromJson(Map<String, dynamic> json) => _$ReportHistoryAdditionFromJson(json);

  Map<String, dynamic> toJson() => _$ReportHistoryAdditionToJson(this);
}

@JsonSerializable()
class ReportHistory extends History {
  final ReportHistoryAddition addition;

  ReportHistory({
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

  factory ReportHistory.fromJson(Map<String, dynamic> json) => _$ReportHistoryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ReportHistoryToJson(this);
}
