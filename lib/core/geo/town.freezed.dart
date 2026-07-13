// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'town.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Town {

 String get code; String get city; String get town; double get lat; double get lng; String get cityLevel; String get townLevel;
/// Create a copy of Town
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TownCopyWith<Town> get copyWith => _$TownCopyWithImpl<Town>(this as Town, _$identity);

  /// Serializes this Town to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Town&&(identical(other.code, code) || other.code == code)&&(identical(other.city, city) || other.city == city)&&(identical(other.town, town) || other.town == town)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.cityLevel, cityLevel) || other.cityLevel == cityLevel)&&(identical(other.townLevel, townLevel) || other.townLevel == townLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,city,town,lat,lng,cityLevel,townLevel);

@override
String toString() {
  return 'Town(code: $code, city: $city, town: $town, lat: $lat, lng: $lng, cityLevel: $cityLevel, townLevel: $townLevel)';
}


}

/// @nodoc
abstract mixin class $TownCopyWith<$Res>  {
  factory $TownCopyWith(Town value, $Res Function(Town) _then) = _$TownCopyWithImpl;
@useResult
$Res call({
 String code, String city, String town, double lat, double lng, String cityLevel, String townLevel
});




}
/// @nodoc
class _$TownCopyWithImpl<$Res>
    implements $TownCopyWith<$Res> {
  _$TownCopyWithImpl(this._self, this._then);

  final Town _self;
  final $Res Function(Town) _then;

/// Create a copy of Town
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? city = null,Object? town = null,Object? lat = null,Object? lng = null,Object? cityLevel = null,Object? townLevel = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,town: null == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,cityLevel: null == cityLevel ? _self.cityLevel : cityLevel // ignore: cast_nullable_to_non_nullable
as String,townLevel: null == townLevel ? _self.townLevel : townLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Town].
extension TownPatterns on Town {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Town value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Town() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Town value)  $default,){
final _that = this;
switch (_that) {
case _Town():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Town value)?  $default,){
final _that = this;
switch (_that) {
case _Town() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String city,  String town,  double lat,  double lng,  String cityLevel,  String townLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Town() when $default != null:
return $default(_that.code,_that.city,_that.town,_that.lat,_that.lng,_that.cityLevel,_that.townLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String city,  String town,  double lat,  double lng,  String cityLevel,  String townLevel)  $default,) {final _that = this;
switch (_that) {
case _Town():
return $default(_that.code,_that.city,_that.town,_that.lat,_that.lng,_that.cityLevel,_that.townLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String city,  String town,  double lat,  double lng,  String cityLevel,  String townLevel)?  $default,) {final _that = this;
switch (_that) {
case _Town() when $default != null:
return $default(_that.code,_that.city,_that.town,_that.lat,_that.lng,_that.cityLevel,_that.townLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Town extends Town {
  const _Town({required this.code, required this.city, required this.town, required this.lat, required this.lng, required this.cityLevel, required this.townLevel}): super._();
  factory _Town.fromJson(Map<String, dynamic> json) => _$TownFromJson(json);

@override final  String code;
@override final  String city;
@override final  String town;
@override final  double lat;
@override final  double lng;
@override final  String cityLevel;
@override final  String townLevel;

/// Create a copy of Town
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TownCopyWith<_Town> get copyWith => __$TownCopyWithImpl<_Town>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TownToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Town&&(identical(other.code, code) || other.code == code)&&(identical(other.city, city) || other.city == city)&&(identical(other.town, town) || other.town == town)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.cityLevel, cityLevel) || other.cityLevel == cityLevel)&&(identical(other.townLevel, townLevel) || other.townLevel == townLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,city,town,lat,lng,cityLevel,townLevel);

@override
String toString() {
  return 'Town(code: $code, city: $city, town: $town, lat: $lat, lng: $lng, cityLevel: $cityLevel, townLevel: $townLevel)';
}


}

/// @nodoc
abstract mixin class _$TownCopyWith<$Res> implements $TownCopyWith<$Res> {
  factory _$TownCopyWith(_Town value, $Res Function(_Town) _then) = __$TownCopyWithImpl;
@override @useResult
$Res call({
 String code, String city, String town, double lat, double lng, String cityLevel, String townLevel
});




}
/// @nodoc
class __$TownCopyWithImpl<$Res>
    implements _$TownCopyWith<$Res> {
  __$TownCopyWithImpl(this._self, this._then);

  final _Town _self;
  final $Res Function(_Town) _then;

/// Create a copy of Town
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? city = null,Object? town = null,Object? lat = null,Object? lng = null,Object? cityLevel = null,Object? townLevel = null,}) {
  return _then(_Town(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,town: null == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,cityLevel: null == cityLevel ? _self.cityLevel : cityLevel // ignore: cast_nullable_to_non_nullable
as String,townLevel: null == townLevel ? _self.townLevel : townLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
