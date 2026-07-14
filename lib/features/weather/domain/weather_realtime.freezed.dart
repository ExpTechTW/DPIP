// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_realtime.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherRealtime {

/// Full 6-char station code (the `/station` directory key).
 String get id; WeatherRealtimeStation get station;/// Observation time, Unix seconds.
 int get time; WeatherRealtimeData get data;
/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherRealtimeCopyWith<WeatherRealtime> get copyWith => _$WeatherRealtimeCopyWithImpl<WeatherRealtime>(this as WeatherRealtime, _$identity);

  /// Serializes this WeatherRealtime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherRealtime&&(identical(other.id, id) || other.id == id)&&(identical(other.station, station) || other.station == station)&&(identical(other.time, time) || other.time == time)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,station,time,data);

@override
String toString() {
  return 'WeatherRealtime(id: $id, station: $station, time: $time, data: $data)';
}


}

/// @nodoc
abstract mixin class $WeatherRealtimeCopyWith<$Res>  {
  factory $WeatherRealtimeCopyWith(WeatherRealtime value, $Res Function(WeatherRealtime) _then) = _$WeatherRealtimeCopyWithImpl;
@useResult
$Res call({
 String id, WeatherRealtimeStation station, int time, WeatherRealtimeData data
});


$WeatherRealtimeStationCopyWith<$Res> get station;$WeatherRealtimeDataCopyWith<$Res> get data;

}
/// @nodoc
class _$WeatherRealtimeCopyWithImpl<$Res>
    implements $WeatherRealtimeCopyWith<$Res> {
  _$WeatherRealtimeCopyWithImpl(this._self, this._then);

  final WeatherRealtime _self;
  final $Res Function(WeatherRealtime) _then;

/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? station = null,Object? time = null,Object? data = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as WeatherRealtimeStation,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as WeatherRealtimeData,
  ));
}
/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherRealtimeStationCopyWith<$Res> get station {
  
  return $WeatherRealtimeStationCopyWith<$Res>(_self.station, (value) {
    return _then(_self.copyWith(station: value));
  });
}/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherRealtimeDataCopyWith<$Res> get data {
  
  return $WeatherRealtimeDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeatherRealtime].
extension WeatherRealtimePatterns on WeatherRealtime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherRealtime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherRealtime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherRealtime value)  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherRealtime value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  WeatherRealtimeStation station,  int time,  WeatherRealtimeData data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherRealtime() when $default != null:
return $default(_that.id,_that.station,_that.time,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  WeatherRealtimeStation station,  int time,  WeatherRealtimeData data)  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtime():
return $default(_that.id,_that.station,_that.time,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  WeatherRealtimeStation station,  int time,  WeatherRealtimeData data)?  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtime() when $default != null:
return $default(_that.id,_that.station,_that.time,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherRealtime implements WeatherRealtime {
  const _WeatherRealtime({required this.id, required this.station, required this.time, required this.data});
  factory _WeatherRealtime.fromJson(Map<String, dynamic> json) => _$WeatherRealtimeFromJson(json);

/// Full 6-char station code (the `/station` directory key).
@override final  String id;
@override final  WeatherRealtimeStation station;
/// Observation time, Unix seconds.
@override final  int time;
@override final  WeatherRealtimeData data;

/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherRealtimeCopyWith<_WeatherRealtime> get copyWith => __$WeatherRealtimeCopyWithImpl<_WeatherRealtime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherRealtimeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherRealtime&&(identical(other.id, id) || other.id == id)&&(identical(other.station, station) || other.station == station)&&(identical(other.time, time) || other.time == time)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,station,time,data);

@override
String toString() {
  return 'WeatherRealtime(id: $id, station: $station, time: $time, data: $data)';
}


}

/// @nodoc
abstract mixin class _$WeatherRealtimeCopyWith<$Res> implements $WeatherRealtimeCopyWith<$Res> {
  factory _$WeatherRealtimeCopyWith(_WeatherRealtime value, $Res Function(_WeatherRealtime) _then) = __$WeatherRealtimeCopyWithImpl;
@override @useResult
$Res call({
 String id, WeatherRealtimeStation station, int time, WeatherRealtimeData data
});


@override $WeatherRealtimeStationCopyWith<$Res> get station;@override $WeatherRealtimeDataCopyWith<$Res> get data;

}
/// @nodoc
class __$WeatherRealtimeCopyWithImpl<$Res>
    implements _$WeatherRealtimeCopyWith<$Res> {
  __$WeatherRealtimeCopyWithImpl(this._self, this._then);

  final _WeatherRealtime _self;
  final $Res Function(_WeatherRealtime) _then;

/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? station = null,Object? time = null,Object? data = null,}) {
  return _then(_WeatherRealtime(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as WeatherRealtimeStation,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as WeatherRealtimeData,
  ));
}

/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherRealtimeStationCopyWith<$Res> get station {
  
  return $WeatherRealtimeStationCopyWith<$Res>(_self.station, (value) {
    return _then(_self.copyWith(station: value));
  });
}/// Create a copy of WeatherRealtime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherRealtimeDataCopyWith<$Res> get data {
  
  return $WeatherRealtimeDataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$WeatherRealtimeStation {

 String get name;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;/// Station altitude, metres.
 double get altitude;/// Great-circle distance from the query coordinate, kilometres.
 double get distance;
/// Create a copy of WeatherRealtimeStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherRealtimeStationCopyWith<WeatherRealtimeStation> get copyWith => _$WeatherRealtimeStationCopyWithImpl<WeatherRealtimeStation>(this as WeatherRealtimeStation, _$identity);

  /// Serializes this WeatherRealtimeStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherRealtimeStation&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,latitude,longitude,altitude,distance);

@override
String toString() {
  return 'WeatherRealtimeStation(name: $name, latitude: $latitude, longitude: $longitude, altitude: $altitude, distance: $distance)';
}


}

/// @nodoc
abstract mixin class $WeatherRealtimeStationCopyWith<$Res>  {
  factory $WeatherRealtimeStationCopyWith(WeatherRealtimeStation value, $Res Function(WeatherRealtimeStation) _then) = _$WeatherRealtimeStationCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double altitude, double distance
});




}
/// @nodoc
class _$WeatherRealtimeStationCopyWithImpl<$Res>
    implements $WeatherRealtimeStationCopyWith<$Res> {
  _$WeatherRealtimeStationCopyWithImpl(this._self, this._then);

  final WeatherRealtimeStation _self;
  final $Res Function(WeatherRealtimeStation) _then;

/// Create a copy of WeatherRealtimeStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? latitude = null,Object? longitude = null,Object? altitude = null,Object? distance = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as double,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherRealtimeStation].
extension WeatherRealtimeStationPatterns on WeatherRealtimeStation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherRealtimeStation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherRealtimeStation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherRealtimeStation value)  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtimeStation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherRealtimeStation value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtimeStation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double altitude,  double distance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherRealtimeStation() when $default != null:
return $default(_that.name,_that.latitude,_that.longitude,_that.altitude,_that.distance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double altitude,  double distance)  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtimeStation():
return $default(_that.name,_that.latitude,_that.longitude,_that.altitude,_that.distance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double altitude,  double distance)?  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtimeStation() when $default != null:
return $default(_that.name,_that.latitude,_that.longitude,_that.altitude,_that.distance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherRealtimeStation implements WeatherRealtimeStation {
  const _WeatherRealtimeStation({required this.name, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude, required this.altitude, required this.distance});
  factory _WeatherRealtimeStation.fromJson(Map<String, dynamic> json) => _$WeatherRealtimeStationFromJson(json);

@override final  String name;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;
/// Station altitude, metres.
@override final  double altitude;
/// Great-circle distance from the query coordinate, kilometres.
@override final  double distance;

/// Create a copy of WeatherRealtimeStation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherRealtimeStationCopyWith<_WeatherRealtimeStation> get copyWith => __$WeatherRealtimeStationCopyWithImpl<_WeatherRealtimeStation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherRealtimeStationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherRealtimeStation&&(identical(other.name, name) || other.name == name)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.distance, distance) || other.distance == distance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,latitude,longitude,altitude,distance);

@override
String toString() {
  return 'WeatherRealtimeStation(name: $name, latitude: $latitude, longitude: $longitude, altitude: $altitude, distance: $distance)';
}


}

/// @nodoc
abstract mixin class _$WeatherRealtimeStationCopyWith<$Res> implements $WeatherRealtimeStationCopyWith<$Res> {
  factory _$WeatherRealtimeStationCopyWith(_WeatherRealtimeStation value, $Res Function(_WeatherRealtimeStation) _then) = __$WeatherRealtimeStationCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double altitude, double distance
});




}
/// @nodoc
class __$WeatherRealtimeStationCopyWithImpl<$Res>
    implements _$WeatherRealtimeStationCopyWith<$Res> {
  __$WeatherRealtimeStationCopyWithImpl(this._self, this._then);

  final _WeatherRealtimeStation _self;
  final $Res Function(_WeatherRealtimeStation) _then;

/// Create a copy of WeatherRealtimeStation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? latitude = null,Object? longitude = null,Object? altitude = null,Object? distance = null,}) {
  return _then(_WeatherRealtimeStation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as double,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$WeatherRealtimeData {

/// Human-readable weather text (e.g. `多雲`).
 String get weather;/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
 int get weatherCode;@JsonKey(fromJson: MeteorDecode.real) double? get temperature;@JsonKey(fromJson: MeteorDecode.integer) int? get humidity;/// Rolling 1-hour rainfall, mm.
@JsonKey(fromJson: MeteorDecode.real) double? get rain; WeatherWind get wind; WeatherWind get gust;@JsonKey(fromJson: MeteorDecode.real) double? get visibility;@JsonKey(name: 'visibility_text') String? get visibilityText;@JsonKey(fromJson: MeteorDecode.real) double? get pressure;/// Accumulated sunshine, hours.
@JsonKey(fromJson: MeteorDecode.real) double? get sunshine;
/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherRealtimeDataCopyWith<WeatherRealtimeData> get copyWith => _$WeatherRealtimeDataCopyWithImpl<WeatherRealtimeData>(this as WeatherRealtimeData, _$identity);

  /// Serializes this WeatherRealtimeData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherRealtimeData&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.rain, rain) || other.rain == rain)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.visibilityText, visibilityText) || other.visibilityText == visibilityText)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.sunshine, sunshine) || other.sunshine == sunshine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weather,weatherCode,temperature,humidity,rain,wind,gust,visibility,visibilityText,pressure,sunshine);

@override
String toString() {
  return 'WeatherRealtimeData(weather: $weather, weatherCode: $weatherCode, temperature: $temperature, humidity: $humidity, rain: $rain, wind: $wind, gust: $gust, visibility: $visibility, visibilityText: $visibilityText, pressure: $pressure, sunshine: $sunshine)';
}


}

/// @nodoc
abstract mixin class $WeatherRealtimeDataCopyWith<$Res>  {
  factory $WeatherRealtimeDataCopyWith(WeatherRealtimeData value, $Res Function(WeatherRealtimeData) _then) = _$WeatherRealtimeDataCopyWithImpl;
@useResult
$Res call({
 String weather, int weatherCode,@JsonKey(fromJson: MeteorDecode.real) double? temperature,@JsonKey(fromJson: MeteorDecode.integer) int? humidity,@JsonKey(fromJson: MeteorDecode.real) double? rain, WeatherWind wind, WeatherWind gust,@JsonKey(fromJson: MeteorDecode.real) double? visibility,@JsonKey(name: 'visibility_text') String? visibilityText,@JsonKey(fromJson: MeteorDecode.real) double? pressure,@JsonKey(fromJson: MeteorDecode.real) double? sunshine
});


$WeatherWindCopyWith<$Res> get wind;$WeatherWindCopyWith<$Res> get gust;

}
/// @nodoc
class _$WeatherRealtimeDataCopyWithImpl<$Res>
    implements $WeatherRealtimeDataCopyWith<$Res> {
  _$WeatherRealtimeDataCopyWithImpl(this._self, this._then);

  final WeatherRealtimeData _self;
  final $Res Function(WeatherRealtimeData) _then;

/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weather = null,Object? weatherCode = null,Object? temperature = freezed,Object? humidity = freezed,Object? rain = freezed,Object? wind = null,Object? gust = null,Object? visibility = freezed,Object? visibilityText = freezed,Object? pressure = freezed,Object? sunshine = freezed,}) {
  return _then(_self.copyWith(
weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int?,rain: freezed == rain ? _self.rain : rain // ignore: cast_nullable_to_non_nullable
as double?,wind: null == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as WeatherWind,gust: null == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as WeatherWind,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as double?,visibilityText: freezed == visibilityText ? _self.visibilityText : visibilityText // ignore: cast_nullable_to_non_nullable
as String?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,sunshine: freezed == sunshine ? _self.sunshine : sunshine // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherWindCopyWith<$Res> get wind {
  
  return $WeatherWindCopyWith<$Res>(_self.wind, (value) {
    return _then(_self.copyWith(wind: value));
  });
}/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherWindCopyWith<$Res> get gust {
  
  return $WeatherWindCopyWith<$Res>(_self.gust, (value) {
    return _then(_self.copyWith(gust: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeatherRealtimeData].
extension WeatherRealtimeDataPatterns on WeatherRealtimeData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherRealtimeData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherRealtimeData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherRealtimeData value)  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtimeData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherRealtimeData value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherRealtimeData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weather,  int weatherCode, @JsonKey(fromJson: MeteorDecode.real)  double? temperature, @JsonKey(fromJson: MeteorDecode.integer)  int? humidity, @JsonKey(fromJson: MeteorDecode.real)  double? rain,  WeatherWind wind,  WeatherWind gust, @JsonKey(fromJson: MeteorDecode.real)  double? visibility, @JsonKey(name: 'visibility_text')  String? visibilityText, @JsonKey(fromJson: MeteorDecode.real)  double? pressure, @JsonKey(fromJson: MeteorDecode.real)  double? sunshine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherRealtimeData() when $default != null:
return $default(_that.weather,_that.weatherCode,_that.temperature,_that.humidity,_that.rain,_that.wind,_that.gust,_that.visibility,_that.visibilityText,_that.pressure,_that.sunshine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weather,  int weatherCode, @JsonKey(fromJson: MeteorDecode.real)  double? temperature, @JsonKey(fromJson: MeteorDecode.integer)  int? humidity, @JsonKey(fromJson: MeteorDecode.real)  double? rain,  WeatherWind wind,  WeatherWind gust, @JsonKey(fromJson: MeteorDecode.real)  double? visibility, @JsonKey(name: 'visibility_text')  String? visibilityText, @JsonKey(fromJson: MeteorDecode.real)  double? pressure, @JsonKey(fromJson: MeteorDecode.real)  double? sunshine)  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtimeData():
return $default(_that.weather,_that.weatherCode,_that.temperature,_that.humidity,_that.rain,_that.wind,_that.gust,_that.visibility,_that.visibilityText,_that.pressure,_that.sunshine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weather,  int weatherCode, @JsonKey(fromJson: MeteorDecode.real)  double? temperature, @JsonKey(fromJson: MeteorDecode.integer)  int? humidity, @JsonKey(fromJson: MeteorDecode.real)  double? rain,  WeatherWind wind,  WeatherWind gust, @JsonKey(fromJson: MeteorDecode.real)  double? visibility, @JsonKey(name: 'visibility_text')  String? visibilityText, @JsonKey(fromJson: MeteorDecode.real)  double? pressure, @JsonKey(fromJson: MeteorDecode.real)  double? sunshine)?  $default,) {final _that = this;
switch (_that) {
case _WeatherRealtimeData() when $default != null:
return $default(_that.weather,_that.weatherCode,_that.temperature,_that.humidity,_that.rain,_that.wind,_that.gust,_that.visibility,_that.visibilityText,_that.pressure,_that.sunshine);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherRealtimeData implements WeatherRealtimeData {
  const _WeatherRealtimeData({required this.weather, required this.weatherCode, @JsonKey(fromJson: MeteorDecode.real) this.temperature, @JsonKey(fromJson: MeteorDecode.integer) this.humidity, @JsonKey(fromJson: MeteorDecode.real) this.rain, required this.wind, required this.gust, @JsonKey(fromJson: MeteorDecode.real) this.visibility, @JsonKey(name: 'visibility_text') this.visibilityText, @JsonKey(fromJson: MeteorDecode.real) this.pressure, @JsonKey(fromJson: MeteorDecode.real) this.sunshine});
  factory _WeatherRealtimeData.fromJson(Map<String, dynamic> json) => _$WeatherRealtimeDataFromJson(json);

/// Human-readable weather text (e.g. `多雲`).
@override final  String weather;
/// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
@override final  int weatherCode;
@override@JsonKey(fromJson: MeteorDecode.real) final  double? temperature;
@override@JsonKey(fromJson: MeteorDecode.integer) final  int? humidity;
/// Rolling 1-hour rainfall, mm.
@override@JsonKey(fromJson: MeteorDecode.real) final  double? rain;
@override final  WeatherWind wind;
@override final  WeatherWind gust;
@override@JsonKey(fromJson: MeteorDecode.real) final  double? visibility;
@override@JsonKey(name: 'visibility_text') final  String? visibilityText;
@override@JsonKey(fromJson: MeteorDecode.real) final  double? pressure;
/// Accumulated sunshine, hours.
@override@JsonKey(fromJson: MeteorDecode.real) final  double? sunshine;

/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherRealtimeDataCopyWith<_WeatherRealtimeData> get copyWith => __$WeatherRealtimeDataCopyWithImpl<_WeatherRealtimeData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherRealtimeDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherRealtimeData&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.weatherCode, weatherCode) || other.weatherCode == weatherCode)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.humidity, humidity) || other.humidity == humidity)&&(identical(other.rain, rain) || other.rain == rain)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.visibilityText, visibilityText) || other.visibilityText == visibilityText)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.sunshine, sunshine) || other.sunshine == sunshine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weather,weatherCode,temperature,humidity,rain,wind,gust,visibility,visibilityText,pressure,sunshine);

@override
String toString() {
  return 'WeatherRealtimeData(weather: $weather, weatherCode: $weatherCode, temperature: $temperature, humidity: $humidity, rain: $rain, wind: $wind, gust: $gust, visibility: $visibility, visibilityText: $visibilityText, pressure: $pressure, sunshine: $sunshine)';
}


}

/// @nodoc
abstract mixin class _$WeatherRealtimeDataCopyWith<$Res> implements $WeatherRealtimeDataCopyWith<$Res> {
  factory _$WeatherRealtimeDataCopyWith(_WeatherRealtimeData value, $Res Function(_WeatherRealtimeData) _then) = __$WeatherRealtimeDataCopyWithImpl;
@override @useResult
$Res call({
 String weather, int weatherCode,@JsonKey(fromJson: MeteorDecode.real) double? temperature,@JsonKey(fromJson: MeteorDecode.integer) int? humidity,@JsonKey(fromJson: MeteorDecode.real) double? rain, WeatherWind wind, WeatherWind gust,@JsonKey(fromJson: MeteorDecode.real) double? visibility,@JsonKey(name: 'visibility_text') String? visibilityText,@JsonKey(fromJson: MeteorDecode.real) double? pressure,@JsonKey(fromJson: MeteorDecode.real) double? sunshine
});


@override $WeatherWindCopyWith<$Res> get wind;@override $WeatherWindCopyWith<$Res> get gust;

}
/// @nodoc
class __$WeatherRealtimeDataCopyWithImpl<$Res>
    implements _$WeatherRealtimeDataCopyWith<$Res> {
  __$WeatherRealtimeDataCopyWithImpl(this._self, this._then);

  final _WeatherRealtimeData _self;
  final $Res Function(_WeatherRealtimeData) _then;

/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weather = null,Object? weatherCode = null,Object? temperature = freezed,Object? humidity = freezed,Object? rain = freezed,Object? wind = null,Object? gust = null,Object? visibility = freezed,Object? visibilityText = freezed,Object? pressure = freezed,Object? sunshine = freezed,}) {
  return _then(_WeatherRealtimeData(
weather: null == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as String,weatherCode: null == weatherCode ? _self.weatherCode : weatherCode // ignore: cast_nullable_to_non_nullable
as int,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double?,humidity: freezed == humidity ? _self.humidity : humidity // ignore: cast_nullable_to_non_nullable
as int?,rain: freezed == rain ? _self.rain : rain // ignore: cast_nullable_to_non_nullable
as double?,wind: null == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as WeatherWind,gust: null == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as WeatherWind,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as double?,visibilityText: freezed == visibilityText ? _self.visibilityText : visibilityText // ignore: cast_nullable_to_non_nullable
as String?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,sunshine: freezed == sunshine ? _self.sunshine : sunshine // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherWindCopyWith<$Res> get wind {
  
  return $WeatherWindCopyWith<$Res>(_self.wind, (value) {
    return _then(_self.copyWith(wind: value));
  });
}/// Create a copy of WeatherRealtimeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeatherWindCopyWith<$Res> get gust {
  
  return $WeatherWindCopyWith<$Res>(_self.gust, (value) {
    return _then(_self.copyWith(gust: value));
  });
}
}


/// @nodoc
mixin _$WeatherWind {

 String? get direction;@JsonKey(fromJson: MeteorDecode.real) double? get speed;@JsonKey(fromJson: MeteorDecode.integer) int? get beaufort;
/// Create a copy of WeatherWind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherWindCopyWith<WeatherWind> get copyWith => _$WeatherWindCopyWithImpl<WeatherWind>(this as WeatherWind, _$identity);

  /// Serializes this WeatherWind to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherWind&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.beaufort, beaufort) || other.beaufort == beaufort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,speed,beaufort);

@override
String toString() {
  return 'WeatherWind(direction: $direction, speed: $speed, beaufort: $beaufort)';
}


}

/// @nodoc
abstract mixin class $WeatherWindCopyWith<$Res>  {
  factory $WeatherWindCopyWith(WeatherWind value, $Res Function(WeatherWind) _then) = _$WeatherWindCopyWithImpl;
@useResult
$Res call({
 String? direction,@JsonKey(fromJson: MeteorDecode.real) double? speed,@JsonKey(fromJson: MeteorDecode.integer) int? beaufort
});




}
/// @nodoc
class _$WeatherWindCopyWithImpl<$Res>
    implements $WeatherWindCopyWith<$Res> {
  _$WeatherWindCopyWithImpl(this._self, this._then);

  final WeatherWind _self;
  final $Res Function(WeatherWind) _then;

/// Create a copy of WeatherWind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = freezed,Object? speed = freezed,Object? beaufort = freezed,}) {
  return _then(_self.copyWith(
direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,beaufort: freezed == beaufort ? _self.beaufort : beaufort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherWind].
extension WeatherWindPatterns on WeatherWind {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherWind value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherWind() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherWind value)  $default,){
final _that = this;
switch (_that) {
case _WeatherWind():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherWind value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherWind() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? direction, @JsonKey(fromJson: MeteorDecode.real)  double? speed, @JsonKey(fromJson: MeteorDecode.integer)  int? beaufort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherWind() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? direction, @JsonKey(fromJson: MeteorDecode.real)  double? speed, @JsonKey(fromJson: MeteorDecode.integer)  int? beaufort)  $default,) {final _that = this;
switch (_that) {
case _WeatherWind():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? direction, @JsonKey(fromJson: MeteorDecode.real)  double? speed, @JsonKey(fromJson: MeteorDecode.integer)  int? beaufort)?  $default,) {final _that = this;
switch (_that) {
case _WeatherWind() when $default != null:
return $default(_that.direction,_that.speed,_that.beaufort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherWind implements WeatherWind {
  const _WeatherWind({this.direction, @JsonKey(fromJson: MeteorDecode.real) this.speed, @JsonKey(fromJson: MeteorDecode.integer) this.beaufort});
  factory _WeatherWind.fromJson(Map<String, dynamic> json) => _$WeatherWindFromJson(json);

@override final  String? direction;
@override@JsonKey(fromJson: MeteorDecode.real) final  double? speed;
@override@JsonKey(fromJson: MeteorDecode.integer) final  int? beaufort;

/// Create a copy of WeatherWind
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherWindCopyWith<_WeatherWind> get copyWith => __$WeatherWindCopyWithImpl<_WeatherWind>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherWindToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherWind&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.beaufort, beaufort) || other.beaufort == beaufort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,direction,speed,beaufort);

@override
String toString() {
  return 'WeatherWind(direction: $direction, speed: $speed, beaufort: $beaufort)';
}


}

/// @nodoc
abstract mixin class _$WeatherWindCopyWith<$Res> implements $WeatherWindCopyWith<$Res> {
  factory _$WeatherWindCopyWith(_WeatherWind value, $Res Function(_WeatherWind) _then) = __$WeatherWindCopyWithImpl;
@override @useResult
$Res call({
 String? direction,@JsonKey(fromJson: MeteorDecode.real) double? speed,@JsonKey(fromJson: MeteorDecode.integer) int? beaufort
});




}
/// @nodoc
class __$WeatherWindCopyWithImpl<$Res>
    implements _$WeatherWindCopyWith<$Res> {
  __$WeatherWindCopyWithImpl(this._self, this._then);

  final _WeatherWind _self;
  final $Res Function(_WeatherWind) _then;

/// Create a copy of WeatherWind
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = freezed,Object? speed = freezed,Object? beaufort = freezed,}) {
  return _then(_WeatherWind(
direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,beaufort: freezed == beaufort ? _self.beaufort : beaufort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
