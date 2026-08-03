// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aed_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AedDetail {

 int get id;@JsonKey(name: 'aed_id') String get aedId; String get name; String get city; String get district; String get category; String get type; String get place; double get lat; double get lng; String get address; String get description;@JsonKey(name: 'place_desc') String get placeDesc;@JsonKey(name: 'weekday_start') String get weekdayStart;@JsonKey(name: 'weekday_end') String get weekdayEnd;@JsonKey(name: 'saturday_start') String get saturdayStart;@JsonKey(name: 'saturday_end') String get saturdayEnd;@JsonKey(name: 'sunday_start') String get sundayStart;@JsonKey(name: 'sunday_end') String get sundayEnd;@JsonKey(name: 'open_remark') String get openRemark;@JsonKey(name: 'emergency_phone') String get emergencyPhone;@JsonKey(name: 'place_id') String get placeId;
/// Create a copy of AedDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AedDetailCopyWith<AedDetail> get copyWith => _$AedDetailCopyWithImpl<AedDetail>(this as AedDetail, _$identity);

  /// Serializes this AedDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AedDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.aedId, aedId) || other.aedId == aedId)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.district, district) || other.district == district)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.place, place) || other.place == place)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.placeDesc, placeDesc) || other.placeDesc == placeDesc)&&(identical(other.weekdayStart, weekdayStart) || other.weekdayStart == weekdayStart)&&(identical(other.weekdayEnd, weekdayEnd) || other.weekdayEnd == weekdayEnd)&&(identical(other.saturdayStart, saturdayStart) || other.saturdayStart == saturdayStart)&&(identical(other.saturdayEnd, saturdayEnd) || other.saturdayEnd == saturdayEnd)&&(identical(other.sundayStart, sundayStart) || other.sundayStart == sundayStart)&&(identical(other.sundayEnd, sundayEnd) || other.sundayEnd == sundayEnd)&&(identical(other.openRemark, openRemark) || other.openRemark == openRemark)&&(identical(other.emergencyPhone, emergencyPhone) || other.emergencyPhone == emergencyPhone)&&(identical(other.placeId, placeId) || other.placeId == placeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,aedId,name,city,district,category,type,place,lat,lng,address,description,placeDesc,weekdayStart,weekdayEnd,saturdayStart,saturdayEnd,sundayStart,sundayEnd,openRemark,emergencyPhone,placeId]);

@override
String toString() {
  return 'AedDetail(id: $id, aedId: $aedId, name: $name, city: $city, district: $district, category: $category, type: $type, place: $place, lat: $lat, lng: $lng, address: $address, description: $description, placeDesc: $placeDesc, weekdayStart: $weekdayStart, weekdayEnd: $weekdayEnd, saturdayStart: $saturdayStart, saturdayEnd: $saturdayEnd, sundayStart: $sundayStart, sundayEnd: $sundayEnd, openRemark: $openRemark, emergencyPhone: $emergencyPhone, placeId: $placeId)';
}


}

/// @nodoc
abstract mixin class $AedDetailCopyWith<$Res>  {
  factory $AedDetailCopyWith(AedDetail value, $Res Function(AedDetail) _then) = _$AedDetailCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'aed_id') String aedId, String name, String city, String district, String category, String type, String place, double lat, double lng, String address, String description,@JsonKey(name: 'place_desc') String placeDesc,@JsonKey(name: 'weekday_start') String weekdayStart,@JsonKey(name: 'weekday_end') String weekdayEnd,@JsonKey(name: 'saturday_start') String saturdayStart,@JsonKey(name: 'saturday_end') String saturdayEnd,@JsonKey(name: 'sunday_start') String sundayStart,@JsonKey(name: 'sunday_end') String sundayEnd,@JsonKey(name: 'open_remark') String openRemark,@JsonKey(name: 'emergency_phone') String emergencyPhone,@JsonKey(name: 'place_id') String placeId
});




}
/// @nodoc
class _$AedDetailCopyWithImpl<$Res>
    implements $AedDetailCopyWith<$Res> {
  _$AedDetailCopyWithImpl(this._self, this._then);

  final AedDetail _self;
  final $Res Function(AedDetail) _then;

/// Create a copy of AedDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? aedId = null,Object? name = null,Object? city = null,Object? district = null,Object? category = null,Object? type = null,Object? place = null,Object? lat = null,Object? lng = null,Object? address = null,Object? description = null,Object? placeDesc = null,Object? weekdayStart = null,Object? weekdayEnd = null,Object? saturdayStart = null,Object? saturdayEnd = null,Object? sundayStart = null,Object? sundayEnd = null,Object? openRemark = null,Object? emergencyPhone = null,Object? placeId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,aedId: null == aedId ? _self.aedId : aedId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,placeDesc: null == placeDesc ? _self.placeDesc : placeDesc // ignore: cast_nullable_to_non_nullable
as String,weekdayStart: null == weekdayStart ? _self.weekdayStart : weekdayStart // ignore: cast_nullable_to_non_nullable
as String,weekdayEnd: null == weekdayEnd ? _self.weekdayEnd : weekdayEnd // ignore: cast_nullable_to_non_nullable
as String,saturdayStart: null == saturdayStart ? _self.saturdayStart : saturdayStart // ignore: cast_nullable_to_non_nullable
as String,saturdayEnd: null == saturdayEnd ? _self.saturdayEnd : saturdayEnd // ignore: cast_nullable_to_non_nullable
as String,sundayStart: null == sundayStart ? _self.sundayStart : sundayStart // ignore: cast_nullable_to_non_nullable
as String,sundayEnd: null == sundayEnd ? _self.sundayEnd : sundayEnd // ignore: cast_nullable_to_non_nullable
as String,openRemark: null == openRemark ? _self.openRemark : openRemark // ignore: cast_nullable_to_non_nullable
as String,emergencyPhone: null == emergencyPhone ? _self.emergencyPhone : emergencyPhone // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AedDetail].
extension AedDetailPatterns on AedDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AedDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AedDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AedDetail value)  $default,){
final _that = this;
switch (_that) {
case _AedDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AedDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AedDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'aed_id')  String aedId,  String name,  String city,  String district,  String category,  String type,  String place,  double lat,  double lng,  String address,  String description, @JsonKey(name: 'place_desc')  String placeDesc, @JsonKey(name: 'weekday_start')  String weekdayStart, @JsonKey(name: 'weekday_end')  String weekdayEnd, @JsonKey(name: 'saturday_start')  String saturdayStart, @JsonKey(name: 'saturday_end')  String saturdayEnd, @JsonKey(name: 'sunday_start')  String sundayStart, @JsonKey(name: 'sunday_end')  String sundayEnd, @JsonKey(name: 'open_remark')  String openRemark, @JsonKey(name: 'emergency_phone')  String emergencyPhone, @JsonKey(name: 'place_id')  String placeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AedDetail() when $default != null:
return $default(_that.id,_that.aedId,_that.name,_that.city,_that.district,_that.category,_that.type,_that.place,_that.lat,_that.lng,_that.address,_that.description,_that.placeDesc,_that.weekdayStart,_that.weekdayEnd,_that.saturdayStart,_that.saturdayEnd,_that.sundayStart,_that.sundayEnd,_that.openRemark,_that.emergencyPhone,_that.placeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'aed_id')  String aedId,  String name,  String city,  String district,  String category,  String type,  String place,  double lat,  double lng,  String address,  String description, @JsonKey(name: 'place_desc')  String placeDesc, @JsonKey(name: 'weekday_start')  String weekdayStart, @JsonKey(name: 'weekday_end')  String weekdayEnd, @JsonKey(name: 'saturday_start')  String saturdayStart, @JsonKey(name: 'saturday_end')  String saturdayEnd, @JsonKey(name: 'sunday_start')  String sundayStart, @JsonKey(name: 'sunday_end')  String sundayEnd, @JsonKey(name: 'open_remark')  String openRemark, @JsonKey(name: 'emergency_phone')  String emergencyPhone, @JsonKey(name: 'place_id')  String placeId)  $default,) {final _that = this;
switch (_that) {
case _AedDetail():
return $default(_that.id,_that.aedId,_that.name,_that.city,_that.district,_that.category,_that.type,_that.place,_that.lat,_that.lng,_that.address,_that.description,_that.placeDesc,_that.weekdayStart,_that.weekdayEnd,_that.saturdayStart,_that.saturdayEnd,_that.sundayStart,_that.sundayEnd,_that.openRemark,_that.emergencyPhone,_that.placeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'aed_id')  String aedId,  String name,  String city,  String district,  String category,  String type,  String place,  double lat,  double lng,  String address,  String description, @JsonKey(name: 'place_desc')  String placeDesc, @JsonKey(name: 'weekday_start')  String weekdayStart, @JsonKey(name: 'weekday_end')  String weekdayEnd, @JsonKey(name: 'saturday_start')  String saturdayStart, @JsonKey(name: 'saturday_end')  String saturdayEnd, @JsonKey(name: 'sunday_start')  String sundayStart, @JsonKey(name: 'sunday_end')  String sundayEnd, @JsonKey(name: 'open_remark')  String openRemark, @JsonKey(name: 'emergency_phone')  String emergencyPhone, @JsonKey(name: 'place_id')  String placeId)?  $default,) {final _that = this;
switch (_that) {
case _AedDetail() when $default != null:
return $default(_that.id,_that.aedId,_that.name,_that.city,_that.district,_that.category,_that.type,_that.place,_that.lat,_that.lng,_that.address,_that.description,_that.placeDesc,_that.weekdayStart,_that.weekdayEnd,_that.saturdayStart,_that.saturdayEnd,_that.sundayStart,_that.sundayEnd,_that.openRemark,_that.emergencyPhone,_that.placeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AedDetail implements AedDetail {
  const _AedDetail({required this.id, @JsonKey(name: 'aed_id') required this.aedId, required this.name, this.city = '', this.district = '', this.category = '', this.type = '', this.place = '', required this.lat, required this.lng, this.address = '', this.description = '', @JsonKey(name: 'place_desc') this.placeDesc = '', @JsonKey(name: 'weekday_start') this.weekdayStart = '', @JsonKey(name: 'weekday_end') this.weekdayEnd = '', @JsonKey(name: 'saturday_start') this.saturdayStart = '', @JsonKey(name: 'saturday_end') this.saturdayEnd = '', @JsonKey(name: 'sunday_start') this.sundayStart = '', @JsonKey(name: 'sunday_end') this.sundayEnd = '', @JsonKey(name: 'open_remark') this.openRemark = '', @JsonKey(name: 'emergency_phone') this.emergencyPhone = '', @JsonKey(name: 'place_id') this.placeId = ''});
  factory _AedDetail.fromJson(Map<String, dynamic> json) => _$AedDetailFromJson(json);

@override final  int id;
@override@JsonKey(name: 'aed_id') final  String aedId;
@override final  String name;
@override@JsonKey() final  String city;
@override@JsonKey() final  String district;
@override@JsonKey() final  String category;
@override@JsonKey() final  String type;
@override@JsonKey() final  String place;
@override final  double lat;
@override final  double lng;
@override@JsonKey() final  String address;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'place_desc') final  String placeDesc;
@override@JsonKey(name: 'weekday_start') final  String weekdayStart;
@override@JsonKey(name: 'weekday_end') final  String weekdayEnd;
@override@JsonKey(name: 'saturday_start') final  String saturdayStart;
@override@JsonKey(name: 'saturday_end') final  String saturdayEnd;
@override@JsonKey(name: 'sunday_start') final  String sundayStart;
@override@JsonKey(name: 'sunday_end') final  String sundayEnd;
@override@JsonKey(name: 'open_remark') final  String openRemark;
@override@JsonKey(name: 'emergency_phone') final  String emergencyPhone;
@override@JsonKey(name: 'place_id') final  String placeId;

/// Create a copy of AedDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AedDetailCopyWith<_AedDetail> get copyWith => __$AedDetailCopyWithImpl<_AedDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AedDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AedDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.aedId, aedId) || other.aedId == aedId)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.district, district) || other.district == district)&&(identical(other.category, category) || other.category == category)&&(identical(other.type, type) || other.type == type)&&(identical(other.place, place) || other.place == place)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.placeDesc, placeDesc) || other.placeDesc == placeDesc)&&(identical(other.weekdayStart, weekdayStart) || other.weekdayStart == weekdayStart)&&(identical(other.weekdayEnd, weekdayEnd) || other.weekdayEnd == weekdayEnd)&&(identical(other.saturdayStart, saturdayStart) || other.saturdayStart == saturdayStart)&&(identical(other.saturdayEnd, saturdayEnd) || other.saturdayEnd == saturdayEnd)&&(identical(other.sundayStart, sundayStart) || other.sundayStart == sundayStart)&&(identical(other.sundayEnd, sundayEnd) || other.sundayEnd == sundayEnd)&&(identical(other.openRemark, openRemark) || other.openRemark == openRemark)&&(identical(other.emergencyPhone, emergencyPhone) || other.emergencyPhone == emergencyPhone)&&(identical(other.placeId, placeId) || other.placeId == placeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,aedId,name,city,district,category,type,place,lat,lng,address,description,placeDesc,weekdayStart,weekdayEnd,saturdayStart,saturdayEnd,sundayStart,sundayEnd,openRemark,emergencyPhone,placeId]);

@override
String toString() {
  return 'AedDetail(id: $id, aedId: $aedId, name: $name, city: $city, district: $district, category: $category, type: $type, place: $place, lat: $lat, lng: $lng, address: $address, description: $description, placeDesc: $placeDesc, weekdayStart: $weekdayStart, weekdayEnd: $weekdayEnd, saturdayStart: $saturdayStart, saturdayEnd: $saturdayEnd, sundayStart: $sundayStart, sundayEnd: $sundayEnd, openRemark: $openRemark, emergencyPhone: $emergencyPhone, placeId: $placeId)';
}


}

/// @nodoc
abstract mixin class _$AedDetailCopyWith<$Res> implements $AedDetailCopyWith<$Res> {
  factory _$AedDetailCopyWith(_AedDetail value, $Res Function(_AedDetail) _then) = __$AedDetailCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'aed_id') String aedId, String name, String city, String district, String category, String type, String place, double lat, double lng, String address, String description,@JsonKey(name: 'place_desc') String placeDesc,@JsonKey(name: 'weekday_start') String weekdayStart,@JsonKey(name: 'weekday_end') String weekdayEnd,@JsonKey(name: 'saturday_start') String saturdayStart,@JsonKey(name: 'saturday_end') String saturdayEnd,@JsonKey(name: 'sunday_start') String sundayStart,@JsonKey(name: 'sunday_end') String sundayEnd,@JsonKey(name: 'open_remark') String openRemark,@JsonKey(name: 'emergency_phone') String emergencyPhone,@JsonKey(name: 'place_id') String placeId
});




}
/// @nodoc
class __$AedDetailCopyWithImpl<$Res>
    implements _$AedDetailCopyWith<$Res> {
  __$AedDetailCopyWithImpl(this._self, this._then);

  final _AedDetail _self;
  final $Res Function(_AedDetail) _then;

/// Create a copy of AedDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? aedId = null,Object? name = null,Object? city = null,Object? district = null,Object? category = null,Object? type = null,Object? place = null,Object? lat = null,Object? lng = null,Object? address = null,Object? description = null,Object? placeDesc = null,Object? weekdayStart = null,Object? weekdayEnd = null,Object? saturdayStart = null,Object? saturdayEnd = null,Object? sundayStart = null,Object? sundayEnd = null,Object? openRemark = null,Object? emergencyPhone = null,Object? placeId = null,}) {
  return _then(_AedDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,aedId: null == aedId ? _self.aedId : aedId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,district: null == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,placeDesc: null == placeDesc ? _self.placeDesc : placeDesc // ignore: cast_nullable_to_non_nullable
as String,weekdayStart: null == weekdayStart ? _self.weekdayStart : weekdayStart // ignore: cast_nullable_to_non_nullable
as String,weekdayEnd: null == weekdayEnd ? _self.weekdayEnd : weekdayEnd // ignore: cast_nullable_to_non_nullable
as String,saturdayStart: null == saturdayStart ? _self.saturdayStart : saturdayStart // ignore: cast_nullable_to_non_nullable
as String,saturdayEnd: null == saturdayEnd ? _self.saturdayEnd : saturdayEnd // ignore: cast_nullable_to_non_nullable
as String,sundayStart: null == sundayStart ? _self.sundayStart : sundayStart // ignore: cast_nullable_to_non_nullable
as String,sundayEnd: null == sundayEnd ? _self.sundayEnd : sundayEnd // ignore: cast_nullable_to_non_nullable
as String,openRemark: null == openRemark ? _self.openRemark : openRemark // ignore: cast_nullable_to_non_nullable
as String,emergencyPhone: null == emergencyPhone ? _self.emergencyPhone : emergencyPhone // ignore: cast_nullable_to_non_nullable
as String,placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
