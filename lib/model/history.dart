import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

@JsonSerializable()
class History {
  final String id;
  final int status;
  final String type;
  final String author;
  final Time time;
  final Text text;
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
class Time {
  final int send;
  final Expires expires;

  Time({
    required this.send,
    required this.expires,
  });

  factory Time.fromJson(Map<String, dynamic> json) => _$TimeFromJson(json);
  Map<String, dynamic> toJson() => _$TimeToJson(this);
}

@JsonSerializable()
class Expires {
  final int all;

  Expires({required this.all});

  factory Expires.fromJson(Map<String, dynamic> json) => _$ExpiresFromJson(json);
  Map<String, dynamic> toJson() => _$ExpiresToJson(this);
}

@JsonSerializable()
class Text {
  final Content content;
  final Description description;

  Text({
    required this.content,
    required this.description,
  });

  factory Text.fromJson(Map<String, dynamic> json) => _$TextFromJson(json);
  Map<String, dynamic> toJson() => _$TextToJson(this);
}

@JsonSerializable()
class Content {
  final All all;

  Content({required this.all});

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);
  Map<String, dynamic> toJson() => _$ContentToJson(this);
}

@JsonSerializable()
class All {
  final String title;
  final String subtitle;

  All({required this.title, required this.subtitle});

  factory All.fromJson(Map<String, dynamic> json) => _$AllFromJson(json);
  Map<String, dynamic> toJson() => _$AllToJson(this);
}

@JsonSerializable()
class Description {
  final String all;

  Description({required this.all});

  factory Description.fromJson(Map<String, dynamic> json) => _$DescriptionFromJson(json);
  Map<String, dynamic> toJson() => _$DescriptionToJson(this);
}
