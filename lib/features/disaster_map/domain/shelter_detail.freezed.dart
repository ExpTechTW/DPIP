// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelter_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShelterDetail {

 int get id; String get name; int get capacity; List<String> get category; bool get indoor; bool get outdoor;@JsonKey(name: 'vulnerable_ok') bool get vulnerableOk; double get lat; double get lng; String get address;
/// Create a copy of ShelterDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelterDetailCopyWith<ShelterDetail> get copyWith => _$ShelterDetailCopyWithImpl<ShelterDetail>(this as ShelterDetail, _$identity);

  /// Serializes this ShelterDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelterDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other.category, category)&&(identical(other.indoor, indoor) || other.indoor == indoor)&&(identical(other.outdoor, outdoor) || other.outdoor == outdoor)&&(identical(other.vulnerableOk, vulnerableOk) || other.vulnerableOk == vulnerableOk)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,capacity,const DeepCollectionEquality().hash(category),indoor,outdoor,vulnerableOk,lat,lng,address);

@override
String toString() {
  return 'ShelterDetail(id: $id, name: $name, capacity: $capacity, category: $category, indoor: $indoor, outdoor: $outdoor, vulnerableOk: $vulnerableOk, lat: $lat, lng: $lng, address: $address)';
}


}

/// @nodoc
abstract mixin class $ShelterDetailCopyWith<$Res>  {
  factory $ShelterDetailCopyWith(ShelterDetail value, $Res Function(ShelterDetail) _then) = _$ShelterDetailCopyWithImpl;
@useResult
$Res call({
 int id, String name, int capacity, List<String> category, bool indoor, bool outdoor,@JsonKey(name: 'vulnerable_ok') bool vulnerableOk, double lat, double lng, String address
});




}
/// @nodoc
class _$ShelterDetailCopyWithImpl<$Res>
    implements $ShelterDetailCopyWith<$Res> {
  _$ShelterDetailCopyWithImpl(this._self, this._then);

  final ShelterDetail _self;
  final $Res Function(ShelterDetail) _then;

/// Create a copy of ShelterDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? capacity = null,Object? category = null,Object? indoor = null,Object? outdoor = null,Object? vulnerableOk = null,Object? lat = null,Object? lng = null,Object? address = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as List<String>,indoor: null == indoor ? _self.indoor : indoor // ignore: cast_nullable_to_non_nullable
as bool,outdoor: null == outdoor ? _self.outdoor : outdoor // ignore: cast_nullable_to_non_nullable
as bool,vulnerableOk: null == vulnerableOk ? _self.vulnerableOk : vulnerableOk // ignore: cast_nullable_to_non_nullable
as bool,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShelterDetail].
extension ShelterDetailPatterns on ShelterDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShelterDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShelterDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShelterDetail value)  $default,){
final _that = this;
switch (_that) {
case _ShelterDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShelterDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ShelterDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int capacity,  List<String> category,  bool indoor,  bool outdoor, @JsonKey(name: 'vulnerable_ok')  bool vulnerableOk,  double lat,  double lng,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShelterDetail() when $default != null:
return $default(_that.id,_that.name,_that.capacity,_that.category,_that.indoor,_that.outdoor,_that.vulnerableOk,_that.lat,_that.lng,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int capacity,  List<String> category,  bool indoor,  bool outdoor, @JsonKey(name: 'vulnerable_ok')  bool vulnerableOk,  double lat,  double lng,  String address)  $default,) {final _that = this;
switch (_that) {
case _ShelterDetail():
return $default(_that.id,_that.name,_that.capacity,_that.category,_that.indoor,_that.outdoor,_that.vulnerableOk,_that.lat,_that.lng,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int capacity,  List<String> category,  bool indoor,  bool outdoor, @JsonKey(name: 'vulnerable_ok')  bool vulnerableOk,  double lat,  double lng,  String address)?  $default,) {final _that = this;
switch (_that) {
case _ShelterDetail() when $default != null:
return $default(_that.id,_that.name,_that.capacity,_that.category,_that.indoor,_that.outdoor,_that.vulnerableOk,_that.lat,_that.lng,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShelterDetail implements ShelterDetail {
  const _ShelterDetail({this.id = 0, this.name = '', this.capacity = 0, final  List<String> category = const <String>[], this.indoor = false, this.outdoor = false, @JsonKey(name: 'vulnerable_ok') this.vulnerableOk = false, this.lat = 0, this.lng = 0, this.address = ''}): _category = category;
  factory _ShelterDetail.fromJson(Map<String, dynamic> json) => _$ShelterDetailFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String name;
@override@JsonKey() final  int capacity;
 final  List<String> _category;
@override@JsonKey() List<String> get category {
  if (_category is EqualUnmodifiableListView) return _category;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_category);
}

@override@JsonKey() final  bool indoor;
@override@JsonKey() final  bool outdoor;
@override@JsonKey(name: 'vulnerable_ok') final  bool vulnerableOk;
@override@JsonKey() final  double lat;
@override@JsonKey() final  double lng;
@override@JsonKey() final  String address;

/// Create a copy of ShelterDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShelterDetailCopyWith<_ShelterDetail> get copyWith => __$ShelterDetailCopyWithImpl<_ShelterDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShelterDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShelterDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other._category, _category)&&(identical(other.indoor, indoor) || other.indoor == indoor)&&(identical(other.outdoor, outdoor) || other.outdoor == outdoor)&&(identical(other.vulnerableOk, vulnerableOk) || other.vulnerableOk == vulnerableOk)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,capacity,const DeepCollectionEquality().hash(_category),indoor,outdoor,vulnerableOk,lat,lng,address);

@override
String toString() {
  return 'ShelterDetail(id: $id, name: $name, capacity: $capacity, category: $category, indoor: $indoor, outdoor: $outdoor, vulnerableOk: $vulnerableOk, lat: $lat, lng: $lng, address: $address)';
}


}

/// @nodoc
abstract mixin class _$ShelterDetailCopyWith<$Res> implements $ShelterDetailCopyWith<$Res> {
  factory _$ShelterDetailCopyWith(_ShelterDetail value, $Res Function(_ShelterDetail) _then) = __$ShelterDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int capacity, List<String> category, bool indoor, bool outdoor,@JsonKey(name: 'vulnerable_ok') bool vulnerableOk, double lat, double lng, String address
});




}
/// @nodoc
class __$ShelterDetailCopyWithImpl<$Res>
    implements _$ShelterDetailCopyWith<$Res> {
  __$ShelterDetailCopyWithImpl(this._self, this._then);

  final _ShelterDetail _self;
  final $Res Function(_ShelterDetail) _then;

/// Create a copy of ShelterDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? capacity = null,Object? category = null,Object? indoor = null,Object? outdoor = null,Object? vulnerableOk = null,Object? lat = null,Object? lng = null,Object? address = null,}) {
  return _then(_ShelterDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self._category : category // ignore: cast_nullable_to_non_nullable
as List<String>,indoor: null == indoor ? _self.indoor : indoor // ignore: cast_nullable_to_non_nullable
as bool,outdoor: null == outdoor ? _self.outdoor : outdoor // ignore: cast_nullable_to_non_nullable
as bool,vulnerableOk: null == vulnerableOk ? _self.vulnerableOk : vulnerableOk // ignore: cast_nullable_to_non_nullable
as bool,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
