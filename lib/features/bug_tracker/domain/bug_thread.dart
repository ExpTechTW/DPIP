/// 已回報錯誤的資料模型 — the Discord bug-tracker mirror, read-only.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bug_thread.freezed.dart';
part 'bug_thread.g.dart';

/// Reads a wire string that may be absent or null into a displayable one.
///
/// The mirror reflects Discord state verbatim, and Discord lets an author
/// delete an opening post while the thread survives — such a thread arrives
/// with `"body": null`. One deleted post must not kill the whole index.
class LooseString implements JsonConverter<String, Object?> {
  const LooseString();

  @override
  String fromJson(Object? value) => value is String ? value : '';

  @override
  Object? toJson(String value) => value;
}

/// Converts Unix-seconds timestamps from the wire into UTC DateTimes.
class UnixSecondsDateTime implements JsonConverter<DateTime, int> {
  const UnixSecondsDateTime();

  @override
  DateTime fromJson(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  @override
  int toJson(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
}

/// The developers who build the app — rendered with a「開發人員」badge and a
/// primary-coloured name.
const Set<int> bugTrackerAdminIds = {780043079385612319, 592012263834255360};

/// The tracker team who triage and reply — rendered with a「工作人員」badge,
/// one step quieter than the developer badge but still distinct from users.
const Set<int> bugTrackerStaffIds = {
  452103762320949248,
  815574915901554699,
  878792688416227368,
  860479942550093866,
  905433558921920562,
  1001016404289536051,
};

/// The role an author id carries on the tracker, driving badge and colour.
enum BugAuthorRole { user, staff, admin }

BugAuthorRole bugAuthorRole(int authorId) {
  if (bugTrackerAdminIds.contains(authorId)) return BugAuthorRole.admin;
  if (bugTrackerStaffIds.contains(authorId)) return BugAuthorRole.staff;
  return BugAuthorRole.user;
}

/// One staff/victim reply inside a reported-bug thread.
@freezed
abstract class BugMessage with _$BugMessage {
  const factory BugMessage({
    required int id,
    required int author,

    /// Display name as the source shows it — Discord nicknames arrive with
    /// their location suffixes (`・ω・ (竹子) ⇛ 新竹竹東`) and are kept verbatim.
    @JsonKey(name: 'author_name') @LooseString() required String authorName,
    @JsonKey(name: 'author_avatar') @LooseString() required String authorAvatar,

    /// The reply text, with Discord custom-emote tokens normalised to their
    /// readable `:name:` form at parse time.
    @JsonKey(name: 'msg') required String? body,
    @UnixSecondsDateTime() @JsonKey(name: 'time') required DateTime time,
  }) = _BugMessage;

  factory BugMessage.fromJson(Map<String, dynamic> json) =>
      _$BugMessageFromJson(json);
}

/// A reported bug, as listed in the tracker index.
@freezed
abstract class BugThread with _$BugThread {
  const factory BugThread({
    @JsonKey(name: 'threads_id') required int id,
    @LooseString() required String title,
    @Default(<String>[]) List<String> tags,
    @LooseString() required String body,
    @JsonKey(name: 'author') required int author,
    @JsonKey(name: 'author_name') @LooseString() required String authorName,
    @JsonKey(name: 'author_avatar') @LooseString() required String authorAvatar,
    @UnixSecondsDateTime()
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
    @JsonKey(name: 'message_count') @Default(0) int messageCount,
    @Default(false) bool archived,
    @Default(false) bool locked,
    @JsonKey(name: 'last_message_id') @Default(0) int lastMessageId,
  }) = _BugThread;

  factory BugThread.fromJson(Map<String, dynamic> json) =>
      _$BugThreadFromJson(json);
}

/// A thread plus its full reply history — what the detail endpoint returns.
@freezed
abstract class BugThreadDetail with _$BugThreadDetail {
  const factory BugThreadDetail({
    required BugThread thread,
    @Default(<BugMessage>[]) List<BugMessage> messages,
  }) = _BugThreadDetail;
}
