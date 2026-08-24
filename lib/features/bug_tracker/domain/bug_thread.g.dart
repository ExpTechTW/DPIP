// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bug_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BugMessage _$BugMessageFromJson(Map<String, dynamic> json) => _BugMessage(
  id: (json['id'] as num).toInt(),
  author: (json['author'] as num).toInt(),
  authorName: const LooseString().fromJson(json['author_name']),
  authorAvatar: const LooseString().fromJson(json['author_avatar']),
  body: json['msg'] as String?,
  time: const UnixSecondsDateTime().fromJson((json['time'] as num).toInt()),
);

Map<String, dynamic> _$BugMessageToJson(_BugMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'author_name': const LooseString().toJson(instance.authorName),
      'author_avatar': const LooseString().toJson(instance.authorAvatar),
      'msg': instance.body,
      'time': const UnixSecondsDateTime().toJson(instance.time),
    };

_BugThread _$BugThreadFromJson(Map<String, dynamic> json) => _BugThread(
  id: (json['threads_id'] as num).toInt(),
  title: const LooseString().fromJson(json['title']),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  body: const LooseString().fromJson(json['body']),
  author: (json['author'] as num).toInt(),
  authorName: const LooseString().fromJson(json['author_name']),
  authorAvatar: const LooseString().fromJson(json['author_avatar']),
  createdAt: const UnixSecondsDateTime().fromJson(
    (json['created_at'] as num).toInt(),
  ),
  messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
  archived: json['archived'] as bool? ?? false,
  locked: json['locked'] as bool? ?? false,
  lastMessageId: (json['last_message_id'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BugThreadToJson(_BugThread instance) =>
    <String, dynamic>{
      'threads_id': instance.id,
      'title': const LooseString().toJson(instance.title),
      'tags': instance.tags,
      'body': const LooseString().toJson(instance.body),
      'author': instance.author,
      'author_name': const LooseString().toJson(instance.authorName),
      'author_avatar': const LooseString().toJson(instance.authorAvatar),
      'created_at': const UnixSecondsDateTime().toJson(instance.createdAt),
      'message_count': instance.messageCount,
      'archived': instance.archived,
      'locked': instance.locked,
      'last_message_id': instance.lastMessageId,
    };
