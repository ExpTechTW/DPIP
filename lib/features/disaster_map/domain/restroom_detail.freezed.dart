// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restroom_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RestroomDetail {

 String get name; String get address; double get latitude; double get longitude; int get type; int get type2; int get typegrade;
/// Create a copy of RestroomDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RestroomDetailCopyWith<RestroomDetail> get copyWith => _$RestroomDetailCopyWithImpl<RestroomDetail>(this as RestroomDetail, _$identity);

  /// Serializes this RestroomDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RestroomDetail&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.type, type) || other.type == type)&&(identical(other.type2, type2) || other.type2 == type2)&&(identical(other.typegrade, typegrade) || other.typegrade == typegrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,type,type2,typegrade);

@override
String toString() {
  return 'RestroomDetail(name: $name, address: $address, latitude: $latitude, longitude: $longitude, type: $type, type2: $type2, typegrade: $typegrade)';
}


}

/// @nodoc
abstract mixin class $RestroomDetailCopyWith<$Res>  {
  factory $RestroomDetailCopyWith(RestroomDetail value, $Res Function(RestroomDetail) _then) = _$RestroomDetailCopyWithImpl;
@useResult
$Res call({
 String name, String address, double latitude, double longitude, int type, int type2, int typegrade
});




}
/// @nodoc
class _$RestroomDetailCopyWithImpl<$Res>
    implements $RestroomDetailCopyWith<$Res> {
  _$RestroomDetailCopyWithImpl(this._self, this._then);

  final RestroomDetail _self;
  final $Res Function(RestroomDetail) _then;

/// Create a copy of RestroomDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? type = null,Object? type2 = null,Object? typegrade = null,}) {
  return _then(RestroomDetail(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,type2: null == type2 ? _self.type2 : type2 // ignore: cast_nullable_to_non_nullable
as int,typegrade: null == typegrade ? _self.typegrade : typegrade // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RestroomDetail].
extension RestroomDetailPatterns on RestroomDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RestroomDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RestroomDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RestroomDetail value)  $default,){
final _that = this;
switch (_that) {
case _RestroomDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RestroomDetail value)?  $default,){
final _that = this;
switch (_that) {
case _RestroomDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String address,  double latitude,  double longitude,  int type,  int type2,  int typegrade)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RestroomDetail() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.type,_that.type2,_that.typegrade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String address,  double latitude,  double longitude,  int type,  int type2,  int typegrade)  $default,) {final _that = this;
switch (_that) {
case _RestroomDetail():
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.type,_that.type2,_that.typegrade);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String address,  double latitude,  double longitude,  int type,  int type2,  int typegrade)?  $default,) {final _that = this;
switch (_that) {
case _RestroomDetail() when $default != null:
return $default(_that.name,_that.address,_that.latitude,_that.longitude,_that.type,_that.type2,_that.typegrade);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RestroomDetail implements RestroomDetail {
  const _RestroomDetail({this.name = '', this.address = '', this.latitude = 0, this.longitude = 0, this.type = 0, this.type2 = 0, this.typegrade = 0});
  factory _RestroomDetail.fromJson(Map<String, dynamic> json) => _$RestroomDetailFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String address;
@override@JsonKey() final  double latitude;
@override@JsonKey() final  double longitude;
@override@JsonKey() final  int type;
@override@JsonKey() final  int type2;
@override@JsonKey() final  int typegrade;

/// Create a copy of RestroomDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RestroomDetailCopyWith<_RestroomDetail> get copyWith => __$RestroomDetailCopyWithImpl<_RestroomDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RestroomDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RestroomDetail&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.type, type) || other.type == type)&&(identical(other.type2, type2) || other.type2 == type2)&&(identical(other.typegrade, typegrade) || other.typegrade == typegrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,latitude,longitude,type,type2,typegrade);

@override
String toString() {
  return 'RestroomDetail(name: $name, address: $address, latitude: $latitude, longitude: $longitude, type: $type, type2: $type2, typegrade: $typegrade)';
}


}

/// @nodoc
abstract mixin class _$RestroomDetailCopyWith<$Res> implements $RestroomDetailCopyWith<$Res> {
  factory _$RestroomDetailCopyWith(_RestroomDetail value, $Res Function(_RestroomDetail) _then) = __$RestroomDetailCopyWithImpl;
@override @useResult
$Res call({
 String name, String address, double latitude, double longitude, int type, int type2, int typegrade
});




}
/// @nodoc
class __$RestroomDetailCopyWithImpl<$Res>
    implements _$RestroomDetailCopyWith<$Res> {
  __$RestroomDetailCopyWithImpl(this._self, this._then);

  final _RestroomDetail _self;
  final $Res Function(_RestroomDetail) _then;

/// Create a copy of RestroomDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? type = null,Object? type2 = null,Object? typegrade = null,}) {
  return _then(_RestroomDetail(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as int,type2: null == type2 ? _self.type2 : type2 // ignore: cast_nullable_to_non_nullable
as int,typegrade: null == typegrade ? _self.typegrade : typegrade // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
