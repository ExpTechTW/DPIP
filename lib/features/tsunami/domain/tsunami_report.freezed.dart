// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tsunami_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TsunamiEarthquake {

/// Origin time (Unix milliseconds).
@JsonKey(name: 't') int get time;@JsonKey(name: 'lon') double get longitude;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'loc') String get location;/// Focal depth (km).
@JsonKey(name: 'dep') double get depth;/// CWA magnitude.
@JsonKey(name: 'mag') double get magnitude;
/// Create a copy of TsunamiEarthquake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TsunamiEarthquakeCopyWith<TsunamiEarthquake> get copyWith => _$TsunamiEarthquakeCopyWithImpl<TsunamiEarthquake>(this as TsunamiEarthquake, _$identity);

  /// Serializes this TsunamiEarthquake to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TsunamiEarthquake&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,longitude,latitude,location,depth,magnitude);

@override
String toString() {
  return 'TsunamiEarthquake(time: $time, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude)';
}


}

/// @nodoc
abstract mixin class $TsunamiEarthquakeCopyWith<$Res>  {
  factory $TsunamiEarthquakeCopyWith(TsunamiEarthquake value, $Res Function(TsunamiEarthquake) _then) = _$TsunamiEarthquakeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location,@JsonKey(name: 'dep') double depth,@JsonKey(name: 'mag') double magnitude
});




}
/// @nodoc
class _$TsunamiEarthquakeCopyWithImpl<$Res>
    implements $TsunamiEarthquakeCopyWith<$Res> {
  _$TsunamiEarthquakeCopyWithImpl(this._self, this._then);

  final TsunamiEarthquake _self;
  final $Res Function(TsunamiEarthquake) _then;

/// Create a copy of TsunamiEarthquake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,}) {
  return _then(TsunamiEarthquake(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TsunamiEarthquake].
extension TsunamiEarthquakePatterns on TsunamiEarthquake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TsunamiEarthquake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TsunamiEarthquake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TsunamiEarthquake value)  $default,){
final _that = this;
switch (_that) {
case _TsunamiEarthquake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TsunamiEarthquake value)?  $default,){
final _that = this;
switch (_that) {
case _TsunamiEarthquake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location, @JsonKey(name: 'dep')  double depth, @JsonKey(name: 'mag')  double magnitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TsunamiEarthquake() when $default != null:
return $default(_that.time,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location, @JsonKey(name: 'dep')  double depth, @JsonKey(name: 'mag')  double magnitude)  $default,) {final _that = this;
switch (_that) {
case _TsunamiEarthquake():
return $default(_that.time,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lon')  double longitude, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'loc')  String location, @JsonKey(name: 'dep')  double depth, @JsonKey(name: 'mag')  double magnitude)?  $default,) {final _that = this;
switch (_that) {
case _TsunamiEarthquake() when $default != null:
return $default(_that.time,_that.longitude,_that.latitude,_that.location,_that.depth,_that.magnitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TsunamiEarthquake implements TsunamiEarthquake {
  const _TsunamiEarthquake({@JsonKey(name: 't') required this.time, @JsonKey(name: 'lon') required this.longitude, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'loc') required this.location, @JsonKey(name: 'dep') required this.depth, @JsonKey(name: 'mag') required this.magnitude});
  factory _TsunamiEarthquake.fromJson(Map<String, dynamic> json) => _$TsunamiEarthquakeFromJson(json);

/// Origin time (Unix milliseconds).
@override@JsonKey(name: 't') final  int time;
@override@JsonKey(name: 'lon') final  double longitude;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'loc') final  String location;
/// Focal depth (km).
@override@JsonKey(name: 'dep') final  double depth;
/// CWA magnitude.
@override@JsonKey(name: 'mag') final  double magnitude;

/// Create a copy of TsunamiEarthquake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TsunamiEarthquakeCopyWith<_TsunamiEarthquake> get copyWith => __$TsunamiEarthquakeCopyWithImpl<_TsunamiEarthquake>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TsunamiEarthquakeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TsunamiEarthquake&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.location, location) || other.location == location)&&(identical(other.depth, depth) || other.depth == depth)&&(identical(other.magnitude, magnitude) || other.magnitude == magnitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,longitude,latitude,location,depth,magnitude);

@override
String toString() {
  return 'TsunamiEarthquake(time: $time, longitude: $longitude, latitude: $latitude, location: $location, depth: $depth, magnitude: $magnitude)';
}


}

/// @nodoc
abstract mixin class _$TsunamiEarthquakeCopyWith<$Res> implements $TsunamiEarthquakeCopyWith<$Res> {
  factory _$TsunamiEarthquakeCopyWith(_TsunamiEarthquake value, $Res Function(_TsunamiEarthquake) _then) = __$TsunamiEarthquakeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lon') double longitude,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'loc') String location,@JsonKey(name: 'dep') double depth,@JsonKey(name: 'mag') double magnitude
});




}
/// @nodoc
class __$TsunamiEarthquakeCopyWithImpl<$Res>
    implements _$TsunamiEarthquakeCopyWith<$Res> {
  __$TsunamiEarthquakeCopyWithImpl(this._self, this._then);

  final _TsunamiEarthquake _self;
  final $Res Function(_TsunamiEarthquake) _then;

/// Create a copy of TsunamiEarthquake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? longitude = null,Object? latitude = null,Object? location = null,Object? depth = null,Object? magnitude = null,}) {
  return _then(_TsunamiEarthquake(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,depth: null == depth ? _self.depth : depth // ignore: cast_nullable_to_non_nullable
as double,magnitude: null == magnitude ? _self.magnitude : magnitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TsunamiPrediction {

 String get area; String get coast; String get height;/// Predicted arrival time (Unix milliseconds).
 int get arrivalTime;/// CWA's own warning colour for the area (`黃色`), the fifth field of the
/// tuple. Null when the tuple is shorter or the field is empty: the map
/// then leaves the area unpainted rather than reading a band out of
/// [height].
 String? get color;
/// Create a copy of TsunamiPrediction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TsunamiPredictionCopyWith<TsunamiPrediction> get copyWith => _$TsunamiPredictionCopyWithImpl<TsunamiPrediction>(this as TsunamiPrediction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TsunamiPrediction&&(identical(other.area, area) || other.area == area)&&(identical(other.coast, coast) || other.coast == coast)&&(identical(other.height, height) || other.height == height)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,area,coast,height,arrivalTime,color);

@override
String toString() {
  return 'TsunamiPrediction(area: $area, coast: $coast, height: $height, arrivalTime: $arrivalTime, color: $color)';
}


}

/// @nodoc
abstract mixin class $TsunamiPredictionCopyWith<$Res>  {
  factory $TsunamiPredictionCopyWith(TsunamiPrediction value, $Res Function(TsunamiPrediction) _then) = _$TsunamiPredictionCopyWithImpl;
@useResult
$Res call({
 String area, String coast, String height, int arrivalTime, String? color
});




}
/// @nodoc
class _$TsunamiPredictionCopyWithImpl<$Res>
    implements $TsunamiPredictionCopyWith<$Res> {
  _$TsunamiPredictionCopyWithImpl(this._self, this._then);

  final TsunamiPrediction _self;
  final $Res Function(TsunamiPrediction) _then;

/// Create a copy of TsunamiPrediction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? area = null,Object? coast = null,Object? height = null,Object? arrivalTime = null,Object? color = freezed,}) {
  return _then(TsunamiPrediction(
area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,coast: null == coast ? _self.coast : coast // ignore: cast_nullable_to_non_nullable
as String,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String,arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TsunamiPrediction].
extension TsunamiPredictionPatterns on TsunamiPrediction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TsunamiPrediction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TsunamiPrediction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TsunamiPrediction value)  $default,){
final _that = this;
switch (_that) {
case _TsunamiPrediction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TsunamiPrediction value)?  $default,){
final _that = this;
switch (_that) {
case _TsunamiPrediction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String area,  String coast,  String height,  int arrivalTime,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TsunamiPrediction() when $default != null:
return $default(_that.area,_that.coast,_that.height,_that.arrivalTime,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String area,  String coast,  String height,  int arrivalTime,  String? color)  $default,) {final _that = this;
switch (_that) {
case _TsunamiPrediction():
return $default(_that.area,_that.coast,_that.height,_that.arrivalTime,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String area,  String coast,  String height,  int arrivalTime,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _TsunamiPrediction() when $default != null:
return $default(_that.area,_that.coast,_that.height,_that.arrivalTime,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _TsunamiPrediction implements TsunamiPrediction {
  const _TsunamiPrediction({required this.area, required this.coast, required this.height, required this.arrivalTime, this.color});
  

@override final  String area;
@override final  String coast;
@override final  String height;
/// Predicted arrival time (Unix milliseconds).
@override final  int arrivalTime;
/// CWA's own warning colour for the area (`黃色`), the fifth field of the
/// tuple. Null when the tuple is shorter or the field is empty: the map
/// then leaves the area unpainted rather than reading a band out of
/// [height].
@override final  String? color;

/// Create a copy of TsunamiPrediction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TsunamiPredictionCopyWith<_TsunamiPrediction> get copyWith => __$TsunamiPredictionCopyWithImpl<_TsunamiPrediction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TsunamiPrediction&&(identical(other.area, area) || other.area == area)&&(identical(other.coast, coast) || other.coast == coast)&&(identical(other.height, height) || other.height == height)&&(identical(other.arrivalTime, arrivalTime) || other.arrivalTime == arrivalTime)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,area,coast,height,arrivalTime,color);

@override
String toString() {
  return 'TsunamiPrediction(area: $area, coast: $coast, height: $height, arrivalTime: $arrivalTime, color: $color)';
}


}

/// @nodoc
abstract mixin class _$TsunamiPredictionCopyWith<$Res> implements $TsunamiPredictionCopyWith<$Res> {
  factory _$TsunamiPredictionCopyWith(_TsunamiPrediction value, $Res Function(_TsunamiPrediction) _then) = __$TsunamiPredictionCopyWithImpl;
@override @useResult
$Res call({
 String area, String coast, String height, int arrivalTime, String? color
});




}
/// @nodoc
class __$TsunamiPredictionCopyWithImpl<$Res>
    implements _$TsunamiPredictionCopyWith<$Res> {
  __$TsunamiPredictionCopyWithImpl(this._self, this._then);

  final _TsunamiPrediction _self;
  final $Res Function(_TsunamiPrediction) _then;

/// Create a copy of TsunamiPrediction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? area = null,Object? coast = null,Object? height = null,Object? arrivalTime = null,Object? color = freezed,}) {
  return _then(_TsunamiPrediction(
area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,coast: null == coast ? _self.coast : coast // ignore: cast_nullable_to_non_nullable
as String,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String,arrivalTime: null == arrivalTime ? _self.arrivalTime : arrivalTime // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TsunamiObservation {

 String get name;/// CWA's observed height text (`27公分`).
 String get height;/// Observation time (Unix milliseconds).
 int get time; double? get longitude; double? get latitude;
/// Create a copy of TsunamiObservation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TsunamiObservationCopyWith<TsunamiObservation> get copyWith => _$TsunamiObservationCopyWithImpl<TsunamiObservation>(this as TsunamiObservation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TsunamiObservation&&(identical(other.name, name) || other.name == name)&&(identical(other.height, height) || other.height == height)&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude));
}


@override
int get hashCode => Object.hash(runtimeType,name,height,time,longitude,latitude);

@override
String toString() {
  return 'TsunamiObservation(name: $name, height: $height, time: $time, longitude: $longitude, latitude: $latitude)';
}


}

/// @nodoc
abstract mixin class $TsunamiObservationCopyWith<$Res>  {
  factory $TsunamiObservationCopyWith(TsunamiObservation value, $Res Function(TsunamiObservation) _then) = _$TsunamiObservationCopyWithImpl;
@useResult
$Res call({
 String name, String height, int time, double? longitude, double? latitude
});




}
/// @nodoc
class _$TsunamiObservationCopyWithImpl<$Res>
    implements $TsunamiObservationCopyWith<$Res> {
  _$TsunamiObservationCopyWithImpl(this._self, this._then);

  final TsunamiObservation _self;
  final $Res Function(TsunamiObservation) _then;

/// Create a copy of TsunamiObservation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? height = null,Object? time = null,Object? longitude = freezed,Object? latitude = freezed,}) {
  return _then(TsunamiObservation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TsunamiObservation].
extension TsunamiObservationPatterns on TsunamiObservation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TsunamiObservation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TsunamiObservation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TsunamiObservation value)  $default,){
final _that = this;
switch (_that) {
case _TsunamiObservation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TsunamiObservation value)?  $default,){
final _that = this;
switch (_that) {
case _TsunamiObservation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String height,  int time,  double? longitude,  double? latitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TsunamiObservation() when $default != null:
return $default(_that.name,_that.height,_that.time,_that.longitude,_that.latitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String height,  int time,  double? longitude,  double? latitude)  $default,) {final _that = this;
switch (_that) {
case _TsunamiObservation():
return $default(_that.name,_that.height,_that.time,_that.longitude,_that.latitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String height,  int time,  double? longitude,  double? latitude)?  $default,) {final _that = this;
switch (_that) {
case _TsunamiObservation() when $default != null:
return $default(_that.name,_that.height,_that.time,_that.longitude,_that.latitude);case _:
  return null;

}
}

}

/// @nodoc


class _TsunamiObservation implements TsunamiObservation {
  const _TsunamiObservation({required this.name, required this.height, required this.time, this.longitude, this.latitude});
  

@override final  String name;
/// CWA's observed height text (`27公分`).
@override final  String height;
/// Observation time (Unix milliseconds).
@override final  int time;
@override final  double? longitude;
@override final  double? latitude;

/// Create a copy of TsunamiObservation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TsunamiObservationCopyWith<_TsunamiObservation> get copyWith => __$TsunamiObservationCopyWithImpl<_TsunamiObservation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TsunamiObservation&&(identical(other.name, name) || other.name == name)&&(identical(other.height, height) || other.height == height)&&(identical(other.time, time) || other.time == time)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.latitude, latitude) || other.latitude == latitude));
}


@override
int get hashCode => Object.hash(runtimeType,name,height,time,longitude,latitude);

@override
String toString() {
  return 'TsunamiObservation(name: $name, height: $height, time: $time, longitude: $longitude, latitude: $latitude)';
}


}

/// @nodoc
abstract mixin class _$TsunamiObservationCopyWith<$Res> implements $TsunamiObservationCopyWith<$Res> {
  factory _$TsunamiObservationCopyWith(_TsunamiObservation value, $Res Function(_TsunamiObservation) _then) = __$TsunamiObservationCopyWithImpl;
@override @useResult
$Res call({
 String name, String height, int time, double? longitude, double? latitude
});




}
/// @nodoc
class __$TsunamiObservationCopyWithImpl<$Res>
    implements _$TsunamiObservationCopyWith<$Res> {
  __$TsunamiObservationCopyWithImpl(this._self, this._then);

  final _TsunamiObservation _self;
  final $Res Function(_TsunamiObservation) _then;

/// Create a copy of TsunamiObservation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? height = null,Object? time = null,Object? longitude = freezed,Object? latitude = freezed,}) {
  return _then(_TsunamiObservation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$TsunamiBulletin {

 String get id;/// CWA event number, shared by every report of the same earthquake
/// (`113003`) — the key that makes "this event's reports" a list.
@JsonKey(name: 'no') int get number;/// Report within the event, CWA's own wording (`第3報`).
@JsonKey(name: 'rep') String get report;/// `海嘯警報` / `海嘯警報解除`.
 String get type;/// Send time (Unix milliseconds).
 int get sent;
/// Create a copy of TsunamiBulletin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TsunamiBulletinCopyWith<TsunamiBulletin> get copyWith => _$TsunamiBulletinCopyWithImpl<TsunamiBulletin>(this as TsunamiBulletin, _$identity);

  /// Serializes this TsunamiBulletin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TsunamiBulletin&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.report, report) || other.report == report)&&(identical(other.type, type) || other.type == type)&&(identical(other.sent, sent) || other.sent == sent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,report,type,sent);

@override
String toString() {
  return 'TsunamiBulletin(id: $id, number: $number, report: $report, type: $type, sent: $sent)';
}


}

/// @nodoc
abstract mixin class $TsunamiBulletinCopyWith<$Res>  {
  factory $TsunamiBulletinCopyWith(TsunamiBulletin value, $Res Function(TsunamiBulletin) _then) = _$TsunamiBulletinCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'no') int number,@JsonKey(name: 'rep') String report, String type, int sent
});




}
/// @nodoc
class _$TsunamiBulletinCopyWithImpl<$Res>
    implements $TsunamiBulletinCopyWith<$Res> {
  _$TsunamiBulletinCopyWithImpl(this._self, this._then);

  final TsunamiBulletin _self;
  final $Res Function(TsunamiBulletin) _then;

/// Create a copy of TsunamiBulletin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? report = null,Object? type = null,Object? sent = null,}) {
  return _then(TsunamiBulletin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TsunamiBulletin].
extension TsunamiBulletinPatterns on TsunamiBulletin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TsunamiBulletin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TsunamiBulletin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TsunamiBulletin value)  $default,){
final _that = this;
switch (_that) {
case _TsunamiBulletin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TsunamiBulletin value)?  $default,){
final _that = this;
switch (_that) {
case _TsunamiBulletin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'no')  int number, @JsonKey(name: 'rep')  String report,  String type,  int sent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TsunamiBulletin() when $default != null:
return $default(_that.id,_that.number,_that.report,_that.type,_that.sent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'no')  int number, @JsonKey(name: 'rep')  String report,  String type,  int sent)  $default,) {final _that = this;
switch (_that) {
case _TsunamiBulletin():
return $default(_that.id,_that.number,_that.report,_that.type,_that.sent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'no')  int number, @JsonKey(name: 'rep')  String report,  String type,  int sent)?  $default,) {final _that = this;
switch (_that) {
case _TsunamiBulletin() when $default != null:
return $default(_that.id,_that.number,_that.report,_that.type,_that.sent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TsunamiBulletin implements TsunamiBulletin {
  const _TsunamiBulletin({required this.id, @JsonKey(name: 'no') required this.number, @JsonKey(name: 'rep') required this.report, required this.type, required this.sent});
  factory _TsunamiBulletin.fromJson(Map<String, dynamic> json) => _$TsunamiBulletinFromJson(json);

@override final  String id;
/// CWA event number, shared by every report of the same earthquake
/// (`113003`) — the key that makes "this event's reports" a list.
@override@JsonKey(name: 'no') final  int number;
/// Report within the event, CWA's own wording (`第3報`).
@override@JsonKey(name: 'rep') final  String report;
/// `海嘯警報` / `海嘯警報解除`.
@override final  String type;
/// Send time (Unix milliseconds).
@override final  int sent;

/// Create a copy of TsunamiBulletin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TsunamiBulletinCopyWith<_TsunamiBulletin> get copyWith => __$TsunamiBulletinCopyWithImpl<_TsunamiBulletin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TsunamiBulletinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TsunamiBulletin&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.report, report) || other.report == report)&&(identical(other.type, type) || other.type == type)&&(identical(other.sent, sent) || other.sent == sent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,report,type,sent);

@override
String toString() {
  return 'TsunamiBulletin(id: $id, number: $number, report: $report, type: $type, sent: $sent)';
}


}

/// @nodoc
abstract mixin class _$TsunamiBulletinCopyWith<$Res> implements $TsunamiBulletinCopyWith<$Res> {
  factory _$TsunamiBulletinCopyWith(_TsunamiBulletin value, $Res Function(_TsunamiBulletin) _then) = __$TsunamiBulletinCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'no') int number,@JsonKey(name: 'rep') String report, String type, int sent
});




}
/// @nodoc
class __$TsunamiBulletinCopyWithImpl<$Res>
    implements _$TsunamiBulletinCopyWith<$Res> {
  __$TsunamiBulletinCopyWithImpl(this._self, this._then);

  final _TsunamiBulletin _self;
  final $Res Function(_TsunamiBulletin) _then;

/// Create a copy of TsunamiBulletin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? report = null,Object? type = null,Object? sent = null,}) {
  return _then(_TsunamiBulletin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$TsunamiReport {

 String get id;/// Send time (Unix milliseconds — the tsunami feed, unlike the meteor
/// families, is not in seconds).
 int get sent;/// CAP message type: `Issue` / `Update` / `Cancel`. `Cancel` means the
/// threat was lifted, which the sheet states rather than hiding.
 String get msgType;/// Report within the event, CWA's own wording (`第3報`).
 String get report;/// `海嘯警報` / `海嘯警報解除`.
 String get type; String get content; TsunamiEarthquake get earthquake; List<TsunamiPrediction> get predictions; List<TsunamiObservation> get observations;
/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TsunamiReportCopyWith<TsunamiReport> get copyWith => _$TsunamiReportCopyWithImpl<TsunamiReport>(this as TsunamiReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TsunamiReport&&(identical(other.id, id) || other.id == id)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.msgType, msgType) || other.msgType == msgType)&&(identical(other.report, report) || other.report == report)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.earthquake, earthquake) || other.earthquake == earthquake)&&const DeepCollectionEquality().equals(other.predictions, predictions)&&const DeepCollectionEquality().equals(other.observations, observations));
}


@override
int get hashCode => Object.hash(runtimeType,id,sent,msgType,report,type,content,earthquake,const DeepCollectionEquality().hash(predictions),const DeepCollectionEquality().hash(observations));

@override
String toString() {
  return 'TsunamiReport(id: $id, sent: $sent, msgType: $msgType, report: $report, type: $type, content: $content, earthquake: $earthquake, predictions: $predictions, observations: $observations)';
}


}

/// @nodoc
abstract mixin class $TsunamiReportCopyWith<$Res>  {
  factory $TsunamiReportCopyWith(TsunamiReport value, $Res Function(TsunamiReport) _then) = _$TsunamiReportCopyWithImpl;
@useResult
$Res call({
 String id, int sent, String msgType, String report, String type, String content, TsunamiEarthquake earthquake, List<TsunamiPrediction> predictions, List<TsunamiObservation> observations
});


$TsunamiEarthquakeCopyWith<$Res> get earthquake;

}
/// @nodoc
class _$TsunamiReportCopyWithImpl<$Res>
    implements $TsunamiReportCopyWith<$Res> {
  _$TsunamiReportCopyWithImpl(this._self, this._then);

  final TsunamiReport _self;
  final $Res Function(TsunamiReport) _then;

/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sent = null,Object? msgType = null,Object? report = null,Object? type = null,Object? content = null,Object? earthquake = null,Object? predictions = null,Object? observations = null,}) {
  return _then(TsunamiReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,msgType: null == msgType ? _self.msgType : msgType // ignore: cast_nullable_to_non_nullable
as String,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,earthquake: null == earthquake ? _self.earthquake : earthquake // ignore: cast_nullable_to_non_nullable
as TsunamiEarthquake,predictions: null == predictions ? _self.predictions : predictions // ignore: cast_nullable_to_non_nullable
as List<TsunamiPrediction>,observations: null == observations ? _self.observations : observations // ignore: cast_nullable_to_non_nullable
as List<TsunamiObservation>,
  ));
}
/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TsunamiEarthquakeCopyWith<$Res> get earthquake {
  
  return $TsunamiEarthquakeCopyWith<$Res>(_self.earthquake, (value) {
    return _then(_self.copyWith(earthquake: value));
  });
}
}


/// Adds pattern-matching-related methods to [TsunamiReport].
extension TsunamiReportPatterns on TsunamiReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TsunamiReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TsunamiReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TsunamiReport value)  $default,){
final _that = this;
switch (_that) {
case _TsunamiReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TsunamiReport value)?  $default,){
final _that = this;
switch (_that) {
case _TsunamiReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int sent,  String msgType,  String report,  String type,  String content,  TsunamiEarthquake earthquake,  List<TsunamiPrediction> predictions,  List<TsunamiObservation> observations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TsunamiReport() when $default != null:
return $default(_that.id,_that.sent,_that.msgType,_that.report,_that.type,_that.content,_that.earthquake,_that.predictions,_that.observations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int sent,  String msgType,  String report,  String type,  String content,  TsunamiEarthquake earthquake,  List<TsunamiPrediction> predictions,  List<TsunamiObservation> observations)  $default,) {final _that = this;
switch (_that) {
case _TsunamiReport():
return $default(_that.id,_that.sent,_that.msgType,_that.report,_that.type,_that.content,_that.earthquake,_that.predictions,_that.observations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int sent,  String msgType,  String report,  String type,  String content,  TsunamiEarthquake earthquake,  List<TsunamiPrediction> predictions,  List<TsunamiObservation> observations)?  $default,) {final _that = this;
switch (_that) {
case _TsunamiReport() when $default != null:
return $default(_that.id,_that.sent,_that.msgType,_that.report,_that.type,_that.content,_that.earthquake,_that.predictions,_that.observations);case _:
  return null;

}
}

}

/// @nodoc


class _TsunamiReport implements TsunamiReport {
  const _TsunamiReport({required this.id, required this.sent, required this.msgType, required this.report, required this.type, required this.content, required this.earthquake, required  List<TsunamiPrediction> predictions, required  List<TsunamiObservation> observations}): _predictions = predictions,_observations = observations;
  

@override final  String id;
/// Send time (Unix milliseconds — the tsunami feed, unlike the meteor
/// families, is not in seconds).
@override final  int sent;
/// CAP message type: `Issue` / `Update` / `Cancel`. `Cancel` means the
/// threat was lifted, which the sheet states rather than hiding.
@override final  String msgType;
/// Report within the event, CWA's own wording (`第3報`).
@override final  String report;
/// `海嘯警報` / `海嘯警報解除`.
@override final  String type;
@override final  String content;
@override final  TsunamiEarthquake earthquake;
 final  List<TsunamiPrediction> _predictions;
@override List<TsunamiPrediction> get predictions {
  if (_predictions is EqualUnmodifiableListView) return _predictions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_predictions);
}

 final  List<TsunamiObservation> _observations;
@override List<TsunamiObservation> get observations {
  if (_observations is EqualUnmodifiableListView) return _observations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_observations);
}


/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TsunamiReportCopyWith<_TsunamiReport> get copyWith => __$TsunamiReportCopyWithImpl<_TsunamiReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TsunamiReport&&(identical(other.id, id) || other.id == id)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.msgType, msgType) || other.msgType == msgType)&&(identical(other.report, report) || other.report == report)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.earthquake, earthquake) || other.earthquake == earthquake)&&const DeepCollectionEquality().equals(other._predictions, _predictions)&&const DeepCollectionEquality().equals(other._observations, _observations));
}


@override
int get hashCode => Object.hash(runtimeType,id,sent,msgType,report,type,content,earthquake,const DeepCollectionEquality().hash(_predictions),const DeepCollectionEquality().hash(_observations));

@override
String toString() {
  return 'TsunamiReport(id: $id, sent: $sent, msgType: $msgType, report: $report, type: $type, content: $content, earthquake: $earthquake, predictions: $predictions, observations: $observations)';
}


}

/// @nodoc
abstract mixin class _$TsunamiReportCopyWith<$Res> implements $TsunamiReportCopyWith<$Res> {
  factory _$TsunamiReportCopyWith(_TsunamiReport value, $Res Function(_TsunamiReport) _then) = __$TsunamiReportCopyWithImpl;
@override @useResult
$Res call({
 String id, int sent, String msgType, String report, String type, String content, TsunamiEarthquake earthquake, List<TsunamiPrediction> predictions, List<TsunamiObservation> observations
});


@override $TsunamiEarthquakeCopyWith<$Res> get earthquake;

}
/// @nodoc
class __$TsunamiReportCopyWithImpl<$Res>
    implements _$TsunamiReportCopyWith<$Res> {
  __$TsunamiReportCopyWithImpl(this._self, this._then);

  final _TsunamiReport _self;
  final $Res Function(_TsunamiReport) _then;

/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sent = null,Object? msgType = null,Object? report = null,Object? type = null,Object? content = null,Object? earthquake = null,Object? predictions = null,Object? observations = null,}) {
  return _then(_TsunamiReport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,msgType: null == msgType ? _self.msgType : msgType // ignore: cast_nullable_to_non_nullable
as String,report: null == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,earthquake: null == earthquake ? _self.earthquake : earthquake // ignore: cast_nullable_to_non_nullable
as TsunamiEarthquake,predictions: null == predictions ? _self._predictions : predictions // ignore: cast_nullable_to_non_nullable
as List<TsunamiPrediction>,observations: null == observations ? _self._observations : observations // ignore: cast_nullable_to_non_nullable
as List<TsunamiObservation>,
  ));
}

/// Create a copy of TsunamiReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TsunamiEarthquakeCopyWith<$Res> get earthquake {
  
  return $TsunamiEarthquakeCopyWith<$Res>(_self.earthquake, (value) {
    return _then(_self.copyWith(earthquake: value));
  });
}
}

// dart format on
