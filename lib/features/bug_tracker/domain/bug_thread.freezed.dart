// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bug_thread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BugMessage {

 int get id; int get author;/// Display name as the source shows it — Discord nicknames arrive with
/// their location suffixes (`・ω・ (竹子) ⇛ 新竹竹東`) and are kept verbatim.
@JsonKey(name: 'author_name')@LooseString() String get authorName;@JsonKey(name: 'author_avatar')@LooseString() String get authorAvatar;/// The reply text, with Discord custom-emote tokens normalised to their
/// readable `:name:` form at parse time.
@JsonKey(name: 'msg') String? get body;@UnixSecondsDateTime()@JsonKey(name: 'time') DateTime get time;
/// Create a copy of BugMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BugMessageCopyWith<BugMessage> get copyWith => _$BugMessageCopyWithImpl<BugMessage>(this as BugMessage, _$identity);

  /// Serializes this BugMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BugMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorAvatar, authorAvatar) || other.authorAvatar == authorAvatar)&&(identical(other.body, body) || other.body == body)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,authorName,authorAvatar,body,time);

@override
String toString() {
  return 'BugMessage(id: $id, author: $author, authorName: $authorName, authorAvatar: $authorAvatar, body: $body, time: $time)';
}


}

/// @nodoc
abstract mixin class $BugMessageCopyWith<$Res>  {
  factory $BugMessageCopyWith(BugMessage value, $Res Function(BugMessage) _then) = _$BugMessageCopyWithImpl;
@useResult
$Res call({
 int id, int author,@JsonKey(name: 'author_name')@LooseString() String authorName,@JsonKey(name: 'author_avatar')@LooseString() String authorAvatar,@JsonKey(name: 'msg') String? body,@UnixSecondsDateTime()@JsonKey(name: 'time') DateTime time
});




}
/// @nodoc
class _$BugMessageCopyWithImpl<$Res>
    implements $BugMessageCopyWith<$Res> {
  _$BugMessageCopyWithImpl(this._self, this._then);

  final BugMessage _self;
  final $Res Function(BugMessage) _then;

/// Create a copy of BugMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? authorName = null,Object? authorAvatar = null,Object? body = freezed,Object? time = null,}) {
  return _then(BugMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as int,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorAvatar: null == authorAvatar ? _self.authorAvatar : authorAvatar // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BugMessage].
extension BugMessagePatterns on BugMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BugMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BugMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BugMessage value)  $default,){
final _that = this;
switch (_that) {
case _BugMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BugMessage value)?  $default,){
final _that = this;
switch (_that) {
case _BugMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @JsonKey(name: 'msg')  String? body, @UnixSecondsDateTime()@JsonKey(name: 'time')  DateTime time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BugMessage() when $default != null:
return $default(_that.id,_that.author,_that.authorName,_that.authorAvatar,_that.body,_that.time);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @JsonKey(name: 'msg')  String? body, @UnixSecondsDateTime()@JsonKey(name: 'time')  DateTime time)  $default,) {final _that = this;
switch (_that) {
case _BugMessage():
return $default(_that.id,_that.author,_that.authorName,_that.authorAvatar,_that.body,_that.time);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @JsonKey(name: 'msg')  String? body, @UnixSecondsDateTime()@JsonKey(name: 'time')  DateTime time)?  $default,) {final _that = this;
switch (_that) {
case _BugMessage() when $default != null:
return $default(_that.id,_that.author,_that.authorName,_that.authorAvatar,_that.body,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BugMessage implements BugMessage {
  const _BugMessage({required this.id, required this.author, @JsonKey(name: 'author_name')@LooseString() required this.authorName, @JsonKey(name: 'author_avatar')@LooseString() required this.authorAvatar, @JsonKey(name: 'msg') required this.body, @UnixSecondsDateTime()@JsonKey(name: 'time') required this.time});
  factory _BugMessage.fromJson(Map<String, dynamic> json) => _$BugMessageFromJson(json);

@override final  int id;
@override final  int author;
/// Display name as the source shows it — Discord nicknames arrive with
/// their location suffixes (`・ω・ (竹子) ⇛ 新竹竹東`) and are kept verbatim.
@override@JsonKey(name: 'author_name')@LooseString() final  String authorName;
@override@JsonKey(name: 'author_avatar')@LooseString() final  String authorAvatar;
/// The reply text, with Discord custom-emote tokens normalised to their
/// readable `:name:` form at parse time.
@override@JsonKey(name: 'msg') final  String? body;
@override@UnixSecondsDateTime()@JsonKey(name: 'time') final  DateTime time;

/// Create a copy of BugMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BugMessageCopyWith<_BugMessage> get copyWith => __$BugMessageCopyWithImpl<_BugMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BugMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BugMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorAvatar, authorAvatar) || other.authorAvatar == authorAvatar)&&(identical(other.body, body) || other.body == body)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,authorName,authorAvatar,body,time);

@override
String toString() {
  return 'BugMessage(id: $id, author: $author, authorName: $authorName, authorAvatar: $authorAvatar, body: $body, time: $time)';
}


}

/// @nodoc
abstract mixin class _$BugMessageCopyWith<$Res> implements $BugMessageCopyWith<$Res> {
  factory _$BugMessageCopyWith(_BugMessage value, $Res Function(_BugMessage) _then) = __$BugMessageCopyWithImpl;
@override @useResult
$Res call({
 int id, int author,@JsonKey(name: 'author_name')@LooseString() String authorName,@JsonKey(name: 'author_avatar')@LooseString() String authorAvatar,@JsonKey(name: 'msg') String? body,@UnixSecondsDateTime()@JsonKey(name: 'time') DateTime time
});




}
/// @nodoc
class __$BugMessageCopyWithImpl<$Res>
    implements _$BugMessageCopyWith<$Res> {
  __$BugMessageCopyWithImpl(this._self, this._then);

  final _BugMessage _self;
  final $Res Function(_BugMessage) _then;

/// Create a copy of BugMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? authorName = null,Object? authorAvatar = null,Object? body = freezed,Object? time = null,}) {
  return _then(_BugMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as int,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorAvatar: null == authorAvatar ? _self.authorAvatar : authorAvatar // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$BugThread {

@JsonKey(name: 'threads_id') int get id;@LooseString() String get title; List<String> get tags;@LooseString() String get body;@JsonKey(name: 'author') int get author;@JsonKey(name: 'author_name')@LooseString() String get authorName;@JsonKey(name: 'author_avatar')@LooseString() String get authorAvatar;@UnixSecondsDateTime()@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'message_count') int get messageCount; bool get archived; bool get locked;@JsonKey(name: 'last_message_id') int get lastMessageId;
/// Create a copy of BugThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BugThreadCopyWith<BugThread> get copyWith => _$BugThreadCopyWithImpl<BugThread>(this as BugThread, _$identity);

  /// Serializes this BugThread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BugThread&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorAvatar, authorAvatar) || other.authorAvatar == authorAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.lastMessageId, lastMessageId) || other.lastMessageId == lastMessageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(tags),body,author,authorName,authorAvatar,createdAt,messageCount,archived,locked,lastMessageId);

@override
String toString() {
  return 'BugThread(id: $id, title: $title, tags: $tags, body: $body, author: $author, authorName: $authorName, authorAvatar: $authorAvatar, createdAt: $createdAt, messageCount: $messageCount, archived: $archived, locked: $locked, lastMessageId: $lastMessageId)';
}


}

/// @nodoc
abstract mixin class $BugThreadCopyWith<$Res>  {
  factory $BugThreadCopyWith(BugThread value, $Res Function(BugThread) _then) = _$BugThreadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'threads_id') int id,@LooseString() String title, List<String> tags,@LooseString() String body,@JsonKey(name: 'author') int author,@JsonKey(name: 'author_name')@LooseString() String authorName,@JsonKey(name: 'author_avatar')@LooseString() String authorAvatar,@UnixSecondsDateTime()@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'message_count') int messageCount, bool archived, bool locked,@JsonKey(name: 'last_message_id') int lastMessageId
});




}
/// @nodoc
class _$BugThreadCopyWithImpl<$Res>
    implements $BugThreadCopyWith<$Res> {
  _$BugThreadCopyWithImpl(this._self, this._then);

  final BugThread _self;
  final $Res Function(BugThread) _then;

/// Create a copy of BugThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? body = null,Object? author = null,Object? authorName = null,Object? authorAvatar = null,Object? createdAt = null,Object? messageCount = null,Object? archived = null,Object? locked = null,Object? lastMessageId = null,}) {
  return _then(BugThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as int,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorAvatar: null == authorAvatar ? _self.authorAvatar : authorAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,messageCount: null == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as int,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,lastMessageId: null == lastMessageId ? _self.lastMessageId : lastMessageId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BugThread].
extension BugThreadPatterns on BugThread {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BugThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BugThread() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BugThread value)  $default,){
final _that = this;
switch (_that) {
case _BugThread():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BugThread value)?  $default,){
final _that = this;
switch (_that) {
case _BugThread() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'threads_id')  int id, @LooseString()  String title,  List<String> tags, @LooseString()  String body, @JsonKey(name: 'author')  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @UnixSecondsDateTime()@JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'message_count')  int messageCount,  bool archived,  bool locked, @JsonKey(name: 'last_message_id')  int lastMessageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BugThread() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.body,_that.author,_that.authorName,_that.authorAvatar,_that.createdAt,_that.messageCount,_that.archived,_that.locked,_that.lastMessageId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'threads_id')  int id, @LooseString()  String title,  List<String> tags, @LooseString()  String body, @JsonKey(name: 'author')  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @UnixSecondsDateTime()@JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'message_count')  int messageCount,  bool archived,  bool locked, @JsonKey(name: 'last_message_id')  int lastMessageId)  $default,) {final _that = this;
switch (_that) {
case _BugThread():
return $default(_that.id,_that.title,_that.tags,_that.body,_that.author,_that.authorName,_that.authorAvatar,_that.createdAt,_that.messageCount,_that.archived,_that.locked,_that.lastMessageId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'threads_id')  int id, @LooseString()  String title,  List<String> tags, @LooseString()  String body, @JsonKey(name: 'author')  int author, @JsonKey(name: 'author_name')@LooseString()  String authorName, @JsonKey(name: 'author_avatar')@LooseString()  String authorAvatar, @UnixSecondsDateTime()@JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'message_count')  int messageCount,  bool archived,  bool locked, @JsonKey(name: 'last_message_id')  int lastMessageId)?  $default,) {final _that = this;
switch (_that) {
case _BugThread() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.body,_that.author,_that.authorName,_that.authorAvatar,_that.createdAt,_that.messageCount,_that.archived,_that.locked,_that.lastMessageId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BugThread implements BugThread {
  const _BugThread({@JsonKey(name: 'threads_id') required this.id, @LooseString() required this.title,  List<String> tags = const <String>[], @LooseString() required this.body, @JsonKey(name: 'author') required this.author, @JsonKey(name: 'author_name')@LooseString() required this.authorName, @JsonKey(name: 'author_avatar')@LooseString() required this.authorAvatar, @UnixSecondsDateTime()@JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'message_count') this.messageCount = 0, this.archived = false, this.locked = false, @JsonKey(name: 'last_message_id') this.lastMessageId = 0}): _tags = tags;
  factory _BugThread.fromJson(Map<String, dynamic> json) => _$BugThreadFromJson(json);

@override@JsonKey(name: 'threads_id') final  int id;
@override@LooseString() final  String title;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@LooseString() final  String body;
@override@JsonKey(name: 'author') final  int author;
@override@JsonKey(name: 'author_name')@LooseString() final  String authorName;
@override@JsonKey(name: 'author_avatar')@LooseString() final  String authorAvatar;
@override@UnixSecondsDateTime()@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'message_count') final  int messageCount;
@override@JsonKey() final  bool archived;
@override@JsonKey() final  bool locked;
@override@JsonKey(name: 'last_message_id') final  int lastMessageId;

/// Create a copy of BugThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BugThreadCopyWith<_BugThread> get copyWith => __$BugThreadCopyWithImpl<_BugThread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BugThreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BugThread&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorAvatar, authorAvatar) || other.authorAvatar == authorAvatar)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.locked, locked) || other.locked == locked)&&(identical(other.lastMessageId, lastMessageId) || other.lastMessageId == lastMessageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_tags),body,author,authorName,authorAvatar,createdAt,messageCount,archived,locked,lastMessageId);

@override
String toString() {
  return 'BugThread(id: $id, title: $title, tags: $tags, body: $body, author: $author, authorName: $authorName, authorAvatar: $authorAvatar, createdAt: $createdAt, messageCount: $messageCount, archived: $archived, locked: $locked, lastMessageId: $lastMessageId)';
}


}

/// @nodoc
abstract mixin class _$BugThreadCopyWith<$Res> implements $BugThreadCopyWith<$Res> {
  factory _$BugThreadCopyWith(_BugThread value, $Res Function(_BugThread) _then) = __$BugThreadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'threads_id') int id,@LooseString() String title, List<String> tags,@LooseString() String body,@JsonKey(name: 'author') int author,@JsonKey(name: 'author_name')@LooseString() String authorName,@JsonKey(name: 'author_avatar')@LooseString() String authorAvatar,@UnixSecondsDateTime()@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'message_count') int messageCount, bool archived, bool locked,@JsonKey(name: 'last_message_id') int lastMessageId
});




}
/// @nodoc
class __$BugThreadCopyWithImpl<$Res>
    implements _$BugThreadCopyWith<$Res> {
  __$BugThreadCopyWithImpl(this._self, this._then);

  final _BugThread _self;
  final $Res Function(_BugThread) _then;

/// Create a copy of BugThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? body = null,Object? author = null,Object? authorName = null,Object? authorAvatar = null,Object? createdAt = null,Object? messageCount = null,Object? archived = null,Object? locked = null,Object? lastMessageId = null,}) {
  return _then(_BugThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as int,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorAvatar: null == authorAvatar ? _self.authorAvatar : authorAvatar // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,messageCount: null == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as int,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,locked: null == locked ? _self.locked : locked // ignore: cast_nullable_to_non_nullable
as bool,lastMessageId: null == lastMessageId ? _self.lastMessageId : lastMessageId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BugThreadDetail {

 BugThread get thread; List<BugMessage> get messages;
/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BugThreadDetailCopyWith<BugThreadDetail> get copyWith => _$BugThreadDetailCopyWithImpl<BugThreadDetail>(this as BugThreadDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BugThreadDetail&&(identical(other.thread, thread) || other.thread == thread)&&const DeepCollectionEquality().equals(other.messages, messages));
}


@override
int get hashCode => Object.hash(runtimeType,thread,const DeepCollectionEquality().hash(messages));

@override
String toString() {
  return 'BugThreadDetail(thread: $thread, messages: $messages)';
}


}

/// @nodoc
abstract mixin class $BugThreadDetailCopyWith<$Res>  {
  factory $BugThreadDetailCopyWith(BugThreadDetail value, $Res Function(BugThreadDetail) _then) = _$BugThreadDetailCopyWithImpl;
@useResult
$Res call({
 BugThread thread, List<BugMessage> messages
});


$BugThreadCopyWith<$Res> get thread;

}
/// @nodoc
class _$BugThreadDetailCopyWithImpl<$Res>
    implements $BugThreadDetailCopyWith<$Res> {
  _$BugThreadDetailCopyWithImpl(this._self, this._then);

  final BugThreadDetail _self;
  final $Res Function(BugThreadDetail) _then;

/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? thread = null,Object? messages = null,}) {
  return _then(BugThreadDetail(
thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as BugThread,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<BugMessage>,
  ));
}
/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BugThreadCopyWith<$Res> get thread {
  
  return $BugThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}
}


/// Adds pattern-matching-related methods to [BugThreadDetail].
extension BugThreadDetailPatterns on BugThreadDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BugThreadDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BugThreadDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BugThreadDetail value)  $default,){
final _that = this;
switch (_that) {
case _BugThreadDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BugThreadDetail value)?  $default,){
final _that = this;
switch (_that) {
case _BugThreadDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BugThread thread,  List<BugMessage> messages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BugThreadDetail() when $default != null:
return $default(_that.thread,_that.messages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BugThread thread,  List<BugMessage> messages)  $default,) {final _that = this;
switch (_that) {
case _BugThreadDetail():
return $default(_that.thread,_that.messages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BugThread thread,  List<BugMessage> messages)?  $default,) {final _that = this;
switch (_that) {
case _BugThreadDetail() when $default != null:
return $default(_that.thread,_that.messages);case _:
  return null;

}
}

}

/// @nodoc


class _BugThreadDetail implements BugThreadDetail {
  const _BugThreadDetail({required this.thread,  List<BugMessage> messages = const <BugMessage>[]}): _messages = messages;
  

@override final  BugThread thread;
 final  List<BugMessage> _messages;
@override@JsonKey() List<BugMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}


/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BugThreadDetailCopyWith<_BugThreadDetail> get copyWith => __$BugThreadDetailCopyWithImpl<_BugThreadDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BugThreadDetail&&(identical(other.thread, thread) || other.thread == thread)&&const DeepCollectionEquality().equals(other._messages, _messages));
}


@override
int get hashCode => Object.hash(runtimeType,thread,const DeepCollectionEquality().hash(_messages));

@override
String toString() {
  return 'BugThreadDetail(thread: $thread, messages: $messages)';
}


}

/// @nodoc
abstract mixin class _$BugThreadDetailCopyWith<$Res> implements $BugThreadDetailCopyWith<$Res> {
  factory _$BugThreadDetailCopyWith(_BugThreadDetail value, $Res Function(_BugThreadDetail) _then) = __$BugThreadDetailCopyWithImpl;
@override @useResult
$Res call({
 BugThread thread, List<BugMessage> messages
});


@override $BugThreadCopyWith<$Res> get thread;

}
/// @nodoc
class __$BugThreadDetailCopyWithImpl<$Res>
    implements _$BugThreadDetailCopyWith<$Res> {
  __$BugThreadDetailCopyWithImpl(this._self, this._then);

  final _BugThreadDetail _self;
  final $Res Function(_BugThreadDetail) _then;

/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? thread = null,Object? messages = null,}) {
  return _then(_BugThreadDetail(
thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as BugThread,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<BugMessage>,
  ));
}

/// Create a copy of BugThreadDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BugThreadCopyWith<$Res> get thread {
  
  return $BugThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}
}

// dart format on
