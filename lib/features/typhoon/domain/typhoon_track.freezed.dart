// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typhoon_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackFix {

@JsonKey(name: 't') int get time;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;/// Sustained wind (m/s).
 double? get wind;/// Gust (m/s).
 double? get gust;/// Central pressure (hPa).
@JsonKey(name: 'pres') double? get pressure;
/// Create a copy of TrackFix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackFixCopyWith<TrackFix> get copyWith => _$TrackFixCopyWithImpl<TrackFix>(this as TrackFix, _$identity);

  /// Serializes this TrackFix to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackFix&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,latitude,longitude,wind,gust,pressure);

@override
String toString() {
  return 'TrackFix(time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure)';
}


}

/// @nodoc
abstract mixin class $TrackFixCopyWith<$Res>  {
  factory $TrackFixCopyWith(TrackFix value, $Res Function(TrackFix) _then) = _$TrackFixCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure
});




}
/// @nodoc
class _$TrackFixCopyWithImpl<$Res>
    implements $TrackFixCopyWith<$Res> {
  _$TrackFixCopyWithImpl(this._self, this._then);

  final TrackFix _self;
  final $Res Function(TrackFix) _then;

/// Create a copy of TrackFix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackFix].
extension TrackFixPatterns on TrackFix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackFix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackFix() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackFix value)  $default,){
final _that = this;
switch (_that) {
case _TrackFix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackFix value)?  $default,){
final _that = this;
switch (_that) {
case _TrackFix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackFix() when $default != null:
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure)  $default,) {final _that = this;
switch (_that) {
case _TrackFix():
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure)?  $default,) {final _that = this;
switch (_that) {
case _TrackFix() when $default != null:
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackFix implements TrackFix {
  const _TrackFix({@JsonKey(name: 't') required this.time, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude, this.wind, this.gust, @JsonKey(name: 'pres') this.pressure});
  factory _TrackFix.fromJson(Map<String, dynamic> json) => _$TrackFixFromJson(json);

@override@JsonKey(name: 't') final  int time;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;
/// Sustained wind (m/s).
@override final  double? wind;
/// Gust (m/s).
@override final  double? gust;
/// Central pressure (hPa).
@override@JsonKey(name: 'pres') final  double? pressure;

/// Create a copy of TrackFix
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackFixCopyWith<_TrackFix> get copyWith => __$TrackFixCopyWithImpl<_TrackFix>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackFixToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackFix&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,latitude,longitude,wind,gust,pressure);

@override
String toString() {
  return 'TrackFix(time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure)';
}


}

/// @nodoc
abstract mixin class _$TrackFixCopyWith<$Res> implements $TrackFixCopyWith<$Res> {
  factory _$TrackFixCopyWith(_TrackFix value, $Res Function(_TrackFix) _then) = __$TrackFixCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure
});




}
/// @nodoc
class __$TrackFixCopyWithImpl<$Res>
    implements _$TrackFixCopyWith<$Res> {
  __$TrackFixCopyWithImpl(this._self, this._then);

  final _TrackFix _self;
  final $Res Function(_TrackFix) _then;

/// Create a copy of TrackFix
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,}) {
  return _then(_TrackFix(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$TrackNow {

/// Translation speed (km/hr).
 double? get speed;/// Translation heading (e.g. `WNW`).
@JsonKey(name: 'dir') String? get direction;/// Motion forecast as a `[中文, English]` pair.
 List<String>? get move;/// Level-7 (gale) storm circle; null when too weak.
 StormCircle? get c15;/// Level-10 storm circle; null when too weak.
 StormCircle? get c25;
/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackNowCopyWith<TrackNow> get copyWith => _$TrackNowCopyWithImpl<TrackNow>(this as TrackNow, _$identity);

  /// Serializes this TrackNow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackNow&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other.move, move)&&(identical(other.c15, c15) || other.c15 == c15)&&(identical(other.c25, c25) || other.c25 == c25));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speed,direction,const DeepCollectionEquality().hash(move),c15,c25);

@override
String toString() {
  return 'TrackNow(speed: $speed, direction: $direction, move: $move, c15: $c15, c25: $c25)';
}


}

/// @nodoc
abstract mixin class $TrackNowCopyWith<$Res>  {
  factory $TrackNowCopyWith(TrackNow value, $Res Function(TrackNow) _then) = _$TrackNowCopyWithImpl;
@useResult
$Res call({
 double? speed,@JsonKey(name: 'dir') String? direction, List<String>? move, StormCircle? c15, StormCircle? c25
});


$StormCircleCopyWith<$Res>? get c15;$StormCircleCopyWith<$Res>? get c25;

}
/// @nodoc
class _$TrackNowCopyWithImpl<$Res>
    implements $TrackNowCopyWith<$Res> {
  _$TrackNowCopyWithImpl(this._self, this._then);

  final TrackNow _self;
  final $Res Function(TrackNow) _then;

/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speed = freezed,Object? direction = freezed,Object? move = freezed,Object? c15 = freezed,Object? c25 = freezed,}) {
  return _then(_self.copyWith(
speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,move: freezed == move ? _self.move : move // ignore: cast_nullable_to_non_nullable
as List<String>?,c15: freezed == c15 ? _self.c15 : c15 // ignore: cast_nullable_to_non_nullable
as StormCircle?,c25: freezed == c25 ? _self.c25 : c25 // ignore: cast_nullable_to_non_nullable
as StormCircle?,
  ));
}
/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StormCircleCopyWith<$Res>? get c15 {
    if (_self.c15 == null) {
    return null;
  }

  return $StormCircleCopyWith<$Res>(_self.c15!, (value) {
    return _then(_self.copyWith(c15: value));
  });
}/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StormCircleCopyWith<$Res>? get c25 {
    if (_self.c25 == null) {
    return null;
  }

  return $StormCircleCopyWith<$Res>(_self.c25!, (value) {
    return _then(_self.copyWith(c25: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackNow].
extension TrackNowPatterns on TrackNow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackNow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackNow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackNow value)  $default,){
final _that = this;
switch (_that) {
case _TrackNow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackNow value)?  $default,){
final _that = this;
switch (_that) {
case _TrackNow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? speed, @JsonKey(name: 'dir')  String? direction,  List<String>? move,  StormCircle? c15,  StormCircle? c25)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackNow() when $default != null:
return $default(_that.speed,_that.direction,_that.move,_that.c15,_that.c25);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? speed, @JsonKey(name: 'dir')  String? direction,  List<String>? move,  StormCircle? c15,  StormCircle? c25)  $default,) {final _that = this;
switch (_that) {
case _TrackNow():
return $default(_that.speed,_that.direction,_that.move,_that.c15,_that.c25);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? speed, @JsonKey(name: 'dir')  String? direction,  List<String>? move,  StormCircle? c15,  StormCircle? c25)?  $default,) {final _that = this;
switch (_that) {
case _TrackNow() when $default != null:
return $default(_that.speed,_that.direction,_that.move,_that.c15,_that.c25);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackNow implements TrackNow {
  const _TrackNow({this.speed, @JsonKey(name: 'dir') this.direction, final  List<String>? move, this.c15, this.c25}): _move = move;
  factory _TrackNow.fromJson(Map<String, dynamic> json) => _$TrackNowFromJson(json);

/// Translation speed (km/hr).
@override final  double? speed;
/// Translation heading (e.g. `WNW`).
@override@JsonKey(name: 'dir') final  String? direction;
/// Motion forecast as a `[中文, English]` pair.
 final  List<String>? _move;
/// Motion forecast as a `[中文, English]` pair.
@override List<String>? get move {
  final value = _move;
  if (value == null) return null;
  if (_move is EqualUnmodifiableListView) return _move;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Level-7 (gale) storm circle; null when too weak.
@override final  StormCircle? c15;
/// Level-10 storm circle; null when too weak.
@override final  StormCircle? c25;

/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackNowCopyWith<_TrackNow> get copyWith => __$TrackNowCopyWithImpl<_TrackNow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackNowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackNow&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction)&&const DeepCollectionEquality().equals(other._move, _move)&&(identical(other.c15, c15) || other.c15 == c15)&&(identical(other.c25, c25) || other.c25 == c25));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speed,direction,const DeepCollectionEquality().hash(_move),c15,c25);

@override
String toString() {
  return 'TrackNow(speed: $speed, direction: $direction, move: $move, c15: $c15, c25: $c25)';
}


}

/// @nodoc
abstract mixin class _$TrackNowCopyWith<$Res> implements $TrackNowCopyWith<$Res> {
  factory _$TrackNowCopyWith(_TrackNow value, $Res Function(_TrackNow) _then) = __$TrackNowCopyWithImpl;
@override @useResult
$Res call({
 double? speed,@JsonKey(name: 'dir') String? direction, List<String>? move, StormCircle? c15, StormCircle? c25
});


@override $StormCircleCopyWith<$Res>? get c15;@override $StormCircleCopyWith<$Res>? get c25;

}
/// @nodoc
class __$TrackNowCopyWithImpl<$Res>
    implements _$TrackNowCopyWith<$Res> {
  __$TrackNowCopyWithImpl(this._self, this._then);

  final _TrackNow _self;
  final $Res Function(_TrackNow) _then;

/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speed = freezed,Object? direction = freezed,Object? move = freezed,Object? c15 = freezed,Object? c25 = freezed,}) {
  return _then(_TrackNow(
speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,move: freezed == move ? _self._move : move // ignore: cast_nullable_to_non_nullable
as List<String>?,c15: freezed == c15 ? _self.c15 : c15 // ignore: cast_nullable_to_non_nullable
as StormCircle?,c25: freezed == c25 ? _self.c25 : c25 // ignore: cast_nullable_to_non_nullable
as StormCircle?,
  ));
}

/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StormCircleCopyWith<$Res>? get c15 {
    if (_self.c15 == null) {
    return null;
  }

  return $StormCircleCopyWith<$Res>(_self.c15!, (value) {
    return _then(_self.copyWith(c15: value));
  });
}/// Create a copy of TrackNow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StormCircleCopyWith<$Res>? get c25 {
    if (_self.c25 == null) {
    return null;
  }

  return $StormCircleCopyWith<$Res>(_self.c25!, (value) {
    return _then(_self.copyWith(c25: value));
  });
}
}


/// @nodoc
mixin _$TrackForecast {

/// Forecast lead time (hours).
 int get tau;@JsonKey(name: 't') int get time;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;/// Predicted sustained wind (m/s).
 double? get wind;/// Predicted gust (m/s).
 double? get gust;/// Predicted central pressure (hPa).
@JsonKey(name: 'pres') double? get pressure;/// Predicted translation speed (km/hr).
 double? get speed;/// Predicted translation heading.
@JsonKey(name: 'dir') String? get direction;/// Level-7 wind radius (km).
 double? get r15;/// 70%-probability circle radius (km).
 double? get r70;/// Weakening / transition note as a `[中文, English]` pair.
 List<String>? get state;
/// Create a copy of TrackForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackForecastCopyWith<TrackForecast> get copyWith => _$TrackForecastCopyWithImpl<TrackForecast>(this as TrackForecast, _$identity);

  /// Serializes this TrackForecast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackForecast&&(identical(other.tau, tau) || other.tau == tau)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.r15, r15) || other.r15 == r15)&&(identical(other.r70, r70) || other.r70 == r70)&&const DeepCollectionEquality().equals(other.state, state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tau,time,latitude,longitude,wind,gust,pressure,speed,direction,r15,r70,const DeepCollectionEquality().hash(state));

@override
String toString() {
  return 'TrackForecast(tau: $tau, time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, speed: $speed, direction: $direction, r15: $r15, r70: $r70, state: $state)';
}


}

/// @nodoc
abstract mixin class $TrackForecastCopyWith<$Res>  {
  factory $TrackForecastCopyWith(TrackForecast value, $Res Function(TrackForecast) _then) = _$TrackForecastCopyWithImpl;
@useResult
$Res call({
 int tau,@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? speed,@JsonKey(name: 'dir') String? direction, double? r15, double? r70, List<String>? state
});




}
/// @nodoc
class _$TrackForecastCopyWithImpl<$Res>
    implements $TrackForecastCopyWith<$Res> {
  _$TrackForecastCopyWithImpl(this._self, this._then);

  final TrackForecast _self;
  final $Res Function(TrackForecast) _then;

/// Create a copy of TrackForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tau = null,Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? speed = freezed,Object? direction = freezed,Object? r15 = freezed,Object? r70 = freezed,Object? state = freezed,}) {
  return _then(_self.copyWith(
tau: null == tau ? _self.tau : tau // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,r15: freezed == r15 ? _self.r15 : r15 // ignore: cast_nullable_to_non_nullable
as double?,r70: freezed == r70 ? _self.r70 : r70 // ignore: cast_nullable_to_non_nullable
as double?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackForecast].
extension TrackForecastPatterns on TrackForecast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackForecast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackForecast value)  $default,){
final _that = this;
switch (_that) {
case _TrackForecast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackForecast value)?  $default,){
final _that = this;
switch (_that) {
case _TrackForecast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tau, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction,  double? r15,  double? r70,  List<String>? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackForecast() when $default != null:
return $default(_that.tau,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction,_that.r15,_that.r70,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tau, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction,  double? r15,  double? r70,  List<String>? state)  $default,) {final _that = this;
switch (_that) {
case _TrackForecast():
return $default(_that.tau,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction,_that.r15,_that.r70,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tau, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction,  double? r15,  double? r70,  List<String>? state)?  $default,) {final _that = this;
switch (_that) {
case _TrackForecast() when $default != null:
return $default(_that.tau,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction,_that.r15,_that.r70,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackForecast implements TrackForecast {
  const _TrackForecast({required this.tau, @JsonKey(name: 't') required this.time, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude, this.wind, this.gust, @JsonKey(name: 'pres') this.pressure, this.speed, @JsonKey(name: 'dir') this.direction, this.r15, this.r70, final  List<String>? state}): _state = state;
  factory _TrackForecast.fromJson(Map<String, dynamic> json) => _$TrackForecastFromJson(json);

/// Forecast lead time (hours).
@override final  int tau;
@override@JsonKey(name: 't') final  int time;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;
/// Predicted sustained wind (m/s).
@override final  double? wind;
/// Predicted gust (m/s).
@override final  double? gust;
/// Predicted central pressure (hPa).
@override@JsonKey(name: 'pres') final  double? pressure;
/// Predicted translation speed (km/hr).
@override final  double? speed;
/// Predicted translation heading.
@override@JsonKey(name: 'dir') final  String? direction;
/// Level-7 wind radius (km).
@override final  double? r15;
/// 70%-probability circle radius (km).
@override final  double? r70;
/// Weakening / transition note as a `[中文, English]` pair.
 final  List<String>? _state;
/// Weakening / transition note as a `[中文, English]` pair.
@override List<String>? get state {
  final value = _state;
  if (value == null) return null;
  if (_state is EqualUnmodifiableListView) return _state;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TrackForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackForecastCopyWith<_TrackForecast> get copyWith => __$TrackForecastCopyWithImpl<_TrackForecast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackForecastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackForecast&&(identical(other.tau, tau) || other.tau == tau)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.r15, r15) || other.r15 == r15)&&(identical(other.r70, r70) || other.r70 == r70)&&const DeepCollectionEquality().equals(other._state, _state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tau,time,latitude,longitude,wind,gust,pressure,speed,direction,r15,r70,const DeepCollectionEquality().hash(_state));

@override
String toString() {
  return 'TrackForecast(tau: $tau, time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, speed: $speed, direction: $direction, r15: $r15, r70: $r70, state: $state)';
}


}

/// @nodoc
abstract mixin class _$TrackForecastCopyWith<$Res> implements $TrackForecastCopyWith<$Res> {
  factory _$TrackForecastCopyWith(_TrackForecast value, $Res Function(_TrackForecast) _then) = __$TrackForecastCopyWithImpl;
@override @useResult
$Res call({
 int tau,@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? speed,@JsonKey(name: 'dir') String? direction, double? r15, double? r70, List<String>? state
});




}
/// @nodoc
class __$TrackForecastCopyWithImpl<$Res>
    implements _$TrackForecastCopyWith<$Res> {
  __$TrackForecastCopyWithImpl(this._self, this._then);

  final _TrackForecast _self;
  final $Res Function(_TrackForecast) _then;

/// Create a copy of TrackForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tau = null,Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? speed = freezed,Object? direction = freezed,Object? r15 = freezed,Object? r70 = freezed,Object? state = freezed,}) {
  return _then(_TrackForecast(
tau: null == tau ? _self.tau : tau // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,r15: freezed == r15 ? _self.r15 : r15 // ignore: cast_nullable_to_non_nullable
as double?,r70: freezed == r70 ? _self.r70 : r70 // ignore: cast_nullable_to_non_nullable
as double?,state: freezed == state ? _self._state : state // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$TyphoonTrack {

 String get name; String? get cwaName; int get year; String? get tdNo; String? get tyNo; List<TrackFix> get analysis; TrackNow? get now; List<TrackForecast> get forecast;
/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TyphoonTrackCopyWith<TyphoonTrack> get copyWith => _$TyphoonTrackCopyWithImpl<TyphoonTrack>(this as TyphoonTrack, _$identity);

  /// Serializes this TyphoonTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TyphoonTrack&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.year, year) || other.year == year)&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.tyNo, tyNo) || other.tyNo == tyNo)&&const DeepCollectionEquality().equals(other.analysis, analysis)&&(identical(other.now, now) || other.now == now)&&const DeepCollectionEquality().equals(other.forecast, forecast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cwaName,year,tdNo,tyNo,const DeepCollectionEquality().hash(analysis),now,const DeepCollectionEquality().hash(forecast));

@override
String toString() {
  return 'TyphoonTrack(name: $name, cwaName: $cwaName, year: $year, tdNo: $tdNo, tyNo: $tyNo, analysis: $analysis, now: $now, forecast: $forecast)';
}


}

/// @nodoc
abstract mixin class $TyphoonTrackCopyWith<$Res>  {
  factory $TyphoonTrackCopyWith(TyphoonTrack value, $Res Function(TyphoonTrack) _then) = _$TyphoonTrackCopyWithImpl;
@useResult
$Res call({
 String name, String? cwaName, int year, String? tdNo, String? tyNo, List<TrackFix> analysis, TrackNow? now, List<TrackForecast> forecast
});


$TrackNowCopyWith<$Res>? get now;

}
/// @nodoc
class _$TyphoonTrackCopyWithImpl<$Res>
    implements $TyphoonTrackCopyWith<$Res> {
  _$TyphoonTrackCopyWithImpl(this._self, this._then);

  final TyphoonTrack _self;
  final $Res Function(TyphoonTrack) _then;

/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? cwaName = freezed,Object? year = null,Object? tdNo = freezed,Object? tyNo = freezed,Object? analysis = null,Object? now = freezed,Object? forecast = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,tyNo: freezed == tyNo ? _self.tyNo : tyNo // ignore: cast_nullable_to_non_nullable
as String?,analysis: null == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as List<TrackFix>,now: freezed == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as TrackNow?,forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<TrackForecast>,
  ));
}
/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackNowCopyWith<$Res>? get now {
    if (_self.now == null) {
    return null;
  }

  return $TrackNowCopyWith<$Res>(_self.now!, (value) {
    return _then(_self.copyWith(now: value));
  });
}
}


/// Adds pattern-matching-related methods to [TyphoonTrack].
extension TyphoonTrackPatterns on TyphoonTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TyphoonTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TyphoonTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TyphoonTrack value)  $default,){
final _that = this;
switch (_that) {
case _TyphoonTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TyphoonTrack value)?  $default,){
final _that = this;
switch (_that) {
case _TyphoonTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo,  List<TrackFix> analysis,  TrackNow? now,  List<TrackForecast> forecast)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TyphoonTrack() when $default != null:
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.analysis,_that.now,_that.forecast);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo,  List<TrackFix> analysis,  TrackNow? now,  List<TrackForecast> forecast)  $default,) {final _that = this;
switch (_that) {
case _TyphoonTrack():
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.analysis,_that.now,_that.forecast);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo,  List<TrackFix> analysis,  TrackNow? now,  List<TrackForecast> forecast)?  $default,) {final _that = this;
switch (_that) {
case _TyphoonTrack() when $default != null:
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.analysis,_that.now,_that.forecast);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TyphoonTrack implements TyphoonTrack {
  const _TyphoonTrack({required this.name, this.cwaName, required this.year, this.tdNo, this.tyNo, required final  List<TrackFix> analysis, this.now, required final  List<TrackForecast> forecast}): _analysis = analysis,_forecast = forecast;
  factory _TyphoonTrack.fromJson(Map<String, dynamic> json) => _$TyphoonTrackFromJson(json);

@override final  String name;
@override final  String? cwaName;
@override final  int year;
@override final  String? tdNo;
@override final  String? tyNo;
 final  List<TrackFix> _analysis;
@override List<TrackFix> get analysis {
  if (_analysis is EqualUnmodifiableListView) return _analysis;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_analysis);
}

@override final  TrackNow? now;
 final  List<TrackForecast> _forecast;
@override List<TrackForecast> get forecast {
  if (_forecast is EqualUnmodifiableListView) return _forecast;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_forecast);
}


/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TyphoonTrackCopyWith<_TyphoonTrack> get copyWith => __$TyphoonTrackCopyWithImpl<_TyphoonTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TyphoonTrackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TyphoonTrack&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.year, year) || other.year == year)&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.tyNo, tyNo) || other.tyNo == tyNo)&&const DeepCollectionEquality().equals(other._analysis, _analysis)&&(identical(other.now, now) || other.now == now)&&const DeepCollectionEquality().equals(other._forecast, _forecast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cwaName,year,tdNo,tyNo,const DeepCollectionEquality().hash(_analysis),now,const DeepCollectionEquality().hash(_forecast));

@override
String toString() {
  return 'TyphoonTrack(name: $name, cwaName: $cwaName, year: $year, tdNo: $tdNo, tyNo: $tyNo, analysis: $analysis, now: $now, forecast: $forecast)';
}


}

/// @nodoc
abstract mixin class _$TyphoonTrackCopyWith<$Res> implements $TyphoonTrackCopyWith<$Res> {
  factory _$TyphoonTrackCopyWith(_TyphoonTrack value, $Res Function(_TyphoonTrack) _then) = __$TyphoonTrackCopyWithImpl;
@override @useResult
$Res call({
 String name, String? cwaName, int year, String? tdNo, String? tyNo, List<TrackFix> analysis, TrackNow? now, List<TrackForecast> forecast
});


@override $TrackNowCopyWith<$Res>? get now;

}
/// @nodoc
class __$TyphoonTrackCopyWithImpl<$Res>
    implements _$TyphoonTrackCopyWith<$Res> {
  __$TyphoonTrackCopyWithImpl(this._self, this._then);

  final _TyphoonTrack _self;
  final $Res Function(_TyphoonTrack) _then;

/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? cwaName = freezed,Object? year = null,Object? tdNo = freezed,Object? tyNo = freezed,Object? analysis = null,Object? now = freezed,Object? forecast = null,}) {
  return _then(_TyphoonTrack(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,tyNo: freezed == tyNo ? _self.tyNo : tyNo // ignore: cast_nullable_to_non_nullable
as String?,analysis: null == analysis ? _self._analysis : analysis // ignore: cast_nullable_to_non_nullable
as List<TrackFix>,now: freezed == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as TrackNow?,forecast: null == forecast ? _self._forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<TrackForecast>,
  ));
}

/// Create a copy of TyphoonTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackNowCopyWith<$Res>? get now {
    if (_self.now == null) {
    return null;
  }

  return $TrackNowCopyWith<$Res>(_self.now!, (value) {
    return _then(_self.copyWith(now: value));
  });
}
}


/// @nodoc
mixin _$TrackPayload {

 int get updated; List<TyphoonTrack> get cyclones;
/// Create a copy of TrackPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPayloadCopyWith<TrackPayload> get copyWith => _$TrackPayloadCopyWithImpl<TrackPayload>(this as TrackPayload, _$identity);

  /// Serializes this TrackPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPayload&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other.cyclones, cyclones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(cyclones));

@override
String toString() {
  return 'TrackPayload(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class $TrackPayloadCopyWith<$Res>  {
  factory $TrackPayloadCopyWith(TrackPayload value, $Res Function(TrackPayload) _then) = _$TrackPayloadCopyWithImpl;
@useResult
$Res call({
 int updated, List<TyphoonTrack> cyclones
});




}
/// @nodoc
class _$TrackPayloadCopyWithImpl<$Res>
    implements $TrackPayloadCopyWith<$Res> {
  _$TrackPayloadCopyWithImpl(this._self, this._then);

  final TrackPayload _self;
  final $Res Function(TrackPayload) _then;

/// Create a copy of TrackPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_self.copyWith(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self.cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonTrack>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackPayload].
extension TrackPayloadPatterns on TrackPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackPayload value)  $default,){
final _that = this;
switch (_that) {
case _TrackPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackPayload value)?  $default,){
final _that = this;
switch (_that) {
case _TrackPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updated,  List<TyphoonTrack> cyclones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackPayload() when $default != null:
return $default(_that.updated,_that.cyclones);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updated,  List<TyphoonTrack> cyclones)  $default,) {final _that = this;
switch (_that) {
case _TrackPayload():
return $default(_that.updated,_that.cyclones);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updated,  List<TyphoonTrack> cyclones)?  $default,) {final _that = this;
switch (_that) {
case _TrackPayload() when $default != null:
return $default(_that.updated,_that.cyclones);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackPayload implements TrackPayload {
  const _TrackPayload({required this.updated, required final  List<TyphoonTrack> cyclones}): _cyclones = cyclones;
  factory _TrackPayload.fromJson(Map<String, dynamic> json) => _$TrackPayloadFromJson(json);

@override final  int updated;
 final  List<TyphoonTrack> _cyclones;
@override List<TyphoonTrack> get cyclones {
  if (_cyclones is EqualUnmodifiableListView) return _cyclones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cyclones);
}


/// Create a copy of TrackPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackPayloadCopyWith<_TrackPayload> get copyWith => __$TrackPayloadCopyWithImpl<_TrackPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackPayload&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other._cyclones, _cyclones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(_cyclones));

@override
String toString() {
  return 'TrackPayload(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class _$TrackPayloadCopyWith<$Res> implements $TrackPayloadCopyWith<$Res> {
  factory _$TrackPayloadCopyWith(_TrackPayload value, $Res Function(_TrackPayload) _then) = __$TrackPayloadCopyWithImpl;
@override @useResult
$Res call({
 int updated, List<TyphoonTrack> cyclones
});




}
/// @nodoc
class __$TrackPayloadCopyWithImpl<$Res>
    implements _$TrackPayloadCopyWith<$Res> {
  __$TrackPayloadCopyWithImpl(this._self, this._then);

  final _TrackPayload _self;
  final $Res Function(_TrackPayload) _then;

/// Create a copy of TrackPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_TrackPayload(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self._cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonTrack>,
  ));
}


}

// dart format on
