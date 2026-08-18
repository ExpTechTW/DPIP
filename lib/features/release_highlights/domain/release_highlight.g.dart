// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_highlight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseHighlightCard _$ReleaseHighlightCardFromJson(
  Map<String, dynamic> json,
) => ReleaseHighlightCard(
  id: json['id'] as String,
  icon: json['icon'] as String,
  title: Map<String, String>.from(json['title'] as Map),
  headline: (json['headline'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  body: (json['body'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  stat: (json['stat'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  statLabel: (json['statLabel'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  highlights:
      (json['highlights'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ??
      const [],
  details:
      (json['details'] as List<dynamic>?)
          ?.map((e) => HighlightDetail.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  stats:
      (json['stats'] as List<dynamic>?)
          ?.map((e) => HighlightStat.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ReleaseHighlightCardToJson(
  ReleaseHighlightCard instance,
) => <String, dynamic>{
  'id': instance.id,
  'icon': instance.icon,
  'title': instance.title,
  'headline': instance.headline,
  'body': instance.body,
  'stat': instance.stat,
  'statLabel': instance.statLabel,
  'highlights': instance.highlights,
  'details': instance.details.map((e) => e.toJson()).toList(),
  'stats': instance.stats.map((e) => e.toJson()).toList(),
};

HighlightDetail _$HighlightDetailFromJson(Map<String, dynamic> json) =>
    HighlightDetail(
      key: Map<String, String>.from(json['key'] as Map),
      value: Map<String, String>.from(json['value'] as Map),
    );

Map<String, dynamic> _$HighlightDetailToJson(HighlightDetail instance) =>
    <String, dynamic>{'key': instance.key, 'value': instance.value};

HighlightStat _$HighlightStatFromJson(Map<String, dynamic> json) =>
    HighlightStat(
      value: Map<String, String>.from(json['value'] as Map),
      label: Map<String, String>.from(json['label'] as Map),
    );

Map<String, dynamic> _$HighlightStatToJson(HighlightStat instance) =>
    <String, dynamic>{'value': instance.value, 'label': instance.label};
