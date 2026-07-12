// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eew.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Eew {

@JsonKey(name: 'author') String get agency; String get id; int get serial; int get status;@JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool) bool get isFinal;@JsonKey(name: 'eq') EewInfo get info;
/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EewCopyWith<Eew> get copyWith => _$EewCopyWithImpl<Eew>(this as Eew, _$identity);

  /// Serializes this Eew to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Eew&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.id, id) || other.id == id)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.status, status) || other.status == status)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agency,id,serial,status,isFinal,info);

@override
String toString() {
  return 'Eew(agency: $agency, id: $id, serial: $serial, status: $status, isFinal: $isFinal, info: $info)';
}


}

/// @nodoc
abstract mixin class $EewCopyWith<$Res>  {
  factory $EewCopyWith(Eew value, $Res Function(Eew) _then) = _$EewCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'author') String agency, String id, int serial, int status,@JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool) bool isFinal,@JsonKey(name: 'eq') EewInfo info
});


$EewInfoCopyWith<$Res> get info;

}
/// @nodoc
class _$EewCopyWithImpl<$Res>
    implements $EewCopyWith<$Res> {
  _$EewCopyWithImpl(this._self, this._then);

  final Eew _self;
  final $Res Function(Eew) _then;

/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agency = null,Object? id = null,Object? serial = null,Object? status = null,Object? isFinal = null,Object? info = null,}) {
  return _then(_self.copyWith(
agency: null == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as EewInfo,
  ));
}
/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EewInfoCopyWith<$Res> get info {
  
  return $EewInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// Adds pattern-matching-related methods to [Eew].
extension EewPatterns on Eew {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Eew value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Eew() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Eew value)  $default,){
final _that = this;
switch (_that) {
case _Eew():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Eew value)?  $default,){
final _that = this;
switch (_that) {
case _Eew() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'author')  String agency,  String id,  int serial,  int status, @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool)  bool isFinal, @JsonKey(name: 'eq')  EewInfo info)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Eew() when $default != null:
return $default(_that.agency,_that.id,_that.serial,_that.status,_that.isFinal,_that.info);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'author')  String agency,  String id,  int serial,  int status, @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool)  bool isFinal, @JsonKey(name: 'eq')  EewInfo info)  $default,) {final _that = this;
switch (_that) {
case _Eew():
return $default(_that.agency,_that.id,_that.serial,_that.status,_that.isFinal,_that.info);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'author')  String agency,  String id,  int serial,  int status, @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool)  bool isFinal, @JsonKey(name: 'eq')  EewInfo info)?  $default,) {final _that = this;
switch (_that) {
case _Eew() when $default != null:
return $default(_that.agency,_that.id,_that.serial,_that.status,_that.isFinal,_that.info);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Eew implements Eew {
  const _Eew({@JsonKey(name: 'author') required this.agency, required this.id, required this.serial, required this.status, @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool) required this.isFinal, @JsonKey(name: 'eq') required this.info});
  factory _Eew.fromJson(Map<String, dynamic> json) => _$EewFromJson(json);

@override@JsonKey(name: 'author') final  String agency;
@override final  String id;
@override final  int serial;
@override final  int status;
@override@JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool) final  bool isFinal;
@override@JsonKey(name: 'eq') final  EewInfo info;

/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EewCopyWith<_Eew> get copyWith => __$EewCopyWithImpl<_Eew>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Eew&&(identical(other.agency, agency) || other.agency == agency)&&(identical(other.id, id) || other.id == id)&&(identical(other.serial, serial) || other.serial == serial)&&(identical(other.status, status) || other.status == status)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,agency,id,serial,status,isFinal,info);

@override
String toString() {
  return 'Eew(agency: $agency, id: $id, serial: $serial, status: $status, isFinal: $isFinal, info: $info)';
}


}

/// @nodoc
abstract mixin class _$EewCopyWith<$Res> implements $EewCopyWith<$Res> {
  factory _$EewCopyWith(_Eew value, $Res Function(_Eew) _then) = __$EewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'author') String agency, String id, int serial, int status,@JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool) bool isFinal,@JsonKey(name: 'eq') EewInfo info
});


@override $EewInfoCopyWith<$Res> get info;

}
/// @nodoc
class __$EewCopyWithImpl<$Res>
    implements _$EewCopyWith<$Res> {
  __$EewCopyWithImpl(this._self, this._then);

  final _Eew _self;
  final $Res Function(_Eew) _then;

/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agency = null,Object? id = null,Object? serial = null,Object? status = null,Object? isFinal = null,Object? info = null,}) {
  return _then(_Eew(
agency: null == agency ? _self.agency : agency // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serial: null == serial ? _self.serial : serial // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as int,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as EewInfo,
  ));
}

/// Create a copy of Eew
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EewInfoCopyWith<$Res> get info {
  
  return $EewInfoCopyWith<$Res>(_self.info, (value) {
    return _then(_self.copyWith(info: value));
  });
}
}


/// @nodoc
mixin _$EewInfo {

 int get time;@JsonKey(name: 'lon') double get longitude;@JsonKey(name: 'lat') double get latitude; double get depth;@JsonKey(name: 'mag') double get magnitude;@JsonKey(name: 'loc') String get location; int get max;
/// Create a copy of EewInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EewInfoCopyWith<EewInfo> get copyWith => _$EewInfoCopyWithImpl<EewInfo>(this as EewInfo, _$identity);

  /// Serializes this EewInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EewInfo&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,longitude,latitude,depth,magnitude,location,max);

@override
String toString() {
  return 'EewInfo(time: $time, longitude: $longitude, latitude: $latitude, depth: $depth, magnitude: $magnitude, location: $location, max: $max)';
}


}

/// @nodoc
abstract mixin class $EewInfoCopyWith<$Res>  {
  factory $EewInfoCopyWith(EewInfo value, $Res Function(EewInfo) _then) = _$EewInfoCopyWithImpl;
@useResult
$Res call({
 int time,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude, double depth,@JsonKey(name: 'mag') double magnitude,@JsonKey(name: 'loc') String location, int max
});




}
/// @nodoc
class _$EewInfoCopyWithImpl<$Res>
    implements $EewInfoCopyWith<$Res> {
  _$EewInfoCopyWithImpl(this._self, this._then);

  final EewInfo _self;
  final $Res Function(EewInfo) _then;

/// Create a copy of EewInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? longitude = null,Object? latitude = null,Object? depth = null,Object? magnitude = null,Object? location = null,Object? max = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EewInfo].
extension EewInfoPatterns on EewInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EewInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EewInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EewInfo value)  $default,){
final _that = this;
switch (_that) {
case _EewInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EewInfo value)?  $default,){
final _that = this;
switch (_that) {
case _EewInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'loc')  String location,  int max)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EewInfo() when $default != null:
return $default(_that.time,_that.longitude,_that.latitude,_that.depth,_that.magnitude,_that.location,_that.max);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'loc')  String location,  int max)  $default,) {final _that = this;
switch (_that) {
case _EewInfo():
return $default(_that.time,_that.longitude,_that.latitude,_that.depth,_that.magnitude,_that.location,_that.max);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'loc')  String location,  int max)?  $default,) {final _that = this;
switch (_that) {
case _EewInfo() when $default != null:
return $default(_that.time,_that.longitude,_that.latitude,_that.depth,_that.magnitude,_that.location,_that.max);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EewInfo extends EewInfo {
  const _EewInfo({required this.time, @JsonKey(name: 'lon') required this.longitude, @JsonKey(name: 'lat') required this.latitude, required this.depth, @JsonKey(name: 'mag') required this.magnitude, @JsonKey(name: 'loc') required this.location, required this.max}): super._();
  factory _EewInfo.fromJson(Map<String, dynamic> json) => _$EewInfoFromJson(json);

@override final  int time;
@override@JsonKey(name: 'lon') final  double longitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override final  double depth;
@override@JsonKey(name: 'mag') final  double magnitude;
@override@JsonKey(name: 'loc') final  String location;
@override final  int max;

/// Create a copy of EewInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EewInfoCopyWith<_EewInfo> get copyWith => __$EewInfoCopyWithImpl<_EewInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EewInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EewInfo&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.max, max) || other.max == max));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,longitude,latitude,depth,magnitude,location,max);

@override
String toString() {
  return 'EewInfo(time: $time, longitude: $longitude, latitude: $latitude, depth: $depth, magnitude: $magnitude, location: $location, max: $max)';
}


}

/// @nodoc
abstract mixin class _$EewInfoCopyWith<$Res> implements $EewInfoCopyWith<$Res> {
  factory _$EewInfoCopyWith(_EewInfo value, $Res Function(_EewInfo) _then) = __$EewInfoCopyWithImpl;
@override @useResult
$Res call({
 int time,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude, double depth,@JsonKey(name: 'mag') double magnitude,@JsonKey(name: 'loc') String location, int max
});




}
/// @nodoc
class __$EewInfoCopyWithImpl<$Res>
    implements _$EewInfoCopyWith<$Res> {
  __$EewInfoCopyWithImpl(this._self, this._then);

  final _EewInfo _self;
  final $Res Function(_EewInfo) _then;

/// Create a copy of EewInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? longitude = null,Object? latitude = null,Object? depth = null,Object? magnitude = null,Object? location = null,Object? max = null,}) {
  return _then(_EewInfo(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
