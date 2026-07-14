// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rain_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RainObservation {

/// 6-char station code (the `/station` directory key).
 String get id;/// Accumulation since the top of the current period (`now`).
 double? get now;/// Last 10 minutes (`10m`).
 double? get min10;/// Last 1 hour (`1h`).
 double? get hour1;/// Last 3 hours (`3h`).
 double? get hour3;/// Last 6 hours (`6h`).
 double? get hour6;/// Last 12 hours (`12h`).
 double? get hour12;/// Last 24 hours (`24h`).
 double? get hour24;/// Last 2 days (`2d`).
 double? get day2;/// Last 3 days (`3d`).
 double? get day3;
/// Create a copy of RainObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainObservationCopyWith<RainObservation> get copyWith => _$RainObservationCopyWithImpl<RainObservation>(this as RainObservation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainObservation&&(identical(other.id, id) || other.id == id)&&(identical(other.now, now) || other.now == now)&&(identical(other.min10, min10) || other.min10 == min10)&&(identical(other.hour1, hour1) || other.hour1 == hour1)&&(identical(other.hour3, hour3) || other.hour3 == hour3)&&(identical(other.hour6, hour6) || other.hour6 == hour6)&&(identical(other.hour12, hour12) || other.hour12 == hour12)&&(identical(other.hour24, hour24) || other.hour24 == hour24)&&(identical(other.day2, day2) || other.day2 == day2)&&(identical(other.day3, day3) || other.day3 == day3));
}


@override
int get hashCode => Object.hash(runtimeType,id,now,min10,hour1,hour3,hour6,hour12,hour24,day2,day3);

@override
String toString() {
  return 'RainObservation(id: $id, now: $now, min10: $min10, hour1: $hour1, hour3: $hour3, hour6: $hour6, hour12: $hour12, hour24: $hour24, day2: $day2, day3: $day3)';
}


}

/// @nodoc
abstract mixin class $RainObservationCopyWith<$Res>  {
  factory $RainObservationCopyWith(RainObservation value, $Res Function(RainObservation) _then) = _$RainObservationCopyWithImpl;
@useResult
$Res call({
 String id, double? now, double? min10, double? hour1, double? hour3, double? hour6, double? hour12, double? hour24, double? day2, double? day3
});




}
/// @nodoc
class _$RainObservationCopyWithImpl<$Res>
    implements $RainObservationCopyWith<$Res> {
  _$RainObservationCopyWithImpl(this._self, this._then);

  final RainObservation _self;
  final $Res Function(RainObservation) _then;

/// Create a copy of RainObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? now = freezed,Object? min10 = freezed,Object? hour1 = freezed,Object? hour3 = freezed,Object? hour6 = freezed,Object? hour12 = freezed,Object? hour24 = freezed,Object? day2 = freezed,Object? day3 = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,now: freezed == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as double?,min10: freezed == min10 ? _self.min10 : min10 // ignore: cast_nullable_to_non_nullable
as double?,hour1: freezed == hour1 ? _self.hour1 : hour1 // ignore: cast_nullable_to_non_nullable
as double?,hour3: freezed == hour3 ? _self.hour3 : hour3 // ignore: cast_nullable_to_non_nullable
as double?,hour6: freezed == hour6 ? _self.hour6 : hour6 // ignore: cast_nullable_to_non_nullable
as double?,hour12: freezed == hour12 ? _self.hour12 : hour12 // ignore: cast_nullable_to_non_nullable
as double?,hour24: freezed == hour24 ? _self.hour24 : hour24 // ignore: cast_nullable_to_non_nullable
as double?,day2: freezed == day2 ? _self.day2 : day2 // ignore: cast_nullable_to_non_nullable
as double?,day3: freezed == day3 ? _self.day3 : day3 // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RainObservation].
extension RainObservationPatterns on RainObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RainObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RainObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RainObservation value)  $default,){
final _that = this;
switch (_that) {
case _RainObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RainObservation value)?  $default,){
final _that = this;
switch (_that) {
case _RainObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double? now,  double? min10,  double? hour1,  double? hour3,  double? hour6,  double? hour12,  double? hour24,  double? day2,  double? day3)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RainObservation() when $default != null:
return $default(_that.id,_that.now,_that.min10,_that.hour1,_that.hour3,_that.hour6,_that.hour12,_that.hour24,_that.day2,_that.day3);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double? now,  double? min10,  double? hour1,  double? hour3,  double? hour6,  double? hour12,  double? hour24,  double? day2,  double? day3)  $default,) {final _that = this;
switch (_that) {
case _RainObservation():
return $default(_that.id,_that.now,_that.min10,_that.hour1,_that.hour3,_that.hour6,_that.hour12,_that.hour24,_that.day2,_that.day3);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double? now,  double? min10,  double? hour1,  double? hour3,  double? hour6,  double? hour12,  double? hour24,  double? day2,  double? day3)?  $default,) {final _that = this;
switch (_that) {
case _RainObservation() when $default != null:
return $default(_that.id,_that.now,_that.min10,_that.hour1,_that.hour3,_that.hour6,_that.hour12,_that.hour24,_that.day2,_that.day3);case _:
  return null;

}
}

}

/// @nodoc


class _RainObservation implements RainObservation {
  const _RainObservation({required this.id, this.now, this.min10, this.hour1, this.hour3, this.hour6, this.hour12, this.hour24, this.day2, this.day3});
  

/// 6-char station code (the `/station` directory key).
@override final  String id;
/// Accumulation since the top of the current period (`now`).
@override final  double? now;
/// Last 10 minutes (`10m`).
@override final  double? min10;
/// Last 1 hour (`1h`).
@override final  double? hour1;
/// Last 3 hours (`3h`).
@override final  double? hour3;
/// Last 6 hours (`6h`).
@override final  double? hour6;
/// Last 12 hours (`12h`).
@override final  double? hour12;
/// Last 24 hours (`24h`).
@override final  double? hour24;
/// Last 2 days (`2d`).
@override final  double? day2;
/// Last 3 days (`3d`).
@override final  double? day3;

/// Create a copy of RainObservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RainObservationCopyWith<_RainObservation> get copyWith => __$RainObservationCopyWithImpl<_RainObservation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RainObservation&&(identical(other.id, id) || other.id == id)&&(identical(other.now, now) || other.now == now)&&(identical(other.min10, min10) || other.min10 == min10)&&(identical(other.hour1, hour1) || other.hour1 == hour1)&&(identical(other.hour3, hour3) || other.hour3 == hour3)&&(identical(other.hour6, hour6) || other.hour6 == hour6)&&(identical(other.hour12, hour12) || other.hour12 == hour12)&&(identical(other.hour24, hour24) || other.hour24 == hour24)&&(identical(other.day2, day2) || other.day2 == day2)&&(identical(other.day3, day3) || other.day3 == day3));
}


@override
int get hashCode => Object.hash(runtimeType,id,now,min10,hour1,hour3,hour6,hour12,hour24,day2,day3);

@override
String toString() {
  return 'RainObservation(id: $id, now: $now, min10: $min10, hour1: $hour1, hour3: $hour3, hour6: $hour6, hour12: $hour12, hour24: $hour24, day2: $day2, day3: $day3)';
}


}

/// @nodoc
abstract mixin class _$RainObservationCopyWith<$Res> implements $RainObservationCopyWith<$Res> {
  factory _$RainObservationCopyWith(_RainObservation value, $Res Function(_RainObservation) _then) = __$RainObservationCopyWithImpl;
@override @useResult
$Res call({
 String id, double? now, double? min10, double? hour1, double? hour3, double? hour6, double? hour12, double? hour24, double? day2, double? day3
});




}
/// @nodoc
class __$RainObservationCopyWithImpl<$Res>
    implements _$RainObservationCopyWith<$Res> {
  __$RainObservationCopyWithImpl(this._self, this._then);

  final _RainObservation _self;
  final $Res Function(_RainObservation) _then;

/// Create a copy of RainObservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? now = freezed,Object? min10 = freezed,Object? hour1 = freezed,Object? hour3 = freezed,Object? hour6 = freezed,Object? hour12 = freezed,Object? hour24 = freezed,Object? day2 = freezed,Object? day3 = freezed,}) {
  return _then(_RainObservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,now: freezed == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as double?,min10: freezed == min10 ? _self.min10 : min10 // ignore: cast_nullable_to_non_nullable
as double?,hour1: freezed == hour1 ? _self.hour1 : hour1 // ignore: cast_nullable_to_non_nullable
as double?,hour3: freezed == hour3 ? _self.hour3 : hour3 // ignore: cast_nullable_to_non_nullable
as double?,hour6: freezed == hour6 ? _self.hour6 : hour6 // ignore: cast_nullable_to_non_nullable
as double?,hour12: freezed == hour12 ? _self.hour12 : hour12 // ignore: cast_nullable_to_non_nullable
as double?,hour24: freezed == hour24 ? _self.hour24 : hour24 // ignore: cast_nullable_to_non_nullable
as double?,day2: freezed == day2 ? _self.day2 : day2 // ignore: cast_nullable_to_non_nullable
as double?,day3: freezed == day3 ? _self.day3 : day3 // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$RainSnapshot {

 int get time; List<RainObservation> get stations;
/// Create a copy of RainSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainSnapshotCopyWith<RainSnapshot> get copyWith => _$RainSnapshotCopyWithImpl<RainSnapshot>(this as RainSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other.stations, stations));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(stations));

@override
String toString() {
  return 'RainSnapshot(time: $time, stations: $stations)';
}


}

/// @nodoc
abstract mixin class $RainSnapshotCopyWith<$Res>  {
  factory $RainSnapshotCopyWith(RainSnapshot value, $Res Function(RainSnapshot) _then) = _$RainSnapshotCopyWithImpl;
@useResult
$Res call({
 int time, List<RainObservation> stations
});




}
/// @nodoc
class _$RainSnapshotCopyWithImpl<$Res>
    implements $RainSnapshotCopyWith<$Res> {
  _$RainSnapshotCopyWithImpl(this._self, this._then);

  final RainSnapshot _self;
  final $Res Function(RainSnapshot) _then;

/// Create a copy of RainSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? stations = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,stations: null == stations ? _self.stations : stations // ignore: cast_nullable_to_non_nullable
as List<RainObservation>,
  ));
}

}


/// Adds pattern-matching-related methods to [RainSnapshot].
extension RainSnapshotPatterns on RainSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RainSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RainSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RainSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _RainSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RainSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _RainSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int time,  List<RainObservation> stations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RainSnapshot() when $default != null:
return $default(_that.time,_that.stations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int time,  List<RainObservation> stations)  $default,) {final _that = this;
switch (_that) {
case _RainSnapshot():
return $default(_that.time,_that.stations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int time,  List<RainObservation> stations)?  $default,) {final _that = this;
switch (_that) {
case _RainSnapshot() when $default != null:
return $default(_that.time,_that.stations);case _:
  return null;

}
}

}

/// @nodoc


class _RainSnapshot implements RainSnapshot {
  const _RainSnapshot({required this.time, required final  List<RainObservation> stations}): _stations = stations;
  

@override final  int time;
 final  List<RainObservation> _stations;
@override List<RainObservation> get stations {
  if (_stations is EqualUnmodifiableListView) return _stations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stations);
}


/// Create a copy of RainSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RainSnapshotCopyWith<_RainSnapshot> get copyWith => __$RainSnapshotCopyWithImpl<_RainSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RainSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other._stations, _stations));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(_stations));

@override
String toString() {
  return 'RainSnapshot(time: $time, stations: $stations)';
}


}

/// @nodoc
abstract mixin class _$RainSnapshotCopyWith<$Res> implements $RainSnapshotCopyWith<$Res> {
  factory _$RainSnapshotCopyWith(_RainSnapshot value, $Res Function(_RainSnapshot) _then) = __$RainSnapshotCopyWithImpl;
@override @useResult
$Res call({
 int time, List<RainObservation> stations
});




}
/// @nodoc
class __$RainSnapshotCopyWithImpl<$Res>
    implements _$RainSnapshotCopyWith<$Res> {
  __$RainSnapshotCopyWithImpl(this._self, this._then);

  final _RainSnapshot _self;
  final $Res Function(_RainSnapshot) _then;

/// Create a copy of RainSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? stations = null,}) {
  return _then(_RainSnapshot(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,stations: null == stations ? _self._stations : stations // ignore: cast_nullable_to_non_nullable
as List<RainObservation>,
  ));
}


}

// dart format on
