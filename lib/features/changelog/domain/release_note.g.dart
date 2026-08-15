// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReleaseNote _$ReleaseNoteFromJson(Map<String, dynamic> json) => _ReleaseNote(
  tagName: json['tag_name'] as String,
  name: json['name'] as String? ?? '',
  body: json['body'] as String? ?? '',
  prerelease: json['prerelease'] as bool,
  htmlUrl: json['html_url'] as String? ?? '',
  publishedAt: DateTime.parse(json['published_at'] as String),
);

Map<String, dynamic> _$ReleaseNoteToJson(_ReleaseNote instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'name': instance.name,
      'body': instance.body,
      'prerelease': instance.prerelease,
      'html_url': instance.htmlUrl,
      'published_at': instance.publishedAt.toIso8601String(),
    };
