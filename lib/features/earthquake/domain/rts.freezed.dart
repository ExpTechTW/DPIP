// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rts {

 Map<String, RtsStation> get stations;@JsonKey(name: 'ts') int get time;
/// Create a copy of Rts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RtsCopyWith<Rts> get copyWith => _$RtsCopyWithImpl<Rts>(this as Rts, _$identity);

  /// Serializes this Rts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rts&&const DeepCollectionEquality().equals(other.stations, stations)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(stations),time);

@override
String toString() {
  return 'Rts(stations: $stations, time: $time)';
}


}

/// @nodoc
abstract mixin class $RtsCopyWith<$Res>  {
  factory $RtsCopyWith(Rts value, $Res Function(Rts) _then) = _$RtsCopyWithImpl;
@useResult
$Res call({
 Map<String, RtsStation> stations,@JsonKey(name: 'ts') int time
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
@pragma('vm:prefer-inline') @override $Res call({Object? stations = null,Object? time = null,}) {
  return _then(Rts(
stations: null == stations ? _self.stations : stations // ignore: cast_nullable_to_non_nullable
as Map<String, RtsStation>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, RtsStation> stations, @JsonKey(name: 'ts')  int time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rts() when $default != null:
return $default(_that.stations,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, RtsStation> stations, @JsonKey(name: 'ts')  int time)  $default,) {final _that = this;
switch (_that) {
case _Rts():
return $default(_that.stations,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, RtsStation> stations, @JsonKey(name: 'ts')  int time)?  $default,) {final _that = this;
switch (_that) {
case _Rts() when $default != null:
return $default(_that.stations,_that.time);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rts implements Rts {
  const _Rts({ Map<String, RtsStation> stations = const <String, RtsStation>{}, @JsonKey(name: 'ts') this.time = 0}): _stations = stations;
  factory _Rts.fromJson(Map<String, dynamic> json) => _$RtsFromJson(json);

 final  Map<String, RtsStation> _stations;
@override@JsonKey() Map<String, RtsStation> get stations {
  if (_stations is EqualUnmodifiableMapView) return _stations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stations);
}

@override@JsonKey(name: 'ts') final  int time;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rts&&const DeepCollectionEquality().equals(other._stations, _stations)&&(identical(other.time, time) || other.time == time));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_stations),time);

@override
String toString() {
  return 'Rts(stations: $stations, time: $time)';
}


}

/// @nodoc
abstract mixin class _$RtsCopyWith<$Res> implements $RtsCopyWith<$Res> {
  factory _$RtsCopyWith(_Rts value, $Res Function(_Rts) _then) = __$RtsCopyWithImpl;
@override @useResult
$Res call({
 Map<String, RtsStation> stations,@JsonKey(name: 'ts') int time
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
@override @pragma('vm:prefer-inline') $Res call({Object? stations = null,Object? time = null,}) {
  return _then(_Rts(
stations: null == stations ? _self._stations : stations // ignore: cast_nullable_to_non_nullable
as Map<String, RtsStation>,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RtsStation {

@JsonKey(name: 'i') double get intensity; double get pga;@JsonKey(fromJson: boolishInt, toJson: intFromBool) bool get alert;
/// Create a copy of RtsStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RtsStationCopyWith<RtsStation> get copyWith => _$RtsStationCopyWithImpl<RtsStation>(this as RtsStation, _$identity);

  /// Serializes this RtsStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RtsStation&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.pga, pga) || other.pga == pga)&&(identical(other.alert, alert) || other.alert == alert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,pga,alert);

@override
String toString() {
  return 'RtsStation(intensity: $intensity, pga: $pga, alert: $alert)';
}


}

/// @nodoc
abstract mixin class $RtsStationCopyWith<$Res>  {
  factory $RtsStationCopyWith(RtsStation value, $Res Function(RtsStation) _then) = _$RtsStationCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'i') double intensity, double pga,@JsonKey(fromJson: boolishInt, toJson: intFromBool) bool alert
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
@pragma('vm:prefer-inline') @override $Res call({Object? intensity = null,Object? pga = null,Object? alert = null,}) {
  return _then(RtsStation(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,pga: null == pga ? _self.pga : pga // ignore: cast_nullable_to_non_nullable
as double,alert: null == alert ? _self.alert : alert // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'i')  double intensity,  double pga, @JsonKey(fromJson: boolishInt, toJson: intFromBool)  bool alert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
return $default(_that.intensity,_that.pga,_that.alert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'i')  double intensity,  double pga, @JsonKey(fromJson: boolishInt, toJson: intFromBool)  bool alert)  $default,) {final _that = this;
switch (_that) {
case _RtsStation():
return $default(_that.intensity,_that.pga,_that.alert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'i')  double intensity,  double pga, @JsonKey(fromJson: boolishInt, toJson: intFromBool)  bool alert)?  $default,) {final _that = this;
switch (_that) {
case _RtsStation() when $default != null:
return $default(_that.intensity,_that.pga,_that.alert);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RtsStation implements RtsStation {
  const _RtsStation({@JsonKey(name: 'i') this.intensity = 0.0, this.pga = 0.0, @JsonKey(fromJson: boolishInt, toJson: intFromBool) this.alert = false});
  factory _RtsStation.fromJson(Map<String, dynamic> json) => _$RtsStationFromJson(json);

@override@JsonKey(name: 'i') final  double intensity;
@override@JsonKey() final  double pga;
@override@JsonKey(fromJson: boolishInt, toJson: intFromBool) final  bool alert;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RtsStation&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.pga, pga) || other.pga == pga)&&(identical(other.alert, alert) || other.alert == alert));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,pga,alert);

@override
String toString() {
  return 'RtsStation(intensity: $intensity, pga: $pga, alert: $alert)';
}


}

/// @nodoc
abstract mixin class _$RtsStationCopyWith<$Res> implements $RtsStationCopyWith<$Res> {
  factory _$RtsStationCopyWith(_RtsStation value, $Res Function(_RtsStation) _then) = __$RtsStationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'i') double intensity, double pga,@JsonKey(fromJson: boolishInt, toJson: intFromBool) bool alert
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
@override @pragma('vm:prefer-inline') $Res call({Object? intensity = null,Object? pga = null,Object? alert = null,}) {
  return _then(_RtsStation(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,pga: null == pga ? _self.pga : pga // ignore: cast_nullable_to_non_nullable
as double,alert: null == alert ? _self.alert : alert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
