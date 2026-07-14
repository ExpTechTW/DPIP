// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rain_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RainTrend {

/// 6-char station code (the `/station` directory key).
 String get id;/// The requested range window (`24h` = 10-min native, `7d` = hourly rollup).
 String get range;/// Sample times, absolute Unix seconds ascending (oldest first).
 List<int> get times;/// Rolling 1-hour rainfall (mm) per sample, index-aligned to [times].
 List<double?> get rain;
/// Create a copy of RainTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RainTrendCopyWith<RainTrend> get copyWith => _$RainTrendCopyWithImpl<RainTrend>(this as RainTrend, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RainTrend&&(identical(other.id, id) || other.id == id)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.times, times)&&const DeepCollectionEquality().equals(other.rain, rain));
}


@override
int get hashCode => Object.hash(runtimeType,id,range,const DeepCollectionEquality().hash(times),const DeepCollectionEquality().hash(rain));

@override
String toString() {
  return 'RainTrend(id: $id, range: $range, times: $times, rain: $rain)';
}


}

/// @nodoc
abstract mixin class $RainTrendCopyWith<$Res>  {
  factory $RainTrendCopyWith(RainTrend value, $Res Function(RainTrend) _then) = _$RainTrendCopyWithImpl;
@useResult
$Res call({
 String id, String range, List<int> times, List<double?> rain
});




}
/// @nodoc
class _$RainTrendCopyWithImpl<$Res>
    implements $RainTrendCopyWith<$Res> {
  _$RainTrendCopyWithImpl(this._self, this._then);

  final RainTrend _self;
  final $Res Function(RainTrend) _then;

/// Create a copy of RainTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? range = null,Object? times = null,Object? rain = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as List<int>,rain: null == rain ? _self.rain : rain // ignore: cast_nullable_to_non_nullable
as List<double?>,
  ));
}

}


/// Adds pattern-matching-related methods to [RainTrend].
extension RainTrendPatterns on RainTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RainTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RainTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RainTrend value)  $default,){
final _that = this;
switch (_that) {
case _RainTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RainTrend value)?  $default,){
final _that = this;
switch (_that) {
case _RainTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String range,  List<int> times,  List<double?> rain)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RainTrend() when $default != null:
return $default(_that.id,_that.range,_that.times,_that.rain);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String range,  List<int> times,  List<double?> rain)  $default,) {final _that = this;
switch (_that) {
case _RainTrend():
return $default(_that.id,_that.range,_that.times,_that.rain);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String range,  List<int> times,  List<double?> rain)?  $default,) {final _that = this;
switch (_that) {
case _RainTrend() when $default != null:
return $default(_that.id,_that.range,_that.times,_that.rain);case _:
  return null;

}
}

}

/// @nodoc


class _RainTrend implements RainTrend {
  const _RainTrend({required this.id, required this.range, required final  List<int> times, required final  List<double?> rain}): _times = times,_rain = rain;
  

/// 6-char station code (the `/station` directory key).
@override final  String id;
/// The requested range window (`24h` = 10-min native, `7d` = hourly rollup).
@override final  String range;
/// Sample times, absolute Unix seconds ascending (oldest first).
 final  List<int> _times;
/// Sample times, absolute Unix seconds ascending (oldest first).
@override List<int> get times {
  if (_times is EqualUnmodifiableListView) return _times;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_times);
}

/// Rolling 1-hour rainfall (mm) per sample, index-aligned to [times].
 final  List<double?> _rain;
/// Rolling 1-hour rainfall (mm) per sample, index-aligned to [times].
@override List<double?> get rain {
  if (_rain is EqualUnmodifiableListView) return _rain;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rain);
}


/// Create a copy of RainTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RainTrendCopyWith<_RainTrend> get copyWith => __$RainTrendCopyWithImpl<_RainTrend>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RainTrend&&(identical(other.id, id) || other.id == id)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other._times, _times)&&const DeepCollectionEquality().equals(other._rain, _rain));
}


@override
int get hashCode => Object.hash(runtimeType,id,range,const DeepCollectionEquality().hash(_times),const DeepCollectionEquality().hash(_rain));

@override
String toString() {
  return 'RainTrend(id: $id, range: $range, times: $times, rain: $rain)';
}


}

/// @nodoc
abstract mixin class _$RainTrendCopyWith<$Res> implements $RainTrendCopyWith<$Res> {
  factory _$RainTrendCopyWith(_RainTrend value, $Res Function(_RainTrend) _then) = __$RainTrendCopyWithImpl;
@override @useResult
$Res call({
 String id, String range, List<int> times, List<double?> rain
});




}
/// @nodoc
class __$RainTrendCopyWithImpl<$Res>
    implements _$RainTrendCopyWith<$Res> {
  __$RainTrendCopyWithImpl(this._self, this._then);

  final _RainTrend _self;
  final $Res Function(_RainTrend) _then;

/// Create a copy of RainTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? range = null,Object? times = null,Object? rain = null,}) {
  return _then(_RainTrend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,times: null == times ? _self._times : times // ignore: cast_nullable_to_non_nullable
as List<int>,rain: null == rain ? _self._rain : rain // ignore: cast_nullable_to_non_nullable
as List<double?>,
  ));
}


}

// dart format on
