// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rts {

 Map<String, RtsStation> get station; Map<String, dynamic> get box;@JsonKey(name: 'int') List<dynamic> get intensities; int get time;
/// Create a copy of Rts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RtsCopyWith<Rts> get copyWith => _$RtsCopyWithImpl<Rts>(this as Rts, _$identity);

  /// Serializes this Rts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rts&&const DeepCollectionEquality().equals(other.station, station)&&const DeepCollectionEquality().equals(other.box, box)&&const DeepCollectionEquality().equals(other.intensities, intensities)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(station),const DeepCollectionEquality().hash(box),const DeepCollectionEquality().hash(intensities),time);

@override
String toString() {
  return 'Rts(station: $station, box: $box, intensities: $intensities, time: $time)';
}


}

/// @nodoc
abstract mixin class $RtsCopyWith<$Res>  {
  factory $RtsCopyWith(Rts value, $Res Function(Rts) _then) = _$RtsCopyWithImpl;
@useResult
$Res call({
 Map<String, RtsStation> station, Map<String, dynamic> box,@JsonKey(name: 'int') List<dynamic> intensities, int time
});




}
/// @nodoc
class _$RtsCopyWithImpl<$Res>
    implements $RtsCopyWith<$Res> {
  _$RtsCopyWithImpl(this._self, this._then);

  final Rts _self;
  final $Res Function(Rts) _then;

/// Create a copy of Rts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? station = null,Object? box = null,Object? intensities = null,Object? time = null,}) {
  return _then(_self.copyWith(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as Map<String, RtsStation>,box: null == box ? _self.box : box // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,intensities: null == intensities ? _self.intensities : intensities // ignore: cast_nullable_to_non_nullable
as List<dynamic>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Rts].
extension RtsPatterns on Rts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rts value)  $default,){
final _that = this;
switch (_that) {
case _Rts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rts value)?  $default,){
final _that = this;
switch (_that) {
case _Rts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, RtsStation> station,  Map<String, dynamic> box, @JsonKey(name: 'int')  List<dynamic> intensities,  int time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rts() when $default != null:
return $default(_that.station,_that.box,_that.intensities,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, RtsStation> station,  Map<String, dynamic> box, @JsonKey(name: 'int')  List<dynamic> intensities,  int time)  $default,) {final _that = this;
switch (_that) {
case _Rts():
return $default(_that.station,_that.box,_that.intensities,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, RtsStation> station,  Map<String, dynamic> box, @JsonKey(name: 'int')  List<dynamic> intensities,  int time)?  $default,) {final _that = this;
switch (_that) {
case _Rts() when $default != null:
return $default(_that.station,_that.box,_that.intensities,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rts implements Rts {
  const _Rts({final  Map<String, RtsStation> station = const <String, RtsStation>{}, final  Map<String, dynamic> box = const <String, dynamic>{}, @JsonKey(name: 'int') final  List<dynamic> intensities = const <dynamic>[], this.time = 0}): _station = station,_box = box,_intensities = intensities;
  factory _Rts.fromJson(Map<String, dynamic> json) => _$RtsFromJson(json);

 final  Map<String, RtsStation> _station;
@override@JsonKey() Map<String, RtsStation> get station {
  if (_station is EqualUnmodifiableMapView) return _station;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_station);
}

 final  Map<String, dynamic> _box;
@override@JsonKey() Map<String, dynamic> get box {
  if (_box is EqualUnmodifiableMapView) return _box;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_box);
}

 final  List<dynamic> _intensities;
@override@JsonKey(name: 'int') List<dynamic> get intensities {
  if (_intensities is EqualUnmodifiableListView) return _intensities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_intensities);
}

@override@JsonKey() final  int time;

/// Create a copy of Rts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RtsCopyWith<_Rts> get copyWith => __$RtsCopyWithImpl<_Rts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RtsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rts&&const DeepCollectionEquality().equals(other._station, _station)&&const DeepCollectionEquality().equals(other._box, _box)&&const DeepCollectionEquality().equals(other._intensities, _intensities)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_station),const DeepCollectionEquality().hash(_box),const DeepCollectionEquality().hash(_intensities),time);

@override
String toString() {
  return 'Rts(station: $station, box: $box, intensities: $intensities, time: $time)';
}


}

/// @nodoc
abstract mixin class _$RtsCopyWith<$Res> implements $RtsCopyWith<$Res> {
  factory _$RtsCopyWith(_Rts value, $Res Function(_Rts) _then) = __$RtsCopyWithImpl;
@override @useResult
$Res call({
 Map<String, RtsStation> station, Map<String, dynamic> box,@JsonKey(name: 'int') List<dynamic> intensities, int time
});




}
/// @nodoc
class __$RtsCopyWithImpl<$Res>
    implements _$RtsCopyWith<$Res> {
  __$RtsCopyWithImpl(this._self, this._then);

  final _Rts _self;
  final $Res Function(_Rts) _then;

/// Create a copy of Rts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? station = null,Object? box = null,Object? intensities = null,Object? time = null,}) {
  return _then(_Rts(
station: null == station ? _self._station : station // ignore: cast_nullable_to_non_nullable
as Map<String, RtsStation>,box: null == box ? _self._box : box // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,intensities: null == intensities ? _self._intensities : intensities // ignore: cast_nullable_to_non_nullable
as List<dynamic>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RtsStation {

 double get pga; double get pgv;@JsonKey(name: 'i') double get intensityRaw;@JsonKey(name: 'I') int get intensity;
/// Create a copy of RtsStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RtsStationCopyWith<RtsStation> get copyWith => _$RtsStationCopyWithImpl<RtsStation>(this as RtsStation, _$identity);

  /// Serializes this RtsStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RtsStation&&(identical(other.pga, pga) || other.pga == pga)&&(identical(other.pgv, pgv) || other.pgv == pgv)&&(identical(other.intensityRaw, intensityRaw) || other.intensityRaw == intensityRaw)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pga,pgv,intensityRaw,intensity);

@override
String toString() {
  return 'RtsStation(pga: $pga, pgv: $pgv, intensityRaw: $intensityRaw, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $RtsStationCopyWith<$Res>  {
  factory $RtsStationCopyWith(RtsStation value, $Res Function(RtsStation) _then) = _$RtsStationCopyWithImpl;
@useResult
$Res call({
 double pga, double pgv,@JsonKey(name: 'i') double intensityRaw,@JsonKey(name: 'I') int intensity
});




}
/// @nodoc
class _$RtsStationCopyWithImpl<$Res>
    implements $RtsStationCopyWith<$Res> {
  _$RtsStationCopyWithImpl(this._self, this._then);

  final RtsStation _self;
  final $Res Function(RtsStation) _then;

/// Create a copy of RtsStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pga = null,Object? pgv = null,Object? intensityRaw = null,Object? intensity = null,}) {
  return _then(_self.copyWith(
pga: null == pga ? _self.pga : pga // ignore: cast_nullable_to_non_nullable
as double,pgv: null == pgv ? _self.pgv : pgv // ignore: cast_nullable_to_non_nullable
as double,intensityRaw: null == intensityRaw ? _self.intensityRaw : intensityRaw // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RtsStation].
extension RtsStationPatterns on RtsStation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RtsStation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RtsStation value)  $default,){
final _that = this;
switch (_that) {
case _RtsStation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RtsStation value)?  $default,){
final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double pga,  double pgv, @JsonKey(name: 'i')  double intensityRaw, @JsonKey(name: 'I')  int intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
return $default(_that.pga,_that.pgv,_that.intensityRaw,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double pga,  double pgv, @JsonKey(name: 'i')  double intensityRaw, @JsonKey(name: 'I')  int intensity)  $default,) {final _that = this;
switch (_that) {
case _RtsStation():
return $default(_that.pga,_that.pgv,_that.intensityRaw,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double pga,  double pgv, @JsonKey(name: 'i')  double intensityRaw, @JsonKey(name: 'I')  int intensity)?  $default,) {final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
return $default(_that.pga,_that.pgv,_that.intensityRaw,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RtsStation implements RtsStation {
  const _RtsStation({this.pga = 0.0, this.pgv = 0.0, @JsonKey(name: 'i') this.intensityRaw = 0.0, @JsonKey(name: 'I') this.intensity = 0});
  factory _RtsStation.fromJson(Map<String, dynamic> json) => _$RtsStationFromJson(json);

@override@JsonKey() final  double pga;
@override@JsonKey() final  double pgv;
@override@JsonKey(name: 'i') final  double intensityRaw;
@override@JsonKey(name: 'I') final  int intensity;

/// Create a copy of RtsStation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RtsStationCopyWith<_RtsStation> get copyWith => __$RtsStationCopyWithImpl<_RtsStation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RtsStationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RtsStation&&(identical(other.pga, pga) || other.pga == pga)&&(identical(other.pgv, pgv) || other.pgv == pgv)&&(identical(other.intensityRaw, intensityRaw) || other.intensityRaw == intensityRaw)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pga,pgv,intensityRaw,intensity);

@override
String toString() {
  return 'RtsStation(pga: $pga, pgv: $pgv, intensityRaw: $intensityRaw, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$RtsStationCopyWith<$Res> implements $RtsStationCopyWith<$Res> {
  factory _$RtsStationCopyWith(_RtsStation value, $Res Function(_RtsStation) _then) = __$RtsStationCopyWithImpl;
@override @useResult
$Res call({
 double pga, double pgv,@JsonKey(name: 'i') double intensityRaw,@JsonKey(name: 'I') int intensity
});




}
/// @nodoc
class __$RtsStationCopyWithImpl<$Res>
    implements _$RtsStationCopyWith<$Res> {
  __$RtsStationCopyWithImpl(this._self, this._then);

  final _RtsStation _self;
  final $Res Function(_RtsStation) _then;

/// Create a copy of RtsStation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pga = null,Object? pgv = null,Object? intensityRaw = null,Object? intensity = null,}) {
  return _then(_RtsStation(
pga: null == pga ? _self.pga : pga // ignore: cast_nullable_to_non_nullable
as double,pgv: null == pgv ? _self.pgv : pgv // ignore: cast_nullable_to_non_nullable
as double,intensityRaw: null == intensityRaw ? _self.intensityRaw : intensityRaw // ignore: cast_nullable_to_non_nullable
as double,intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
