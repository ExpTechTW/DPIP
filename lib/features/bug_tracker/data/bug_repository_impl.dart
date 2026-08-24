/// [BugRepository] backed by the tracker mirror API, plus the wire → domain
/// parsers exposed for tests.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/bug_tracker/data/bug_api.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:flutter/foundation.dart';

/// The forum tag that marks a thread as about THIS app. A routing marker, not
/// a category — it is filtered on and never rendered.
const String appBugTag = 'DPIP';

class BugRepositoryImpl implements BugRepository {
  const BugRepositoryImpl(this._api);

  final BugApi _api;

  @override
  Future<Result<List<BugThread>>> threads() =>
      guardResult(() async => parseBugThreads(await _api.list()));

  @override
  Future<Result<BugThreadDetail>> thread(int id) =>
      guardResult(() async => parseBugThreadDetail(await _api.thread(id)));

  @override
  Future<Result<Uint8List>> avatar(String url) =>
      guardResult(() async => (await _api.avatar(url)).bytes);
}

/// Discord custom-emote tokens (`<:name:id>`, `<a:name:id>`) read as `:name:`:
/// the numeric part is meaningless outside Discord and the angle brackets make
/// otherwise plain text look like broken HTML.
final RegExp _emoteToken = RegExp(r'<a?(:[A-Za-z0-9_]+:)\d+>');

String _normalise(String body) => body.replaceAllMapped(
  _emoteToken,
  (match) => match.group(1) ?? match.input,
);

Map<String, dynamic> _asObject(Object? value, String what) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('bug tracker: $what expected an object');
}

List<BugMessage> _parseMessages(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw const FormatException('bug tracker: msg expected an array');
  }
  return [
    for (final entry in raw)
      _normaliseInto(BugMessage.fromJson(_asObject(entry, 'message'))),
  ];
}

BugMessage _normaliseInto(BugMessage message) => message.body == null
    ? message
    : message.copyWith(body: _normalise(message.body!));

BugThread _normaliseIntoThread(BugThread thread) =>
    thread.copyWith(body: _normalise(thread.body));

/// Maps the index reply into threads. Tolerates a missing or malformed entry
/// no better than the type boundary does — one broken row means a broken
/// source, and hiding it would silently shorten the list.
/// Resolves the `users` map the updated API ships alongside every payload:
/// author identity moved OUT of thread/message objects into this directory,
/// keyed by Discord snowflake.
/// Resolves the `users` directory the updated API ships alongside every
/// payload: author identity moved OUT of thread/message objects into this
/// map, keyed by Discord snowflake.
Map<int, ({String name, String avatar})> _parseUsers(Object? raw) {
  if (raw is! Map) return const {};
  final users = <int, ({String name, String avatar})>{};
  for (final entry in raw.entries) {
    final value = entry.value; // MapEntry 欄位無法晉升型別，先落地
    final id = int.tryParse('${entry.key}');
    if (id == null || value is! Map) continue;
    final user = Map<String, dynamic>.from(value);
    users[id] = (
      name: user['name'] is String ? user['name'] as String : '',
      avatar: user['img'] is String ? user['img'] as String : '',
    );
  }
  return users;
}

({String name, String avatar}) _authorOf(
  Map<int, ({String name, String avatar})> users,
  Object? authorId,
) {
  final id = int.tryParse('$authorId');
  final user = id == null ? null : users[id];
  return (name: user?.name ?? '', avatar: user?.avatar ?? '');
}

/// Maps the index reply into threads.
///
/// New contract: the payload carries a `users` directory plus `threads` whose
/// author fields hold only an id — display identity resolves here, in the
/// data layer, so the domain model and UI never see the indirection.
List<BugThread> parseBugThreads(Object? body) {
  final map = _asObject(body, 'index');
  final users = _parseUsers(map['users']);
  final raw = map['threads'];
  if (raw is! List) {
    throw const FormatException('bug tracker: threads expected an array');
  }
  var threads = [
    for (final entry in raw)
      _normaliseIntoThread(BugThread.fromJson(_asObject(entry, 'thread'))),
  ];
  // `DPIP` is the forum's routing marker: threads without it are not about
  // this app (other bots share the channel), so they never reach the index.
  // Locked threads are staff-side conversations — same.
  threads.removeWhere(
    (thread) => thread.locked || !thread.tags.contains(appBugTag),
  );
  // The routing marker is a filter, never a category label; bilingual labels
  // keep their Chinese head only. freezed lists are unmodifiable, so this
  // rebuilds each thread instead of mutating it.
  threads = [
    for (final thread in threads)
      thread.copyWith(
        tags: [
          for (final tag in thread.tags)
            if (tag != appBugTag)
              tag.contains(' ') ? tag.split(' ').first : tag,
        ],
        authorName: _authorOf(users, thread.author).name,
        authorAvatar: _authorOf(users, thread.author).avatar,
      ),
  ];
  // The conversation replied to most recently leads.
  threads.sort((a, b) => b.lastMessageId.compareTo(a.lastMessageId));
  return threads;
}

/// Maps the detail reply: thread fields plus its `msg` reply array, resolving
/// authors through the same directory as [parseBugThreads].
BugThreadDetail parseBugThreadDetail(Object? body) {
  final map = _asObject(body, 'thread');
  final users = _parseUsers(map['users']);
  final opAuthor = _authorOf(users, map['author']);
  final thread = BugThread.fromJson(map).copyWith(
    tags: [
      for (final tag in (map['tags'] ?? const <String>[]) as List)
        if (tag != appBugTag)
          (tag as String).contains(' ') ? tag.split(' ').first : tag,
    ],
    authorName: opAuthor.name,
    authorAvatar: opAuthor.avatar,
  );
  final messages = <BugMessage>[];
  for (final message in _parseMessages(map['msg'])) {
    final info = _authorOf(users, message.author);
    messages.add(
      message.copyWith(authorName: info.name, authorAvatar: info.avatar),
    );
  }
  return BugThreadDetail(thread: thread, messages: messages);
}
