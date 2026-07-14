// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_trend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherTrend {

/// 6-char station code (the `/station` directory key).
 String get id;/// The requested range window (`24h` = hourly native, `7d` = hourly rollup).
 String get range;/// Sample times, absolute Unix seconds ascending (oldest first).
 List<int> get times;/// Air temperature (°C) per sample, index-aligned to [times].
 List<double?> get temperature;/// Relative humidity (%) per sample, index-aligned to [times].
 List<int?> get humidity;/// Station pressure (hPa) per sample, index-aligned to [times].
 List<double?> get pressure;/// Wind speed (m/s) per sample, index-aligned to [times].
 List<double?> get windSpeed;/// Wind direction (°) per sample, index-aligned to [times].
 List<int?> get windDirection;
/// Create a copy of WeatherTrend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherTrendCopyWith<WeatherTrend> get copyWith => _$WeatherTrendCopyWithImpl<WeatherTrend>(this as WeatherTrend, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherTrend&&(identical(other.id, id) || other.id == id)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.times, times)&&const DeepCollectionEquality().equals(other.temperature, temperature)&&const DeepCollectionEquality().equals(other.humidity, humidity)&&const DeepCollectionEquality().equals(other.pressure, pressure)&&const DeepCollectionEquality().equals(other.windSpeed, windSpeed)&&const DeepCollectionEquality().equals(other.windDirection, windDirection));
}


@override
int get hashCode => Object.hash(runtimeType,id,range,const DeepCollectionEquality().hash(times),const DeepCollectionEquality().hash(temperature),const DeepCollectionEquality().hash(humidity),const DeepCollectionEquality().hash(pressure),const DeepCollectionEquality().hash(windSpeed),const DeepCollectionEquality().hash(windDirection));

@override
String toString() {
  return 'WeatherTrend(id: $id, range: $range, times: $times, temperature: $temperature, humidity: $humidity, pressure: $pressure, windSpeed: $windSpeed, windDirection: $windDirection)';
}


}

/// @nodoc
abstract mixin class $WeatherTrendCopyWith<$Res>  {
  factory $WeatherTrendCopyWith(WeatherTrend value, $Res Function(WeatherTrend) _then) = _$WeatherTrendCopyWithImpl;
@useResult
$Res call({
 String id, String range, List<int> times, List<double?> temperature, List<int?> humidity, List<double?> pressure, List<double?> windSpeed, List<int?> windDirection
});




}
/// @nodoc
class _$WeatherTrendCopyWithImpl<$Res>
    implements $WeatherTrendCopyWith<$Res> {
  _$WeatherTrendCopyWithImpl(this._self, this._then);

  final WeatherTrend _self;
  final $Res Function(WeatherTrend) _then;

/// Create a copy of WeatherTrend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? range = null,Object? times = null,Object? temperature = null,Object? humidity = null,Object? pressure = null,Object? windSpeed = null,Object? windDirection = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as List<int>,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as List<double?>,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as List<int?>,pressure: null == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as List<double?>,windSpeed: null == windSpeed ? _self.windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as List<double?>,windDirection: null == windDirection ? _self.windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as List<int?>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherTrend].
extension WeatherTrendPatterns on WeatherTrend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherTrend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherTrend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherTrend value)  $default,){
final _that = this;
switch (_that) {
case _WeatherTrend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherTrend value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherTrend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String range,  List<int> times,  List<double?> temperature,  List<int?> humidity,  List<double?> pressure,  List<double?> windSpeed,  List<int?> windDirection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherTrend() when $default != null:
return $default(_that.id,_that.range,_that.times,_that.temperature,_that.humidity,_that.pressure,_that.windSpeed,_that.windDirection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String range,  List<int> times,  List<double?> temperature,  List<int?> humidity,  List<double?> pressure,  List<double?> windSpeed,  List<int?> windDirection)  $default,) {final _that = this;
switch (_that) {
case _WeatherTrend():
return $default(_that.id,_that.range,_that.times,_that.temperature,_that.humidity,_that.pressure,_that.windSpeed,_that.windDirection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String range,  List<int> times,  List<double?> temperature,  List<int?> humidity,  List<double?> pressure,  List<double?> windSpeed,  List<int?> windDirection)?  $default,) {final _that = this;
switch (_that) {
case _WeatherTrend() when $default != null:
return $default(_that.id,_that.range,_that.times,_that.temperature,_that.humidity,_that.pressure,_that.windSpeed,_that.windDirection);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherTrend implements WeatherTrend {
  const _WeatherTrend({required this.id, required this.range, required final  List<int> times, required final  List<double?> temperature, required final  List<int?> humidity, required final  List<double?> pressure, required final  List<double?> windSpeed, required final  List<int?> windDirection}): _times = times,_temperature = temperature,_humidity = humidity,_pressure = pressure,_windSpeed = windSpeed,_windDirection = windDirection;
  

/// 6-char station code (the `/station` directory key).
@override final  String id;
/// The requested range window (`24h` = hourly native, `7d` = hourly rollup).
@override final  String range;
/// Sample times, absolute Unix seconds ascending (oldest first).
 final  List<int> _times;
/// Sample times, absolute Unix seconds ascending (oldest first).
@override List<int> get times {
  if (_times is EqualUnmodifiableListView) return _times;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_times);
}

/// Air temperature (°C) per sample, index-aligned to [times].
 final  List<double?> _temperature;
/// Air temperature (°C) per sample, index-aligned to [times].
@override List<double?> get temperature {
  if (_temperature is EqualUnmodifiableListView) return _temperature;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_temperature);
}

/// Relative humidity (%) per sample, index-aligned to [times].
 final  List<int?> _humidity;
/// Relative humidity (%) per sample, index-aligned to [times].
@override List<int?> get humidity {
  if (_humidity is EqualUnmodifiableListView) return _humidity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_humidity);
}

/// Station pressure (hPa) per sample, index-aligned to [times].
 final  List<double?> _pressure;
/// Station pressure (hPa) per sample, index-aligned to [times].
@override List<double?> get pressure {
  if (_pressure is EqualUnmodifiableListView) return _pressure;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pressure);
}

/// Wind speed (m/s) per sample, index-aligned to [times].
 final  List<double?> _windSpeed;
/// Wind speed (m/s) per sample, index-aligned to [times].
@override List<double?> get windSpeed {
  if (_windSpeed is EqualUnmodifiableListView) return _windSpeed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_windSpeed);
}

/// Wind direction (°) per sample, index-aligned to [times].
 final  List<int?> _windDirection;
/// Wind direction (°) per sample, index-aligned to [times].
@override List<int?> get windDirection {
  if (_windDirection is EqualUnmodifiableListView) return _windDirection;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_windDirection);
}


/// Create a copy of WeatherTrend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherTrendCopyWith<_WeatherTrend> get copyWith => __$WeatherTrendCopyWithImpl<_WeatherTrend>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherTrend&&(identical(other.id, id) || other.id == id)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other._times, _times)&&const DeepCollectionEquality().equals(other._temperature, _temperature)&&const DeepCollectionEquality().equals(other._humidity, _humidity)&&const DeepCollectionEquality().equals(other._pressure, _pressure)&&const DeepCollectionEquality().equals(other._windSpeed, _windSpeed)&&const DeepCollectionEquality().equals(other._windDirection, _windDirection));
}


@override
int get hashCode => Object.hash(runtimeType,id,range,const DeepCollectionEquality().hash(_times),const DeepCollectionEquality().hash(_temperature),const DeepCollectionEquality().hash(_humidity),const DeepCollectionEquality().hash(_pressure),const DeepCollectionEquality().hash(_windSpeed),const DeepCollectionEquality().hash(_windDirection));

@override
String toString() {
  return 'WeatherTrend(id: $id, range: $range, times: $times, temperature: $temperature, humidity: $humidity, pressure: $pressure, windSpeed: $windSpeed, windDirection: $windDirection)';
}


}

/// @nodoc
abstract mixin class _$WeatherTrendCopyWith<$Res> implements $WeatherTrendCopyWith<$Res> {
  factory _$WeatherTrendCopyWith(_WeatherTrend value, $Res Function(_WeatherTrend) _then) = __$WeatherTrendCopyWithImpl;
@override @useResult
$Res call({
 String id, String range, List<int> times, List<double?> temperature, List<int?> humidity, List<double?> pressure, List<double?> windSpeed, List<int?> windDirection
});




}
/// @nodoc
class __$WeatherTrendCopyWithImpl<$Res>
    implements _$WeatherTrendCopyWith<$Res> {
  __$WeatherTrendCopyWithImpl(this._self, this._then);

  final _WeatherTrend _self;
  final $Res Function(_WeatherTrend) _then;

/// Create a copy of WeatherTrend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? range = null,Object? times = null,Object? temperature = null,Object? humidity = null,Object? pressure = null,Object? windSpeed = null,Object? windDirection = null,}) {
  return _then(_WeatherTrend(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,times: null == times ? _self._times : times // ignore: cast_nullable_to_non_nullable
as List<int>,temperature: null == temperature ? _self._temperature : temperature // ignore: cast_nullable_to_non_nullable
as List<double?>,humidity: null == humidity ? _self._humidity : humidity // ignore: cast_nullable_to_non_nullable
as List<int?>,pressure: null == pressure ? _self._pressure : pressure // ignore: cast_nullable_to_non_nullable
as List<double?>,windSpeed: null == windSpeed ? _self._windSpeed : windSpeed // ignore: cast_nullable_to_non_nullable
as List<double?>,windDirection: null == windDirection ? _self._windDirection : windDirection // ignore: cast_nullable_to_non_nullable
as List<int?>,
  ));
}


}

// dart format on
