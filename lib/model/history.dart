import 'package:dpip/util/parser.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:timezone/timezone.dart';

part 'history.g.dart';

@JsonSerializable()
class History {
  final String id;
  final int status;
  final String type;
  final String author;
  final InfoTime time;
  final InfoText text;
  final List<int> area;

  History({
    required this.id,
    required this.status,
    required this.type,
    required this.author,
    required this.time,
    required this.text,
    required this.area,
  });

  factory History.fromJson(Map<String, dynamic> json) => _$HistoryFromJson(json);
  Map<String, dynamic> toJson() => _$HistoryToJson(this);
}

@JsonSerializable()
class InfoTime {
  @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
  final TZDateTime send;
  final Map expires;

  InfoTime({
    required this.send,
    required this.expires,
  });

  factory InfoTime.fromJson(Map<String, dynamic> json) => _$InfoTimeFromJson(json);
  Map<String, dynamic> toJson() => _$InfoTimeToJson(this);
}

@JsonSerializable()
class InfoText {
  final Map<String, InfoTextValue> content;
  final Map<String, String> description;

  InfoText({
    required this.content,
    required this.description,
  });

  factory InfoText.fromJson(Map<String, dynamic> json) => _$InfoTextFromJson(json);
  Map<String, dynamic> toJson() => _$InfoTextToJson(this);
}

@JsonSerializable()
class InfoTextValue {
  final String title;
  final String subtitle;

  InfoTextValue({
    required this.title,
    required this.subtitle,
  });

  factory InfoTextValue.fromJson(Map<String, dynamic> json) => _$InfoTextValueFromJson(json);
  Map<String, dynamic> toJson() => _$InfoTextValueToJson(this);
}
