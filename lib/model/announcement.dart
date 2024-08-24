import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement {
  final int time;
  final List<int> tags;
  final String title;
  final String content;
  final bool show;

  Announcement({
    required this.time,
    required this.tags,
    required this.title,
    required this.content,
    this.show = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => _$AnnouncementFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}
