// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_forecast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherForecast {

/// Publish time, Unix **milliseconds** (13-digit) — see [updatedAt].
 int get updateTime; List<WeatherForecastPoint> get forecast;
/// Create a copy of WeatherForecast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherForecastCopyWith<WeatherForecast> get copyWith => _$WeatherForecastCopyWithImpl<WeatherForecast>(this as WeatherForecast, _$identity);

  /// Serializes this WeatherForecast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherForecast&&(identical(other.updateTime, updateTime) || other.updateTime == updateTime)&&const DeepCollectionEquality().equals(other.forecast, forecast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updateTime,const DeepCollectionEquality().hash(forecast));

@override
String toString() {
  return 'WeatherForecast(updateTime: $updateTime, forecast: $forecast)';
}


}

/// @nodoc
abstract mixin class $WeatherForecastCopyWith<$Res>  {
  factory $WeatherForecastCopyWith(WeatherForecast value, $Res Function(WeatherForecast) _then) = _$WeatherForecastCopyWithImpl;
@useResult
$Res call({
 int updateTime, List<WeatherForecastPoint> forecast
});




}
/// @nodoc
class _$WeatherForecastCopyWithImpl<$Res>
    implements $WeatherForecastCopyWith<$Res> {
  _$WeatherForecastCopyWithImpl(this._self, this._then);

  final WeatherForecast _self;
  final $Res Function(WeatherForecast) _then;

/// Create a copy of WeatherForecast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updateTime = null,Object? forecast = null,}) {
  return _then(_self.copyWith(
updateTime: null == updateTime ? _self.updateTime : updateTime // ignore: cast_nullable_to_non_nullable
as int,forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<WeatherForecastPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherForecast].
extension WeatherForecastPatterns on WeatherForecast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherForecast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherForecast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherForecast value)  $default,){
final _that = this;
switch (_that) {
case _WeatherForecast():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherForecast value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherForecast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updateTime,  List<WeatherForecastPoint> forecast)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherForecast() when $default != null:
return $default(_that.updateTime,_that.forecast);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updateTime,  List<WeatherForecastPoint> forecast)  $default,) {final _that = this;
switch (_that) {
case _WeatherForecast():
return $default(_that.updateTime,_that.forecast);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updateTime,  List<WeatherForecastPoint> forecast)?  $default,) {final _that = this;
switch (_that) {
case _WeatherForecast() when $default != null:
return $default(_that.updateTime,_that.forecast);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherForecast extends WeatherForecast {
  const _WeatherForecast({required this.updateTime, required final  List<WeatherForecastPoint> forecast}): _forecast = forecast,super._();
  factory _WeatherForecast.fromJson(Map<String, dynamic> json) => _$WeatherForecastFromJson(json);

/// Publish time, Unix **milliseconds** (13-digit) — see [updatedAt].
@override final  int updateTime;
 final  List<WeatherForecastPoint> _forecast;
@override List<WeatherForecastPoint> get forecast {
  if (_forecast is EqualUnmodifiableListView) return _forecast;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_forecast);
}


/// Create a copy of WeatherForecast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherForecastCopyWith<_WeatherForecast> get copyWith => __$WeatherForecastCopyWithImpl<_WeatherForecast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherForecastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherForecast&&(identical(other.updateTime, updateTime) || other.updateTime == updateTime)&&const DeepCollectionEquality().equals(other._forecast, _forecast));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updateTime,const DeepCollectionEquality().hash(_forecast));

@override
String toString() {
  return 'WeatherForecast(updateTime: $updateTime, forecast: $forecast)';
}


}

/// @nodoc
abstract mixin class _$WeatherForecastCopyWith<$Res> implements $WeatherForecastCopyWith<$Res> {
  factory _$WeatherForecastCopyWith(_WeatherForecast value, $Res Function(_WeatherForecast) _then) = __$WeatherForecastCopyWithImpl;
@override @useResult
$Res call({
 int updateTime, List<WeatherForecastPoint> forecast
});




}
/// @nodoc
class __$WeatherForecastCopyWithImpl<$Res>
    implements _$WeatherForecastCopyWith<$Res> {
  __$WeatherForecastCopyWithImpl(this._self, this._then);

  final _WeatherForecast _self;
  final $Res Function(_WeatherForecast) _then;

/// Create a copy of WeatherForecast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updateTime = null,Object? forecast = null,}) {
  return _then(_WeatherForecast(
updateTime: null == updateTime ? _self.updateTime : updateTime // ignore: cast_nullable_to_non_nullable
as int,forecast: null == forecast ? _self._forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<WeatherForecastPoint>,
  ));
}


}


/// @nodoc
mixin _$WeatherForecastPoint {

/// Clock label for this hour (`"HH:00"`, e.g. `"14:00"`).
 String get time;/// Forecast air temperature, °C.
 double get temperature;/// Forecast apparent ("feels-like") temperature, °C.
 double get apparentTemp;/// Forecast relative humidity, %.
 int get humidity;/// Human-readable weather text (e.g. `多雲`).
 String get weather;/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
 int get weatherCode;/// Probability of precipitation, %.
 int get pop; ForecastWind get wind;
/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherForecastPointCopyWith<WeatherForecastPoint> get copyWith => _$WeatherForecastPointCopyWithImpl<WeatherForecastPoint>(this as WeatherForecastPoint, _$identity);

  /// Serializes this WeatherForecastPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherForecastPoint&&(identical(other.time, time) || other.time == time)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.apparentTemp, apparentTemp) || other.apparentTemp == apparentTemp)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.pop, pop) || other.pop == pop)&&(identical(other.wind, wind) || other.wind == wind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,temperature,apparentTemp,humidity,weather,weatherCode,pop,wind);

@override
String toString() {
  return 'WeatherForecastPoint(time: $time, temperature: $temperature, apparentTemp: $apparentTemp, humidity: $humidity, weather: $weather, weatherCode: $weatherCode, pop: $pop, wind: $wind)';
}


}

/// @nodoc
abstract mixin class $WeatherForecastPointCopyWith<$Res>  {
  factory $WeatherForecastPointCopyWith(WeatherForecastPoint value, $Res Function(WeatherForecastPoint) _then) = _$WeatherForecastPointCopyWithImpl;
@useResult
$Res call({
 String time, double temperature, double apparentTemp, int humidity, String weather, int weatherCode, int pop, ForecastWind wind
});


$ForecastWindCopyWith<$Res> get wind;

}
/// @nodoc
class _$WeatherForecastPointCopyWithImpl<$Res>
    implements $WeatherForecastPointCopyWith<$Res> {
  _$WeatherForecastPointCopyWithImpl(this._self, this._then);

  final WeatherForecastPoint _self;
  final $Res Function(WeatherForecastPoint) _then;

/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? temperature = null,Object? apparentTemp = null,Object? humidity = null,Object? weather = null,Object? weatherCode = null,Object? pop = null,Object? wind = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,apparentTemp: null == apparentTemp ? _self.apparentTemp : apparentTemp // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int,weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,pop: null == pop ? _self.pop : pop // ignore: cast_nullable_to_non_nullable
as int,wind: null == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as ForecastWind,
  ));
}
/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ForecastWindCopyWith<$Res> get wind {
  
  return $ForecastWindCopyWith<$Res>(_self.wind, (value) {
    return _then(_self.copyWith(wind: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeatherForecastPoint].
extension WeatherForecastPointPatterns on WeatherForecastPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherForecastPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherForecastPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherForecastPoint value)  $default,){
final _that = this;
switch (_that) {
case _WeatherForecastPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherForecastPoint value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherForecastPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String time,  double temperature,  double apparentTemp,  int humidity,  String weather,  int weatherCode,  int pop,  ForecastWind wind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherForecastPoint() when $default != null:
return $default(_that.time,_that.temperature,_that.apparentTemp,_that.humidity,_that.weather,_that.weatherCode,_that.pop,_that.wind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String time,  double temperature,  double apparentTemp,  int humidity,  String weather,  int weatherCode,  int pop,  ForecastWind wind)  $default,) {final _that = this;
switch (_that) {
case _WeatherForecastPoint():
return $default(_that.time,_that.temperature,_that.apparentTemp,_that.humidity,_that.weather,_that.weatherCode,_that.pop,_that.wind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String time,  double temperature,  double apparentTemp,  int humidity,  String weather,  int weatherCode,  int pop,  ForecastWind wind)?  $default,) {final _that = this;
switch (_that) {
case _WeatherForecastPoint() when $default != null:
return $default(_that.time,_that.temperature,_that.apparentTemp,_that.humidity,_that.weather,_that.weatherCode,_that.pop,_that.wind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherForecastPoint implements WeatherForecastPoint {
  const _WeatherForecastPoint({required this.time, required this.temperature, required this.apparentTemp, required this.humidity, required this.weather, required this.weatherCode, required this.pop, required this.wind});
  factory _WeatherForecastPoint.fromJson(Map<String, dynamic> json) => _$WeatherForecastPointFromJson(json);

/// Clock label for this hour (`"HH:00"`, e.g. `"14:00"`).
@override final  String time;
/// Forecast air temperature, °C.
@override final  double temperature;
/// Forecast apparent ("feels-like") temperature, °C.
@override final  double apparentTemp;
/// Forecast relative humidity, %.
@override final  int humidity;
/// Human-readable weather text (e.g. `多雲`).
@override final  String weather;
/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
@override final  int weatherCode;
/// Probability of precipitation, %.
@override final  int pop;
@override final  ForecastWind wind;

/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherForecastPointCopyWith<_WeatherForecastPoint> get copyWith => __$WeatherForecastPointCopyWithImpl<_WeatherForecastPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherForecastPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherForecastPoint&&(identical(other.time, time) || other.time == time)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.apparentTemp, apparentTemp) || other.apparentTemp == apparentTemp)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.pop, pop) || other.pop == pop)&&(identical(other.wind, wind) || other.wind == wind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,temperature,apparentTemp,humidity,weather,weatherCode,pop,wind);

@override
String toString() {
  return 'WeatherForecastPoint(time: $time, temperature: $temperature, apparentTemp: $apparentTemp, humidity: $humidity, weather: $weather, weatherCode: $weatherCode, pop: $pop, wind: $wind)';
}


}

/// @nodoc
abstract mixin class _$WeatherForecastPointCopyWith<$Res> implements $WeatherForecastPointCopyWith<$Res> {
  factory _$WeatherForecastPointCopyWith(_WeatherForecastPoint value, $Res Function(_WeatherForecastPoint) _then) = __$WeatherForecastPointCopyWithImpl;
@override @useResult
$Res call({
 String time, double temperature, double apparentTemp, int humidity, String weather, int weatherCode, int pop, ForecastWind wind
});


@override $ForecastWindCopyWith<$Res> get wind;

}
/// @nodoc
class __$WeatherForecastPointCopyWithImpl<$Res>
    implements _$WeatherForecastPointCopyWith<$Res> {
  __$WeatherForecastPointCopyWithImpl(this._self, this._then);

  final _WeatherForecastPoint _self;
  final $Res Function(_WeatherForecastPoint) _then;

/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? temperature = null,Object? apparentTemp = null,Object? humidity = null,Object? weather = null,Object? weatherCode = null,Object? pop = null,Object? wind = null,}) {
  return _then(_WeatherForecastPoint(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,apparentTemp: null == apparentTemp ? _self.apparentTemp : apparentTemp // ignore: cast_nullable_to_non_nullable
as double,humidity: null == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int,weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,pop: null == pop ? _self.pop : pop // ignore: cast_nullable_to_non_nullable
as int,wind: null == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as ForecastWind,
  ));
}

/// Create a copy of WeatherForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ForecastWindCopyWith<$Res> get wind {
  
  return $ForecastWindCopyWith<$Res>(_self.wind, (value) {
    return _then(_self.copyWith(wind: value));
  });
}
}


/// @nodoc
mixin _$ForecastWind {

 String get direction; double get speed; int get beaufort;
/// Create a copy of ForecastWind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastWindCopyWith<ForecastWind> get copyWith => _$ForecastWindCopyWithImpl<ForecastWind>(this as ForecastWind, _$identity);

  /// Serializes this ForecastWind to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastWind&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.beaufort, beaufort) || other.beaufort == beaufort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,speed,beaufort);

@override
String toString() {
  return 'ForecastWind(direction: $direction, speed: $speed, beaufort: $beaufort)';
}


}

/// @nodoc
abstract mixin class $ForecastWindCopyWith<$Res>  {
  factory $ForecastWindCopyWith(ForecastWind value, $Res Function(ForecastWind) _then) = _$ForecastWindCopyWithImpl;
@useResult
$Res call({
 String direction, double speed, int beaufort
});




}
/// @nodoc
class _$ForecastWindCopyWithImpl<$Res>
    implements $ForecastWindCopyWith<$Res> {
  _$ForecastWindCopyWithImpl(this._self, this._then);

  final ForecastWind _self;
  final $Res Function(ForecastWind) _then;

/// Create a copy of ForecastWind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? speed = null,Object? beaufort = null,}) {
  return _then(_self.copyWith(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,beaufort: null == beaufort ? _self.beaufort : beaufort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ForecastWind].
extension ForecastWindPatterns on ForecastWind {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForecastWind value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForecastWind() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForecastWind value)  $default,){
final _that = this;
switch (_that) {
case _ForecastWind():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForecastWind value)?  $default,){
final _that = this;
switch (_that) {
case _ForecastWind() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String direction,  double speed,  int beaufort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForecastWind() when $default != null:
return $default(_that.direction,_that.speed,_that.beaufort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String direction,  double speed,  int beaufort)  $default,) {final _that = this;
switch (_that) {
case _ForecastWind():
return $default(_that.direction,_that.speed,_that.beaufort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String direction,  double speed,  int beaufort)?  $default,) {final _that = this;
switch (_that) {
case _ForecastWind() when $default != null:
return $default(_that.direction,_that.speed,_that.beaufort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ForecastWind implements ForecastWind {
  const _ForecastWind({required this.direction, required this.speed, required this.beaufort});
  factory _ForecastWind.fromJson(Map<String, dynamic> json) => _$ForecastWindFromJson(json);

@override final  String direction;
@override final  double speed;
@override final  int beaufort;

/// Create a copy of ForecastWind
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForecastWindCopyWith<_ForecastWind> get copyWith => __$ForecastWindCopyWithImpl<_ForecastWind>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ForecastWindToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForecastWind&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.beaufort, beaufort) || other.beaufort == beaufort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,speed,beaufort);

@override
String toString() {
  return 'ForecastWind(direction: $direction, speed: $speed, beaufort: $beaufort)';
}


}

/// @nodoc
abstract mixin class _$ForecastWindCopyWith<$Res> implements $ForecastWindCopyWith<$Res> {
  factory _$ForecastWindCopyWith(_ForecastWind value, $Res Function(_ForecastWind) _then) = __$ForecastWindCopyWithImpl;
@override @useResult
$Res call({
 String direction, double speed, int beaufort
});




}
/// @nodoc
class __$ForecastWindCopyWithImpl<$Res>
    implements _$ForecastWindCopyWith<$Res> {
  __$ForecastWindCopyWithImpl(this._self, this._then);

  final _ForecastWind _self;
  final $Res Function(_ForecastWind) _then;

/// Create a copy of ForecastWind
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? speed = null,Object? beaufort = null,}) {
  return _then(_ForecastWind(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,beaufort: null == beaufort ? _self.beaufort : beaufort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
