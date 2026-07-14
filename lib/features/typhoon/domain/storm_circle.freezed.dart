// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storm_circle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StormCircle {

/// Mean radius (km).
 double get avg;/// North-east quadrant radius (km).
 double get ne;/// South-east quadrant radius (km).
 double get se;/// South-west quadrant radius (km).
 double get sw;/// North-west quadrant radius (km).
 double get nw;
/// Create a copy of StormCircle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StormCircleCopyWith<StormCircle> get copyWith => _$StormCircleCopyWithImpl<StormCircle>(this as StormCircle, _$identity);

  /// Serializes this StormCircle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StormCircle&&(identical(other.avg, avg) || other.avg == avg)&&(identical(other.ne, ne) || other.ne == ne)&&(identical(other.se, se) || other.se == se)&&(identical(other.sw, sw) || other.sw == sw)&&(identical(other.nw, nw) || other.nw == nw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avg,ne,se,sw,nw);

@override
String toString() {
  return 'StormCircle(avg: $avg, ne: $ne, se: $se, sw: $sw, nw: $nw)';
}


}

/// @nodoc
abstract mixin class $StormCircleCopyWith<$Res>  {
  factory $StormCircleCopyWith(StormCircle value, $Res Function(StormCircle) _then) = _$StormCircleCopyWithImpl;
@useResult
$Res call({
 double avg, double ne, double se, double sw, double nw
});




}
/// @nodoc
class _$StormCircleCopyWithImpl<$Res>
    implements $StormCircleCopyWith<$Res> {
  _$StormCircleCopyWithImpl(this._self, this._then);

  final StormCircle _self;
  final $Res Function(StormCircle) _then;

/// Create a copy of StormCircle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avg = null,Object? ne = null,Object? se = null,Object? sw = null,Object? nw = null,}) {
  return _then(_self.copyWith(
avg: null == avg ? _self.avg : avg // ignore: cast_nullable_to_non_nullable
as double,ne: null == ne ? _self.ne : ne // ignore: cast_nullable_to_non_nullable
as double,se: null == se ? _self.se : se // ignore: cast_nullable_to_non_nullable
as double,sw: null == sw ? _self.sw : sw // ignore: cast_nullable_to_non_nullable
as double,nw: null == nw ? _self.nw : nw // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StormCircle].
extension StormCirclePatterns on StormCircle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StormCircle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StormCircle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StormCircle value)  $default,){
final _that = this;
switch (_that) {
case _StormCircle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StormCircle value)?  $default,){
final _that = this;
switch (_that) {
case _StormCircle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double avg,  double ne,  double se,  double sw,  double nw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StormCircle() when $default != null:
return $default(_that.avg,_that.ne,_that.se,_that.sw,_that.nw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double avg,  double ne,  double se,  double sw,  double nw)  $default,) {final _that = this;
switch (_that) {
case _StormCircle():
return $default(_that.avg,_that.ne,_that.se,_that.sw,_that.nw);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double avg,  double ne,  double se,  double sw,  double nw)?  $default,) {final _that = this;
switch (_that) {
case _StormCircle() when $default != null:
return $default(_that.avg,_that.ne,_that.se,_that.sw,_that.nw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StormCircle implements StormCircle {
  const _StormCircle({required this.avg, required this.ne, required this.se, required this.sw, required this.nw});
  factory _StormCircle.fromJson(Map<String, dynamic> json) => _$StormCircleFromJson(json);

/// Mean radius (km).
@override final  double avg;
/// North-east quadrant radius (km).
@override final  double ne;
/// South-east quadrant radius (km).
@override final  double se;
/// South-west quadrant radius (km).
@override final  double sw;
/// North-west quadrant radius (km).
@override final  double nw;

/// Create a copy of StormCircle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StormCircleCopyWith<_StormCircle> get copyWith => __$StormCircleCopyWithImpl<_StormCircle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StormCircleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StormCircle&&(identical(other.avg, avg) || other.avg == avg)&&(identical(other.ne, ne) || other.ne == ne)&&(identical(other.se, se) || other.se == se)&&(identical(other.sw, sw) || other.sw == sw)&&(identical(other.nw, nw) || other.nw == nw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avg,ne,se,sw,nw);

@override
String toString() {
  return 'StormCircle(avg: $avg, ne: $ne, se: $se, sw: $sw, nw: $nw)';
}


}

/// @nodoc
abstract mixin class _$StormCircleCopyWith<$Res> implements $StormCircleCopyWith<$Res> {
  factory _$StormCircleCopyWith(_StormCircle value, $Res Function(_StormCircle) _then) = __$StormCircleCopyWithImpl;
@override @useResult
$Res call({
 double avg, double ne, double se, double sw, double nw
});




}
/// @nodoc
class __$StormCircleCopyWithImpl<$Res>
    implements _$StormCircleCopyWith<$Res> {
  __$StormCircleCopyWithImpl(this._self, this._then);

  final _StormCircle _self;
  final $Res Function(_StormCircle) _then;

/// Create a copy of StormCircle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avg = null,Object? ne = null,Object? se = null,Object? sw = null,Object? nw = null,}) {
  return _then(_StormCircle(
avg: null == avg ? _self.avg : avg // ignore: cast_nullable_to_non_nullable
as double,ne: null == ne ? _self.ne : ne // ignore: cast_nullable_to_non_nullable
as double,se: null == se ? _self.se : se // ignore: cast_nullable_to_non_nullable
as double,sw: null == sw ? _self.sw : sw // ignore: cast_nullable_to_non_nullable
as double,nw: null == nw ? _self.nw : nw // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
