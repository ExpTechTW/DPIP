// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partial_earthquake_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartialEarthquakeReport {

 String get id;@JsonKey(name: 'lon') double get longitude;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'loc') String get location; double get depth;@JsonKey(name: 'mag') double get magnitude;@JsonKey(name: 'int') int get intensity;/// Origin time as Unix **milliseconds**.
 int get time; int get trem; String get md5;
/// Create a copy of PartialEarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartialEarthquakeReportCopyWith<PartialEarthquakeReport> get copyWith => _$PartialEarthquakeReportCopyWithImpl<PartialEarthquakeReport>(this as PartialEarthquakeReport, _$identity);

  /// Serializes this PartialEarthquakeReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartialEarthquakeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.time, time) || other.time == time)&&(identical(other.trem, trem) || other.trem == trem)&&(identical(other.md5, md5) || other.md5 == md5));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,longitude,latitude,location,depth,magnitude,intensity,time,trem,md5);

@override
String toString() {
  return 'PartialEarthquakeReport(id: $id, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude, intensity: $intensity, time: $time, trem: $trem, md5: $md5)';
}


}

/// @nodoc
abstract mixin class $PartialEarthquakeReportCopyWith<$Res>  {
  factory $PartialEarthquakeReportCopyWith(PartialEarthquakeReport value, $Res Function(PartialEarthquakeReport) _then) = _$PartialEarthquakeReportCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location, double depth,@JsonKey(name: 'mag') double magnitude,@JsonKey(name: 'int') int intensity, int time, int trem, String md5
});




}
/// @nodoc
class _$PartialEarthquakeReportCopyWithImpl<$Res>
    implements $PartialEarthquakeReportCopyWith<$Res> {
  _$PartialEarthquakeReportCopyWithImpl(this._self, this._then);

  final PartialEarthquakeReport _self;
  final $Res Function(PartialEarthquakeReport) _then;

/// Create a copy of PartialEarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,Object? intensity = null,Object? time = null,Object? trem = null,Object? md5 = null,}) {
  return _then(PartialEarthquakeReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,trem: null == trem ? _self.trem : trem // ignore: cast_nullable_to_non_nullable
as int,md5: null == md5 ? _self.md5 : md5 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PartialEarthquakeReport].
extension PartialEarthquakeReportPatterns on PartialEarthquakeReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartialEarthquakeReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartialEarthquakeReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartialEarthquakeReport value)  $default,){
final _that = this;
switch (_that) {
case _PartialEarthquakeReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartialEarthquakeReport value)?  $default,){
final _that = this;
switch (_that) {
case _PartialEarthquakeReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'int')  int intensity,  int time,  int trem,  String md5)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartialEarthquakeReport() when $default != null:
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.intensity,_that.time,_that.trem,_that.md5);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'int')  int intensity,  int time,  int trem,  String md5)  $default,) {final _that = this;
switch (_that) {
case _PartialEarthquakeReport():
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.intensity,_that.time,_that.trem,_that.md5);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude, @JsonKey(name: 'int')  int intensity,  int time,  int trem,  String md5)?  $default,) {final _that = this;
switch (_that) {
case _PartialEarthquakeReport() when $default != null:
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.intensity,_that.time,_that.trem,_that.md5);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartialEarthquakeReport extends PartialEarthquakeReport {
  const _PartialEarthquakeReport({required this.id, @JsonKey(name: 'lon') required this.longitude, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'loc') required this.location, required this.depth, @JsonKey(name: 'mag') required this.magnitude, @JsonKey(name: 'int') required this.intensity, required this.time, required this.trem, required this.md5}): super._();
  factory _PartialEarthquakeReport.fromJson(Map<String, dynamic> json) => _$PartialEarthquakeReportFromJson(json);

@override final  String id;
@override@JsonKey(name: 'lon') final  double longitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'loc') final  String location;
@override final  double depth;
@override@JsonKey(name: 'mag') final  double magnitude;
@override@JsonKey(name: 'int') final  int intensity;
/// Origin time as Unix **milliseconds**.
@override final  int time;
@override final  int trem;
@override final  String md5;

/// Create a copy of PartialEarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartialEarthquakeReportCopyWith<_PartialEarthquakeReport> get copyWith => __$PartialEarthquakeReportCopyWithImpl<_PartialEarthquakeReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartialEarthquakeReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartialEarthquakeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.time, time) || other.time == time)&&(identical(other.trem, trem) || other.trem == trem)&&(identical(other.md5, md5) || other.md5 == md5));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,longitude,latitude,location,depth,magnitude,intensity,time,trem,md5);

@override
String toString() {
  return 'PartialEarthquakeReport(id: $id, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude, intensity: $intensity, time: $time, trem: $trem, md5: $md5)';
}


}

/// @nodoc
abstract mixin class _$PartialEarthquakeReportCopyWith<$Res> implements $PartialEarthquakeReportCopyWith<$Res> {
  factory _$PartialEarthquakeReportCopyWith(_PartialEarthquakeReport value, $Res Function(_PartialEarthquakeReport) _then) = __$PartialEarthquakeReportCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location, double depth,@JsonKey(name: 'mag') double magnitude,@JsonKey(name: 'int') int intensity, int time, int trem, String md5
});




}
/// @nodoc
class __$PartialEarthquakeReportCopyWithImpl<$Res>
    implements _$PartialEarthquakeReportCopyWith<$Res> {
  __$PartialEarthquakeReportCopyWithImpl(this._self, this._then);

  final _PartialEarthquakeReport _self;
  final $Res Function(_PartialEarthquakeReport) _then;

/// Create a copy of PartialEarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,Object? intensity = null,Object? time = null,Object? trem = null,Object? md5 = null,}) {
  return _then(_PartialEarthquakeReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,trem: null == trem ? _self.trem : trem // ignore: cast_nullable_to_non_nullable
as int,md5: null == md5 ? _self.md5 : md5 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
