// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherObservation {

/// 6-char station code (the `/station` directory key).
 String get id;/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300;
/// 0 = no data).
 int get weatherCode; double? get temperature; int? get humidity; double? get pressure; int? get windDirection; double? get windSpeed; double? get gustSpeed; int? get gustDirection; double? get high; double? get low;
/// Create a copy of WeatherObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherObservationCopyWith<WeatherObservation> get copyWith => _$WeatherObservationCopyWithImpl<WeatherObservation>(this as WeatherObservation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherObservation&&(identical(other.id, id) || other.id == id)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.windDirection, windDirection) || other.windDirection == windDirection)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.gustSpeed, gustSpeed) || other.gustSpeed == gustSpeed)&&(identical(other.gustDirection, gustDirection) || other.gustDirection == gustDirection)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low));
}


@override
int get hashCode => Object.hash(runtimeType,id,weatherCode,temperature,humidity,pressure,windDirection,windSpeed,gustSpeed,gustDirection,high,low);

@override
String toString() {
  return 'WeatherObservation(id: $id, weatherCode: $weatherCode, temperature: $temperature, humidity: $humidity, pressure: $pressure, windDirection: $windDirection, windSpeed: $windSpeed, gustSpeed: $gustSpeed, gustDirection: $gustDirection, high: $high, low: $low)';
}


}

/// @nodoc
abstract mixin class $WeatherObservationCopyWith<$Res>  {
  factory $WeatherObservationCopyWith(WeatherObservation value, $Res Function(WeatherObservation) _then) = _$WeatherObservationCopyWithImpl;
@useResult
$Res call({
 String id, int weatherCode, double? temperature, int? humidity, double? pressure, int? windDirection, double? windSpeed, double? gustSpeed, int? gustDirection, double? high, double? low
});




}
/// @nodoc
class _$WeatherObservationCopyWithImpl<$Res>
    implements $WeatherObservationCopyWith<$Res> {
  _$WeatherObservationCopyWithImpl(this._self, this._then);

  final WeatherObservation _self;
  final $Res Function(WeatherObservation) _then;

/// Create a copy of WeatherObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? weatherCode = null,Object? temperature = freezed,Object? humidity = freezed,Object? pressure = freezed,Object? windDirection = freezed,Object? windSpeed = freezed,Object? gustSpeed = freezed,Object? gustDirection = freezed,Object? high = freezed,Object? low = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,windDirection: freezed == windDirection ? _self.windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as int?,windSpeed: freezed == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double?,gustSpeed: freezed == gustSpeed ? _self.gustSpeed : gustSpeed // ignore: cast_nullable_to_non_nullable
as double?,gustDirection: freezed == gustDirection ? _self.gustDirection : gustDirection // ignore: cast_nullable_to_non_nullable
as int?,high: freezed == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double?,low: freezed == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherObservation].
extension WeatherObservationPatterns on WeatherObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherObservation value)  $default,){
final _that = this;
switch (_that) {
case _WeatherObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherObservation value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int weatherCode,  double? temperature,  int? humidity,  double? pressure,  int? windDirection,  double? windSpeed,  double? gustSpeed,  int? gustDirection,  double? high,  double? low)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherObservation() when $default != null:
return $default(_that.id,_that.weatherCode,_that.temperature,_that.humidity,_that.pressure,_that.windDirection,_that.windSpeed,_that.gustSpeed,_that.gustDirection,_that.high,_that.low);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int weatherCode,  double? temperature,  int? humidity,  double? pressure,  int? windDirection,  double? windSpeed,  double? gustSpeed,  int? gustDirection,  double? high,  double? low)  $default,) {final _that = this;
switch (_that) {
case _WeatherObservation():
return $default(_that.id,_that.weatherCode,_that.temperature,_that.humidity,_that.pressure,_that.windDirection,_that.windSpeed,_that.gustSpeed,_that.gustDirection,_that.high,_that.low);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int weatherCode,  double? temperature,  int? humidity,  double? pressure,  int? windDirection,  double? windSpeed,  double? gustSpeed,  int? gustDirection,  double? high,  double? low)?  $default,) {final _that = this;
switch (_that) {
case _WeatherObservation() when $default != null:
return $default(_that.id,_that.weatherCode,_that.temperature,_that.humidity,_that.pressure,_that.windDirection,_that.windSpeed,_that.gustSpeed,_that.gustDirection,_that.high,_that.low);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherObservation implements WeatherObservation {
  const _WeatherObservation({required this.id, required this.weatherCode, this.temperature, this.humidity, this.pressure, this.windDirection, this.windSpeed, this.gustSpeed, this.gustDirection, this.high, this.low});
  

/// 6-char station code (the `/station` directory key).
@override final  String id;
/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300;
/// 0 = no data).
@override final  int weatherCode;
@override final  double? temperature;
@override final  int? humidity;
@override final  double? pressure;
@override final  int? windDirection;
@override final  double? windSpeed;
@override final  double? gustSpeed;
@override final  int? gustDirection;
@override final  double? high;
@override final  double? low;

/// Create a copy of WeatherObservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherObservationCopyWith<_WeatherObservation> get copyWith => __$WeatherObservationCopyWithImpl<_WeatherObservation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherObservation&&(identical(other.id, id) || other.id == id)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.windDirection, windDirection) || other.windDirection == windDirection)&&(identical(other.windSpeed, windSpeed) || other.windSpeed == windSpeed)&&(identical(other.gustSpeed, gustSpeed) || other.gustSpeed == gustSpeed)&&(identical(other.gustDirection, gustDirection) || other.gustDirection == gustDirection)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low));
}


@override
int get hashCode => Object.hash(runtimeType,id,weatherCode,temperature,humidity,pressure,windDirection,windSpeed,gustSpeed,gustDirection,high,low);

@override
String toString() {
  return 'WeatherObservation(id: $id, weatherCode: $weatherCode, temperature: $temperature, humidity: $humidity, pressure: $pressure, windDirection: $windDirection, windSpeed: $windSpeed, gustSpeed: $gustSpeed, gustDirection: $gustDirection, high: $high, low: $low)';
}


}

/// @nodoc
abstract mixin class _$WeatherObservationCopyWith<$Res> implements $WeatherObservationCopyWith<$Res> {
  factory _$WeatherObservationCopyWith(_WeatherObservation value, $Res Function(_WeatherObservation) _then) = __$WeatherObservationCopyWithImpl;
@override @useResult
$Res call({
 String id, int weatherCode, double? temperature, int? humidity, double? pressure, int? windDirection, double? windSpeed, double? gustSpeed, int? gustDirection, double? high, double? low
});




}
/// @nodoc
class __$WeatherObservationCopyWithImpl<$Res>
    implements _$WeatherObservationCopyWith<$Res> {
  __$WeatherObservationCopyWithImpl(this._self, this._then);

  final _WeatherObservation _self;
  final $Res Function(_WeatherObservation) _then;

/// Create a copy of WeatherObservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? weatherCode = null,Object? temperature = freezed,Object? humidity = freezed,Object? pressure = freezed,Object? windDirection = freezed,Object? windSpeed = freezed,Object? gustSpeed = freezed,Object? gustDirection = freezed,Object? high = freezed,Object? low = freezed,}) {
  return _then(_WeatherObservation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,windDirection: freezed == windDirection ? _self.windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as int?,windSpeed: freezed == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as double?,gustSpeed: freezed == gustSpeed ? _self.gustSpeed : gustSpeed // ignore: cast_nullable_to_non_nullable
as double?,gustDirection: freezed == gustDirection ? _self.gustDirection : gustDirection // ignore: cast_nullable_to_non_nullable
as int?,high: freezed == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as double?,low: freezed == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$WeatherSnapshot {

 int get time; List<WeatherObservation> get stations;
/// Create a copy of WeatherSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherSnapshotCopyWith<WeatherSnapshot> get copyWith => _$WeatherSnapshotCopyWithImpl<WeatherSnapshot>(this as WeatherSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other.stations, stations));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(stations));

@override
String toString() {
  return 'WeatherSnapshot(time: $time, stations: $stations)';
}


}

/// @nodoc
abstract mixin class $WeatherSnapshotCopyWith<$Res>  {
  factory $WeatherSnapshotCopyWith(WeatherSnapshot value, $Res Function(WeatherSnapshot) _then) = _$WeatherSnapshotCopyWithImpl;
@useResult
$Res call({
 int time, List<WeatherObservation> stations
});




}
/// @nodoc
class _$WeatherSnapshotCopyWithImpl<$Res>
    implements $WeatherSnapshotCopyWith<$Res> {
  _$WeatherSnapshotCopyWithImpl(this._self, this._then);

  final WeatherSnapshot _self;
  final $Res Function(WeatherSnapshot) _then;

/// Create a copy of WeatherSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? stations = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,stations: null == stations ? _self.stations : stations // ignore: cast_nullable_to_non_nullable
as List<WeatherObservation>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherSnapshot].
extension WeatherSnapshotPatterns on WeatherSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _WeatherSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int time,  List<WeatherObservation> stations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherSnapshot() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int time,  List<WeatherObservation> stations)  $default,) {final _that = this;
switch (_that) {
case _WeatherSnapshot():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int time,  List<WeatherObservation> stations)?  $default,) {final _that = this;
switch (_that) {
case _WeatherSnapshot() when $default != null:
return $default(_that.time,_that.stations);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherSnapshot implements WeatherSnapshot {
  const _WeatherSnapshot({required this.time, required final  List<WeatherObservation> stations}): _stations = stations;
  

@override final  int time;
 final  List<WeatherObservation> _stations;
@override List<WeatherObservation> get stations {
  if (_stations is EqualUnmodifiableListView) return _stations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stations);
}


/// Create a copy of WeatherSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherSnapshotCopyWith<_WeatherSnapshot> get copyWith => __$WeatherSnapshotCopyWithImpl<_WeatherSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherSnapshot&&(identical(other.time, time) || other.time == time)&&const DeepCollectionEquality().equals(other._stations, _stations));
}


@override
int get hashCode => Object.hash(runtimeType,time,const DeepCollectionEquality().hash(_stations));

@override
String toString() {
  return 'WeatherSnapshot(time: $time, stations: $stations)';
}


}

/// @nodoc
abstract mixin class _$WeatherSnapshotCopyWith<$Res> implements $WeatherSnapshotCopyWith<$Res> {
  factory _$WeatherSnapshotCopyWith(_WeatherSnapshot value, $Res Function(_WeatherSnapshot) _then) = __$WeatherSnapshotCopyWithImpl;
@override @useResult
$Res call({
 int time, List<WeatherObservation> stations
});




}
/// @nodoc
class __$WeatherSnapshotCopyWithImpl<$Res>
    implements _$WeatherSnapshotCopyWith<$Res> {
  __$WeatherSnapshotCopyWithImpl(this._self, this._then);

  final _WeatherSnapshot _self;
  final $Res Function(_WeatherSnapshot) _then;

/// Create a copy of WeatherSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? stations = null,}) {
  return _then(_WeatherSnapshot(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,stations: null == stations ? _self._stations : stations // ignore: cast_nullable_to_non_nullable
as List<WeatherObservation>,
  ));
}


}

// dart format on
