import 'package:json_annotation/json_annotation.dart';

part 'notification_record.g.dart';

@JsonSerializable()
class NotificationRecord {
  final int time;
  final String title;
  final String body;
  final List<String> area;
  final bool critical;

  NotificationRecord({
    required this.time,
    required this.title,
    required this.body,
    required this.area,
    required this.critical,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) => _$NotificationRecordFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationRecordToJson(this);
}
