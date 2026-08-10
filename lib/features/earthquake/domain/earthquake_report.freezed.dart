// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earthquake_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarthquakeReport {

 String get id;@JsonKey(name: 'lon') double get longitude;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'loc') String get location; double get depth;@JsonKey(name: 'mag') double get magnitude; Map<String, AreaIntensity> get list;/// Origin time as Unix **milliseconds**.
 int get time; int get trem;
/// Create a copy of EarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarthquakeReportCopyWith<EarthquakeReport> get copyWith => _$EarthquakeReportCopyWithImpl<EarthquakeReport>(this as EarthquakeReport, _$identity);

  /// Serializes this EarthquakeReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarthquakeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.time, time) || other.time == time)&&(identical(other.trem, trem) || other.trem == trem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,longitude,latitude,location,depth,magnitude,const DeepCollectionEquality().hash(list),time,trem);

@override
String toString() {
  return 'EarthquakeReport(id: $id, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude, list: $list, time: $time, trem: $trem)';
}


}

/// @nodoc
abstract mixin class $EarthquakeReportCopyWith<$Res>  {
  factory $EarthquakeReportCopyWith(EarthquakeReport value, $Res Function(EarthquakeReport) _then) = _$EarthquakeReportCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location, double depth,@JsonKey(name: 'mag') double magnitude, Map<String, AreaIntensity> list, int time, int trem
});




}
/// @nodoc
class _$EarthquakeReportCopyWithImpl<$Res>
    implements $EarthquakeReportCopyWith<$Res> {
  _$EarthquakeReportCopyWithImpl(this._self, this._then);

  final EarthquakeReport _self;
  final $Res Function(EarthquakeReport) _then;

/// Create a copy of EarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,Object? list = null,Object? time = null,Object? trem = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as Map<String, AreaIntensity>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,trem: null == trem ? _self.trem : trem // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EarthquakeReport].
extension EarthquakeReportPatterns on EarthquakeReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarthquakeReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarthquakeReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarthquakeReport value)  $default,){
final _that = this;
switch (_that) {
case _EarthquakeReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarthquakeReport value)?  $default,){
final _that = this;
switch (_that) {
case _EarthquakeReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude,  Map<String, AreaIntensity> list,  int time,  int trem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarthquakeReport() when $default != null:
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.list,_that.time,_that.trem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude,  Map<String, AreaIntensity> list,  int time,  int trem)  $default,) {final _that = this;
switch (_that) {
case _EarthquakeReport():
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.list,_that.time,_that.trem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location,  double depth, @JsonKey(name: 'mag')  double magnitude,  Map<String, AreaIntensity> list,  int time,  int trem)?  $default,) {final _that = this;
switch (_that) {
case _EarthquakeReport() when $default != null:
return $default(_that.id,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude,_that.list,_that.time,_that.trem);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarthquakeReport extends EarthquakeReport {
  const _EarthquakeReport({required this.id, @JsonKey(name: 'lon') required this.longitude, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'loc') required this.location, required this.depth, @JsonKey(name: 'mag') required this.magnitude, required final  Map<String, AreaIntensity> list, required this.time, required this.trem}): _list = list,super._();
  factory _EarthquakeReport.fromJson(Map<String, dynamic> json) => _$EarthquakeReportFromJson(json);

@override final  String id;
@override@JsonKey(name: 'lon') final  double longitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'loc') final  String location;
@override final  double depth;
@override@JsonKey(name: 'mag') final  double magnitude;
 final  Map<String, AreaIntensity> _list;
@override Map<String, AreaIntensity> get list {
  if (_list is EqualUnmodifiableMapView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_list);
}

/// Origin time as Unix **milliseconds**.
@override final  int time;
@override final  int trem;

/// Create a copy of EarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarthquakeReportCopyWith<_EarthquakeReport> get copyWith => __$EarthquakeReportCopyWithImpl<_EarthquakeReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarthquakeReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarthquakeReport&&(identical(other.id, id) || other.id == id)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude)&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.time, time) || other.time == time)&&(identical(other.trem, trem) || other.trem == trem));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,longitude,latitude,location,depth,magnitude,const DeepCollectionEquality().hash(_list),time,trem);

@override
String toString() {
  return 'EarthquakeReport(id: $id, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude, list: $list, time: $time, trem: $trem)';
}


}

/// @nodoc
abstract mixin class _$EarthquakeReportCopyWith<$Res> implements $EarthquakeReportCopyWith<$Res> {
  factory _$EarthquakeReportCopyWith(_EarthquakeReport value, $Res Function(_EarthquakeReport) _then) = __$EarthquakeReportCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location, double depth,@JsonKey(name: 'mag') double magnitude, Map<String, AreaIntensity> list, int time, int trem
});




}
/// @nodoc
class __$EarthquakeReportCopyWithImpl<$Res>
    implements _$EarthquakeReportCopyWith<$Res> {
  __$EarthquakeReportCopyWithImpl(this._self, this._then);

  final _EarthquakeReport _self;
  final $Res Function(_EarthquakeReport) _then;

/// Create a copy of EarthquakeReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,Object? list = null,Object? time = null,Object? trem = null,}) {
  return _then(_EarthquakeReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as Map<String, AreaIntensity>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,trem: null == trem ? _self.trem : trem // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AreaIntensity {

@JsonKey(name: 'int') int get intensity; Map<String, StationIntensity> get town;
/// Create a copy of AreaIntensity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreaIntensityCopyWith<AreaIntensity> get copyWith => _$AreaIntensityCopyWithImpl<AreaIntensity>(this as AreaIntensity, _$identity);

  /// Serializes this AreaIntensity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AreaIntensity&&(identical(other.intensity, intensity) || other.intensity == intensity)&&const DeepCollectionEquality().equals(other.town, town));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,const DeepCollectionEquality().hash(town));

@override
String toString() {
  return 'AreaIntensity(intensity: $intensity, town: $town)';
}


}

/// @nodoc
abstract mixin class $AreaIntensityCopyWith<$Res>  {
  factory $AreaIntensityCopyWith(AreaIntensity value, $Res Function(AreaIntensity) _then) = _$AreaIntensityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'int') int intensity, Map<String, StationIntensity> town
});




}
/// @nodoc
class _$AreaIntensityCopyWithImpl<$Res>
    implements $AreaIntensityCopyWith<$Res> {
  _$AreaIntensityCopyWithImpl(this._self, this._then);

  final AreaIntensity _self;
  final $Res Function(AreaIntensity) _then;

/// Create a copy of AreaIntensity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intensity = null,Object? town = null,}) {
  return _then(_self.copyWith(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,town: null == town ? _self.town : town // ignore: cast_nullable_to_non_nullable
as Map<String, StationIntensity>,
  ));
}

}


/// Adds pattern-matching-related methods to [AreaIntensity].
extension AreaIntensityPatterns on AreaIntensity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AreaIntensity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AreaIntensity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AreaIntensity value)  $default,){
final _that = this;
switch (_that) {
case _AreaIntensity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AreaIntensity value)?  $default,){
final _that = this;
switch (_that) {
case _AreaIntensity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'int')  int intensity,  Map<String, StationIntensity> town)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AreaIntensity() when $default != null:
return $default(_that.intensity,_that.town);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'int')  int intensity,  Map<String, StationIntensity> town)  $default,) {final _that = this;
switch (_that) {
case _AreaIntensity():
return $default(_that.intensity,_that.town);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'int')  int intensity,  Map<String, StationIntensity> town)?  $default,) {final _that = this;
switch (_that) {
case _AreaIntensity() when $default != null:
return $default(_that.intensity,_that.town);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AreaIntensity implements AreaIntensity {
  const _AreaIntensity({@JsonKey(name: 'int') required this.intensity, required final  Map<String, StationIntensity> town}): _town = town;
  factory _AreaIntensity.fromJson(Map<String, dynamic> json) => _$AreaIntensityFromJson(json);

@override@JsonKey(name: 'int') final  int intensity;
 final  Map<String, StationIntensity> _town;
@override Map<String, StationIntensity> get town {
  if (_town is EqualUnmodifiableMapView) return _town;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_town);
}


/// Create a copy of AreaIntensity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AreaIntensityCopyWith<_AreaIntensity> get copyWith => __$AreaIntensityCopyWithImpl<_AreaIntensity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AreaIntensityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AreaIntensity&&(identical(other.intensity, intensity) || other.intensity == intensity)&&const DeepCollectionEquality().equals(other._town, _town));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,const DeepCollectionEquality().hash(_town));

@override
String toString() {
  return 'AreaIntensity(intensity: $intensity, town: $town)';
}


}

/// @nodoc
abstract mixin class _$AreaIntensityCopyWith<$Res> implements $AreaIntensityCopyWith<$Res> {
  factory _$AreaIntensityCopyWith(_AreaIntensity value, $Res Function(_AreaIntensity) _then) = __$AreaIntensityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'int') int intensity, Map<String, StationIntensity> town
});




}
/// @nodoc
class __$AreaIntensityCopyWithImpl<$Res>
    implements _$AreaIntensityCopyWith<$Res> {
  __$AreaIntensityCopyWithImpl(this._self, this._then);

  final _AreaIntensity _self;
  final $Res Function(_AreaIntensity) _then;

/// Create a copy of AreaIntensity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intensity = null,Object? town = null,}) {
  return _then(_AreaIntensity(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,town: null == town ? _self._town : town // ignore: cast_nullable_to_non_nullable
as Map<String, StationIntensity>,
  ));
}


}


/// @nodoc
mixin _$StationIntensity {

@JsonKey(name: 'lon') double get longitude;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'int') int get intensity;
/// Create a copy of StationIntensity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationIntensityCopyWith<StationIntensity> get copyWith => _$StationIntensityCopyWithImpl<StationIntensity>(this as StationIntensity, _$identity);

  /// Serializes this StationIntensity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationIntensity&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,longitude,latitude,intensity);

@override
String toString() {
  return 'StationIntensity(longitude: $longitude, latitude: $latitude, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $StationIntensityCopyWith<$Res>  {
  factory $StationIntensityCopyWith(StationIntensity value, $Res Function(StationIntensity) _then) = _$StationIntensityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'int') int intensity
});




}
/// @nodoc
class _$StationIntensityCopyWithImpl<$Res>
    implements $StationIntensityCopyWith<$Res> {
  _$StationIntensityCopyWithImpl(this._self, this._then);

  final StationIntensity _self;
  final $Res Function(StationIntensity) _then;

/// Create a copy of StationIntensity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? longitude = null,Object? latitude = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StationIntensity].
extension StationIntensityPatterns on StationIntensity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StationIntensity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StationIntensity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StationIntensity value)  $default,){
final _that = this;
switch (_that) {
case _StationIntensity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StationIntensity value)?  $default,){
final _that = this;
switch (_that) {
case _StationIntensity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'int')  int intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StationIntensity() when $default != null:
return $default(_that.longitude,_that.latitude,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'int')  int intensity)  $default,) {final _that = this;
switch (_that) {
case _StationIntensity():
return $default(_that.longitude,_that.latitude,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'int')  int intensity)?  $default,) {final _that = this;
switch (_that) {
case _StationIntensity() when $default != null:
return $default(_that.longitude,_that.latitude,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StationIntensity implements StationIntensity {
  const _StationIntensity({@JsonKey(name: 'lon') required this.longitude, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'int') required this.intensity});
  factory _StationIntensity.fromJson(Map<String, dynamic> json) => _$StationIntensityFromJson(json);

@override@JsonKey(name: 'lon') final  double longitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'int') final  int intensity;

/// Create a copy of StationIntensity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StationIntensityCopyWith<_StationIntensity> get copyWith => __$StationIntensityCopyWithImpl<_StationIntensity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StationIntensityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StationIntensity&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,longitude,latitude,intensity);

@override
String toString() {
  return 'StationIntensity(longitude: $longitude, latitude: $latitude, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$StationIntensityCopyWith<$Res> implements $StationIntensityCopyWith<$Res> {
  factory _$StationIntensityCopyWith(_StationIntensity value, $Res Function(_StationIntensity) _then) = __$StationIntensityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'int') int intensity
});




}
/// @nodoc
class __$StationIntensityCopyWithImpl<$Res>
    implements _$StationIntensityCopyWith<$Res> {
  __$StationIntensityCopyWithImpl(this._self, this._then);

  final _StationIntensity _self;
  final $Res Function(_StationIntensity) _then;

/// Create a copy of StationIntensity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? longitude = null,Object? latitude = null,Object? intensity = null,}) {
  return _then(_StationIntensity(
longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
