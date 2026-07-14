// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lightning_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LightningStrike {

/// Discharge type: `0` = cloud-to-cloud, `1` = cloud-to-ground.
 int get type;/// The strike's own timestamp (Unix seconds).
 int get time; double get latitude; double get longitude;
/// Create a copy of LightningStrike
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LightningStrikeCopyWith<LightningStrike> get copyWith => _$LightningStrikeCopyWithImpl<LightningStrike>(this as LightningStrike, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LightningStrike&&(identical(other.type, type) || other.type == type)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}


@override
int get hashCode => Object.hash(runtimeType,type,time,latitude,longitude);

@override
String toString() {
  return 'LightningStrike(type: $type, time: $time, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $LightningStrikeCopyWith<$Res>  {
  factory $LightningStrikeCopyWith(LightningStrike value, $Res Function(LightningStrike) _then) = _$LightningStrikeCopyWithImpl;
@useResult
$Res call({
 int type, int time, double latitude, double longitude
});




}
/// @nodoc
class _$LightningStrikeCopyWithImpl<$Res>
    implements $LightningStrikeCopyWith<$Res> {
  _$LightningStrikeCopyWithImpl(this._self, this._then);

  final LightningStrike _self;
  final $Res Function(LightningStrike) _then;

/// Create a copy of LightningStrike
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? time = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LightningStrike].
extension LightningStrikePatterns on LightningStrike {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LightningStrike value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LightningStrike() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LightningStrike value)  $default,){
final _that = this;
switch (_that) {
case _LightningStrike():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LightningStrike value)?  $default,){
final _that = this;
switch (_that) {
case _LightningStrike() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int type,  int time,  double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LightningStrike() when $default != null:
return $default(_that.type,_that.time,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int type,  int time,  double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _LightningStrike():
return $default(_that.type,_that.time,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int type,  int time,  double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _LightningStrike() when $default != null:
return $default(_that.type,_that.time,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc


class _LightningStrike implements LightningStrike {
  const _LightningStrike({required this.type, required this.time, required this.latitude, required this.longitude});
  

/// Discharge type: `0` = cloud-to-cloud, `1` = cloud-to-ground.
@override final  int type;
/// The strike's own timestamp (Unix seconds).
@override final  int time;
@override final  double latitude;
@override final  double longitude;

/// Create a copy of LightningStrike
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LightningStrikeCopyWith<_LightningStrike> get copyWith => __$LightningStrikeCopyWithImpl<_LightningStrike>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LightningStrike&&(identical(other.type, type) || other.type == type)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}


@override
int get hashCode => Object.hash(runtimeType,type,time,latitude,longitude);

@override
String toString() {
  return 'LightningStrike(type: $type, time: $time, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$LightningStrikeCopyWith<$Res> implements $LightningStrikeCopyWith<$Res> {
  factory _$LightningStrikeCopyWith(_LightningStrike value, $Res Function(_LightningStrike) _then) = __$LightningStrikeCopyWithImpl;
@override @useResult
$Res call({
 int type, int time, double latitude, double longitude
});




}
/// @nodoc
class __$LightningStrikeCopyWithImpl<$Res>
    implements _$LightningStrikeCopyWith<$Res> {
  __$LightningStrikeCopyWithImpl(this._self, this._then);

  final _LightningStrike _self;
  final $Res Function(_LightningStrike) _then;

/// Create a copy of LightningStrike
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? time = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_LightningStrike(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$LightningSnapshot {

 int get time; List<LightningStrike> get strikes;
/// Create a copy of LightningSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LightningSnapshotCopyWith<LightningSnapshot> get copyWith => _$LightningSnapshotCopyWithImpl<LightningSnapshot>(this as LightningSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LightningSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other.strikes, strikes));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(strikes));

@override
String toString() {
  return 'LightningSnapshot(time: $time, strikes: $strikes)';
}


}

/// @nodoc
abstract mixin class $LightningSnapshotCopyWith<$Res>  {
  factory $LightningSnapshotCopyWith(LightningSnapshot value, $Res Function(LightningSnapshot) _then) = _$LightningSnapshotCopyWithImpl;
@useResult
$Res call({
 int time, List<LightningStrike> strikes
});




}
/// @nodoc
class _$LightningSnapshotCopyWithImpl<$Res>
    implements $LightningSnapshotCopyWith<$Res> {
  _$LightningSnapshotCopyWithImpl(this._self, this._then);

  final LightningSnapshot _self;
  final $Res Function(LightningSnapshot) _then;

/// Create a copy of LightningSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? strikes = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,strikes: null == strikes ? _self.strikes : strikes // ignore: cast_nullable_to_non_nullable
as List<LightningStrike>,
  ));
}

}


/// Adds pattern-matching-related methods to [LightningSnapshot].
extension LightningSnapshotPatterns on LightningSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LightningSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LightningSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LightningSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _LightningSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LightningSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _LightningSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int time,  List<LightningStrike> strikes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LightningSnapshot() when $default != null:
return $default(_that.time,_that.strikes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int time,  List<LightningStrike> strikes)  $default,) {final _that = this;
switch (_that) {
case _LightningSnapshot():
return $default(_that.time,_that.strikes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int time,  List<LightningStrike> strikes)?  $default,) {final _that = this;
switch (_that) {
case _LightningSnapshot() when $default != null:
return $default(_that.time,_that.strikes);case _:
  return null;

}
}

}

/// @nodoc


class _LightningSnapshot implements LightningSnapshot {
  const _LightningSnapshot({required this.time, required final  List<LightningStrike> strikes}): _strikes = strikes;
  

@override final  int time;
 final  List<LightningStrike> _strikes;
@override List<LightningStrike> get strikes {
  if (_strikes is EqualUnmodifiableListView) return _strikes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_strikes);
}


/// Create a copy of LightningSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LightningSnapshotCopyWith<_LightningSnapshot> get copyWith => __$LightningSnapshotCopyWithImpl<_LightningSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LightningSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other._strikes, _strikes));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(_strikes));

@override
String toString() {
  return 'LightningSnapshot(time: $time, strikes: $strikes)';
}


}

/// @nodoc
abstract mixin class _$LightningSnapshotCopyWith<$Res> implements $LightningSnapshotCopyWith<$Res> {
  factory _$LightningSnapshotCopyWith(_LightningSnapshot value, $Res Function(_LightningSnapshot) _then) = __$LightningSnapshotCopyWithImpl;
@override @useResult
$Res call({
 int time, List<LightningStrike> strikes
});




}
/// @nodoc
class __$LightningSnapshotCopyWithImpl<$Res>
    implements _$LightningSnapshotCopyWith<$Res> {
  __$LightningSnapshotCopyWithImpl(this._self, this._then);

  final _LightningSnapshot _self;
  final $Res Function(_LightningSnapshot) _then;

/// Create a copy of LightningSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? strikes = null,}) {
  return _then(_LightningSnapshot(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,strikes: null == strikes ? _self._strikes : strikes // ignore: cast_nullable_to_non_nullable
as List<LightningStrike>,
  ));
}


}

// dart format on
