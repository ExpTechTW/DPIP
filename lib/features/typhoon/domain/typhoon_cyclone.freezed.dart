// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typhoon_cyclone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TyphoonCyclone {

/// International name (e.g. `HAISHEN`); a code like `TD11` when unnamed.
 String get name;/// CWA Chinese name (e.g. 海神); null before naming.
 String? get cwaName; int get year;/// Tropical-depression number.
 String? get tdNo;/// Typhoon number.
 String? get tyNo;/// Latest fix time (Unix seconds).
@JsonKey(name: 't') int get time;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;/// Sustained wind (m/s).
 double? get wind;/// Gust (m/s).
 double? get gust;/// Central pressure (hPa).
@JsonKey(name: 'pres') double? get pressure;/// Translation speed (km/hr).
 double? get speed;/// Translation heading (e.g. `WNW`).
@JsonKey(name: 'dir') String? get direction;
/// Create a copy of TyphoonCyclone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TyphoonCycloneCopyWith<TyphoonCyclone> get copyWith => _$TyphoonCycloneCopyWithImpl<TyphoonCyclone>(this as TyphoonCyclone, _$identity);

  /// Serializes this TyphoonCyclone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TyphoonCyclone&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.year, year) || other.year == year)&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.tyNo, tyNo) || other.tyNo == tyNo)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cwaName,year,tdNo,tyNo,time,latitude,longitude,wind,gust,pressure,speed,direction);

@override
String toString() {
  return 'TyphoonCyclone(name: $name, cwaName: $cwaName, year: $year, tdNo: $tdNo, tyNo: $tyNo, time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, speed: $speed, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $TyphoonCycloneCopyWith<$Res>  {
  factory $TyphoonCycloneCopyWith(TyphoonCyclone value, $Res Function(TyphoonCyclone) _then) = _$TyphoonCycloneCopyWithImpl;
@useResult
$Res call({
 String name, String? cwaName, int year, String? tdNo, String? tyNo,@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? speed,@JsonKey(name: 'dir') String? direction
});




}
/// @nodoc
class _$TyphoonCycloneCopyWithImpl<$Res>
    implements $TyphoonCycloneCopyWith<$Res> {
  _$TyphoonCycloneCopyWithImpl(this._self, this._then);

  final TyphoonCyclone _self;
  final $Res Function(TyphoonCyclone) _then;

/// Create a copy of TyphoonCyclone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? cwaName = freezed,Object? year = null,Object? tdNo = freezed,Object? tyNo = freezed,Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? speed = freezed,Object? direction = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,tyNo: freezed == tyNo ? _self.tyNo : tyNo // ignore: cast_nullable_to_non_nullable
as String?,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TyphoonCyclone].
extension TyphoonCyclonePatterns on TyphoonCyclone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TyphoonCyclone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TyphoonCyclone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TyphoonCyclone value)  $default,){
final _that = this;
switch (_that) {
case _TyphoonCyclone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TyphoonCyclone value)?  $default,){
final _that = this;
switch (_that) {
case _TyphoonCyclone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TyphoonCyclone() when $default != null:
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction)  $default,) {final _that = this;
switch (_that) {
case _TyphoonCyclone():
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? cwaName,  int year,  String? tdNo,  String? tyNo, @JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? speed, @JsonKey(name: 'dir')  String? direction)?  $default,) {final _that = this;
switch (_that) {
case _TyphoonCyclone() when $default != null:
return $default(_that.name,_that.cwaName,_that.year,_that.tdNo,_that.tyNo,_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.speed,_that.direction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TyphoonCyclone implements TyphoonCyclone {
  const _TyphoonCyclone({required this.name, this.cwaName, required this.year, this.tdNo, this.tyNo, @JsonKey(name: 't') required this.time, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude, this.wind, this.gust, @JsonKey(name: 'pres') this.pressure, this.speed, @JsonKey(name: 'dir') this.direction});
  factory _TyphoonCyclone.fromJson(Map<String, dynamic> json) => _$TyphoonCycloneFromJson(json);

/// International name (e.g. `HAISHEN`); a code like `TD11` when unnamed.
@override final  String name;
/// CWA Chinese name (e.g. 海神); null before naming.
@override final  String? cwaName;
@override final  int year;
/// Tropical-depression number.
@override final  String? tdNo;
/// Typhoon number.
@override final  String? tyNo;
/// Latest fix time (Unix seconds).
@override@JsonKey(name: 't') final  int time;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;
/// Sustained wind (m/s).
@override final  double? wind;
/// Gust (m/s).
@override final  double? gust;
/// Central pressure (hPa).
@override@JsonKey(name: 'pres') final  double? pressure;
/// Translation speed (km/hr).
@override final  double? speed;
/// Translation heading (e.g. `WNW`).
@override@JsonKey(name: 'dir') final  String? direction;

/// Create a copy of TyphoonCyclone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TyphoonCycloneCopyWith<_TyphoonCyclone> get copyWith => __$TyphoonCycloneCopyWithImpl<_TyphoonCyclone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TyphoonCycloneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TyphoonCyclone&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.year, year) || other.year == year)&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.tyNo, tyNo) || other.tyNo == tyNo)&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,cwaName,year,tdNo,tyNo,time,latitude,longitude,wind,gust,pressure,speed,direction);

@override
String toString() {
  return 'TyphoonCyclone(name: $name, cwaName: $cwaName, year: $year, tdNo: $tdNo, tyNo: $tyNo, time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, speed: $speed, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$TyphoonCycloneCopyWith<$Res> implements $TyphoonCycloneCopyWith<$Res> {
  factory _$TyphoonCycloneCopyWith(_TyphoonCyclone value, $Res Function(_TyphoonCyclone) _then) = __$TyphoonCycloneCopyWithImpl;
@override @useResult
$Res call({
 String name, String? cwaName, int year, String? tdNo, String? tyNo,@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? speed,@JsonKey(name: 'dir') String? direction
});




}
/// @nodoc
class __$TyphoonCycloneCopyWithImpl<$Res>
    implements _$TyphoonCycloneCopyWith<$Res> {
  __$TyphoonCycloneCopyWithImpl(this._self, this._then);

  final _TyphoonCyclone _self;
  final $Res Function(_TyphoonCyclone) _then;

/// Create a copy of TyphoonCyclone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? cwaName = freezed,Object? year = null,Object? tdNo = freezed,Object? tyNo = freezed,Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? speed = freezed,Object? direction = freezed,}) {
  return _then(_TyphoonCyclone(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,tyNo: freezed == tyNo ? _self.tyNo : tyNo // ignore: cast_nullable_to_non_nullable
as String?,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CycloneIndex {

 int get updated; List<TyphoonCyclone> get cyclones;
/// Create a copy of CycloneIndex
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CycloneIndexCopyWith<CycloneIndex> get copyWith => _$CycloneIndexCopyWithImpl<CycloneIndex>(this as CycloneIndex, _$identity);

  /// Serializes this CycloneIndex to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CycloneIndex&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other.cyclones, cyclones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(cyclones));

@override
String toString() {
  return 'CycloneIndex(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class $CycloneIndexCopyWith<$Res>  {
  factory $CycloneIndexCopyWith(CycloneIndex value, $Res Function(CycloneIndex) _then) = _$CycloneIndexCopyWithImpl;
@useResult
$Res call({
 int updated, List<TyphoonCyclone> cyclones
});




}
/// @nodoc
class _$CycloneIndexCopyWithImpl<$Res>
    implements $CycloneIndexCopyWith<$Res> {
  _$CycloneIndexCopyWithImpl(this._self, this._then);

  final CycloneIndex _self;
  final $Res Function(CycloneIndex) _then;

/// Create a copy of CycloneIndex
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_self.copyWith(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self.cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonCyclone>,
  ));
}

}


/// Adds pattern-matching-related methods to [CycloneIndex].
extension CycloneIndexPatterns on CycloneIndex {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CycloneIndex value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CycloneIndex() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CycloneIndex value)  $default,){
final _that = this;
switch (_that) {
case _CycloneIndex():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CycloneIndex value)?  $default,){
final _that = this;
switch (_that) {
case _CycloneIndex() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updated,  List<TyphoonCyclone> cyclones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CycloneIndex() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updated,  List<TyphoonCyclone> cyclones)  $default,) {final _that = this;
switch (_that) {
case _CycloneIndex():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updated,  List<TyphoonCyclone> cyclones)?  $default,) {final _that = this;
switch (_that) {
case _CycloneIndex() when $default != null:
return $default(_that.updated,_that.cyclones);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CycloneIndex implements CycloneIndex {
  const _CycloneIndex({required this.updated, required final  List<TyphoonCyclone> cyclones}): _cyclones = cyclones;
  factory _CycloneIndex.fromJson(Map<String, dynamic> json) => _$CycloneIndexFromJson(json);

@override final  int updated;
 final  List<TyphoonCyclone> _cyclones;
@override List<TyphoonCyclone> get cyclones {
  if (_cyclones is EqualUnmodifiableListView) return _cyclones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cyclones);
}


/// Create a copy of CycloneIndex
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CycloneIndexCopyWith<_CycloneIndex> get copyWith => __$CycloneIndexCopyWithImpl<_CycloneIndex>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CycloneIndexToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CycloneIndex&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other._cyclones, _cyclones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(_cyclones));

@override
String toString() {
  return 'CycloneIndex(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class _$CycloneIndexCopyWith<$Res> implements $CycloneIndexCopyWith<$Res> {
  factory _$CycloneIndexCopyWith(_CycloneIndex value, $Res Function(_CycloneIndex) _then) = __$CycloneIndexCopyWithImpl;
@override @useResult
$Res call({
 int updated, List<TyphoonCyclone> cyclones
});




}
/// @nodoc
class __$CycloneIndexCopyWithImpl<$Res>
    implements _$CycloneIndexCopyWith<$Res> {
  __$CycloneIndexCopyWithImpl(this._self, this._then);

  final _CycloneIndex _self;
  final $Res Function(_CycloneIndex) _then;

/// Create a copy of CycloneIndex
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_CycloneIndex(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self._cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonCyclone>,
  ));
}


}

// dart format on
