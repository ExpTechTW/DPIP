// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'release_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReleaseNote {

/// Tag name (`v3.2.1`).
@JsonKey(name: 'tag_name') String get tagName;/// Display title (usually same as [tagName]).
 String get name;/// Markdown body.
 String get body;/// Whether this is a pre-release (公測).
 bool get prerelease;/// Publish time (ISO-8601 from GitHub).
@JsonKey(name: 'published_at') DateTime get publishedAt;
/// Create a copy of ReleaseNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReleaseNoteCopyWith<ReleaseNote> get copyWith => _$ReleaseNoteCopyWithImpl<ReleaseNote>(this as ReleaseNote, _$identity);

  /// Serializes this ReleaseNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReleaseNote&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.name, name) || other.name == name)&&(identical(other.body, body) || other.body == body)&&(identical(other.prerelease, prerelease) || other.prerelease == prerelease)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tagName,name,body,prerelease,publishedAt);

@override
String toString() {
  return 'ReleaseNote(tagName: $tagName, name: $name, body: $body, prerelease: $prerelease, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $ReleaseNoteCopyWith<$Res>  {
  factory $ReleaseNoteCopyWith(ReleaseNote value, $Res Function(ReleaseNote) _then) = _$ReleaseNoteCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'tag_name') String tagName, String name, String body, bool prerelease,@JsonKey(name: 'published_at') DateTime publishedAt
});




}
/// @nodoc
class _$ReleaseNoteCopyWithImpl<$Res>
    implements $ReleaseNoteCopyWith<$Res> {
  _$ReleaseNoteCopyWithImpl(this._self, this._then);

  final ReleaseNote _self;
  final $Res Function(ReleaseNote) _then;

/// Create a copy of ReleaseNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tagName = null,Object? name = null,Object? body = null,Object? prerelease = null,Object? publishedAt = null,}) {
  return _then(ReleaseNote(
tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,prerelease: null == prerelease ? _self.prerelease : prerelease // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ReleaseNote].
extension ReleaseNotePatterns on ReleaseNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReleaseNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReleaseNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReleaseNote value)  $default,){
final _that = this;
switch (_that) {
case _ReleaseNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReleaseNote value)?  $default,){
final _that = this;
switch (_that) {
case _ReleaseNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'tag_name')  String tagName,  String name,  String body,  bool prerelease, @JsonKey(name: 'published_at')  DateTime publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReleaseNote() when $default != null:
return $default(_that.tagName,_that.name,_that.body,_that.prerelease,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'tag_name')  String tagName,  String name,  String body,  bool prerelease, @JsonKey(name: 'published_at')  DateTime publishedAt)  $default,) {final _that = this;
switch (_that) {
case _ReleaseNote():
return $default(_that.tagName,_that.name,_that.body,_that.prerelease,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'tag_name')  String tagName,  String name,  String body,  bool prerelease, @JsonKey(name: 'published_at')  DateTime publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _ReleaseNote() when $default != null:
return $default(_that.tagName,_that.name,_that.body,_that.prerelease,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReleaseNote implements ReleaseNote {
  const _ReleaseNote({@JsonKey(name: 'tag_name') required this.tagName, this.name = '', this.body = '', required this.prerelease, @JsonKey(name: 'published_at') required this.publishedAt});
  factory _ReleaseNote.fromJson(Map<String, dynamic> json) => _$ReleaseNoteFromJson(json);

/// Tag name (`v3.2.1`).
@override@JsonKey(name: 'tag_name') final  String tagName;
/// Display title (usually same as [tagName]).
@override@JsonKey() final  String name;
/// Markdown body.
@override@JsonKey() final  String body;
/// Whether this is a pre-release (公測).
@override final  bool prerelease;
/// Publish time (ISO-8601 from GitHub).
@override@JsonKey(name: 'published_at') final  DateTime publishedAt;

/// Create a copy of ReleaseNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReleaseNoteCopyWith<_ReleaseNote> get copyWith => __$ReleaseNoteCopyWithImpl<_ReleaseNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReleaseNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReleaseNote&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.name, name) || other.name == name)&&(identical(other.body, body) || other.body == body)&&(identical(other.prerelease, prerelease) || other.prerelease == prerelease)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tagName,name,body,prerelease,publishedAt);

@override
String toString() {
  return 'ReleaseNote(tagName: $tagName, name: $name, body: $body, prerelease: $prerelease, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$ReleaseNoteCopyWith<$Res> implements $ReleaseNoteCopyWith<$Res> {
  factory _$ReleaseNoteCopyWith(_ReleaseNote value, $Res Function(_ReleaseNote) _then) = __$ReleaseNoteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'tag_name') String tagName, String name, String body, bool prerelease,@JsonKey(name: 'published_at') DateTime publishedAt
});




}
/// @nodoc
class __$ReleaseNoteCopyWithImpl<$Res>
    implements _$ReleaseNoteCopyWith<$Res> {
  __$ReleaseNoteCopyWithImpl(this._self, this._then);

  final _ReleaseNote _self;
  final $Res Function(_ReleaseNote) _then;

/// Create a copy of ReleaseNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tagName = null,Object? name = null,Object? body = null,Object? prerelease = null,Object? publishedAt = null,}) {
  return _then(_ReleaseNote(
tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,prerelease: null == prerelease ? _self.prerelease : prerelease // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
