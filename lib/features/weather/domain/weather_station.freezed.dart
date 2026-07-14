// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_station.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherStation {

@JsonKey(name: 'n') String get name;@JsonKey(name: 'c') String get county;@JsonKey(name: 't') String get town;@JsonKey(name: 'alt') double get altitude;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;
/// Create a copy of WeatherStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherStationCopyWith<WeatherStation> get copyWith => _$WeatherStationCopyWithImpl<WeatherStation>(this as WeatherStation, _$identity);

  /// Serializes this WeatherStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherStation&&(identical(other.name, name) || other.name == name)&&(identical(other.county, county) || other.county == county)&&(identical(other.town, town) || other.town == town)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,county,town,altitude,latitude,longitude);

@override
String toString() {
  return 'WeatherStation(name: $name, county: $county, town: $town, altitude: $altitude, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $WeatherStationCopyWith<$Res>  {
  factory $WeatherStationCopyWith(WeatherStation value, $Res Function(WeatherStation) _then) = _$WeatherStationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'n') String name,@JsonKey(name: 'c') String county,@JsonKey(name: 't') String town,@JsonKey(name: 'alt') double altitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude
});




}
/// @nodoc
class _$WeatherStationCopyWithImpl<$Res>
    implements $WeatherStationCopyWith<$Res> {
  _$WeatherStationCopyWithImpl(this._self, this._then);

  final WeatherStation _self;
  final $Res Function(WeatherStation) _then;

/// Create a copy of WeatherStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? county = null,Object? town = null,Object? altitude = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,county: null == county ? _self.county : county // ignore: cast_nullable_to_non_nullable
as String,town: null == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherStation].
extension WeatherStationPatterns on WeatherStation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherStation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherStation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherStation value)  $default,){
final _that = this;
switch (_that) {
case _WeatherStation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherStation value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherStation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'n')  String name, @JsonKey(name: 'c')  String county, @JsonKey(name: 't')  String town, @JsonKey(name: 'alt')  double altitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherStation() when $default != null:
return $default(_that.name,_that.county,_that.town,_that.altitude,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'n')  String name, @JsonKey(name: 'c')  String county, @JsonKey(name: 't')  String town, @JsonKey(name: 'alt')  double altitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude)  $default,) {final _that = this;
switch (_that) {
case _WeatherStation():
return $default(_that.name,_that.county,_that.town,_that.altitude,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'n')  String name, @JsonKey(name: 'c')  String county, @JsonKey(name: 't')  String town, @JsonKey(name: 'alt')  double altitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _WeatherStation() when $default != null:
return $default(_that.name,_that.county,_that.town,_that.altitude,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeatherStation implements WeatherStation {
  const _WeatherStation({@JsonKey(name: 'n') required this.name, @JsonKey(name: 'c') required this.county, @JsonKey(name: 't') required this.town, @JsonKey(name: 'alt') required this.altitude, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude});
  factory _WeatherStation.fromJson(Map<String, dynamic> json) => _$WeatherStationFromJson(json);

@override@JsonKey(name: 'n') final  String name;
@override@JsonKey(name: 'c') final  String county;
@override@JsonKey(name: 't') final  String town;
@override@JsonKey(name: 'alt') final  double altitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;

/// Create a copy of WeatherStation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherStationCopyWith<_WeatherStation> get copyWith => __$WeatherStationCopyWithImpl<_WeatherStation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeatherStationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherStation&&(identical(other.name, name) || other.name == name)&&(identical(other.county, county) || other.county == county)&&(identical(other.town, town) || other.town == town)&&(identical(other.altitude, altitude) || other.altitude == altitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,county,town,altitude,latitude,longitude);

@override
String toString() {
  return 'WeatherStation(name: $name, county: $county, town: $town, altitude: $altitude, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$WeatherStationCopyWith<$Res> implements $WeatherStationCopyWith<$Res> {
  factory _$WeatherStationCopyWith(_WeatherStation value, $Res Function(_WeatherStation) _then) = __$WeatherStationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'n') String name,@JsonKey(name: 'c') String county,@JsonKey(name: 't') String town,@JsonKey(name: 'alt') double altitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude
});




}
/// @nodoc
class __$WeatherStationCopyWithImpl<$Res>
    implements _$WeatherStationCopyWith<$Res> {
  __$WeatherStationCopyWithImpl(this._self, this._then);

  final _WeatherStation _self;
  final $Res Function(_WeatherStation) _then;

/// Create a copy of WeatherStation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? county = null,Object? town = null,Object? altitude = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_WeatherStation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,county: null == county ? _self.county : county // ignore: cast_nullable_to_non_nullable
as String,town: null == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String,altitude: null == altitude ? _self.altitude : altitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
