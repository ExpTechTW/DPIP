// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typhoon_potential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ForecastPoint {

/// Human label from the wire (e.g. `07月14日14時`); display shortens via
/// [shortenTyphoonTimeLabel] to `14日14時`.
 String get label;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lng') double get longitude;
/// Create a copy of ForecastPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastPointCopyWith<ForecastPoint> get copyWith => _$ForecastPointCopyWithImpl<ForecastPoint>(this as ForecastPoint, _$identity);

  /// Serializes this ForecastPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastPoint&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude);

@override
String toString() {
  return 'ForecastPoint(label: $label, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $ForecastPointCopyWith<$Res>  {
  factory $ForecastPointCopyWith(ForecastPoint value, $Res Function(ForecastPoint) _then) = _$ForecastPointCopyWithImpl;
@useResult
$Res call({
 String label,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lng') double longitude
});




}
/// @nodoc
class _$ForecastPointCopyWithImpl<$Res>
    implements $ForecastPointCopyWith<$Res> {
  _$ForecastPointCopyWithImpl(this._self, this._then);

  final ForecastPoint _self;
  final $Res Function(ForecastPoint) _then;

/// Create a copy of ForecastPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ForecastPoint].
extension ForecastPointPatterns on ForecastPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForecastPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForecastPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForecastPoint value)  $default,){
final _that = this;
switch (_that) {
case _ForecastPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForecastPoint value)?  $default,){
final _that = this;
switch (_that) {
case _ForecastPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForecastPoint() when $default != null:
return $default(_that.label,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)  $default,) {final _that = this;
switch (_that) {
case _ForecastPoint():
return $default(_that.label,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lng')  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _ForecastPoint() when $default != null:
return $default(_that.label,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ForecastPoint implements ForecastPoint {
  const _ForecastPoint({required this.label, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lng') required this.longitude});
  factory _ForecastPoint.fromJson(Map<String, dynamic> json) => _$ForecastPointFromJson(json);

/// Human label from the wire (e.g. `07月14日14時`); display shortens via
/// [shortenTyphoonTimeLabel] to `14日14時`.
@override final  String label;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lng') final  double longitude;

/// Create a copy of ForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForecastPointCopyWith<_ForecastPoint> get copyWith => __$ForecastPointCopyWithImpl<_ForecastPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ForecastPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForecastPoint&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude);

@override
String toString() {
  return 'ForecastPoint(label: $label, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$ForecastPointCopyWith<$Res> implements $ForecastPointCopyWith<$Res> {
  factory _$ForecastPointCopyWith(_ForecastPoint value, $Res Function(_ForecastPoint) _then) = __$ForecastPointCopyWithImpl;
@override @useResult
$Res call({
 String label,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lng') double longitude
});




}
/// @nodoc
class __$ForecastPointCopyWithImpl<$Res>
    implements _$ForecastPointCopyWith<$Res> {
  __$ForecastPointCopyWithImpl(this._self, this._then);

  final _ForecastPoint _self;
  final $Res Function(_ForecastPoint) _then;

/// Create a copy of ForecastPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_ForecastPoint(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TyphoonPotential {

/// CWA tropical-depression number — unique within a snapshot.
 String? get tdNo;/// KML folder name (CWA Chinese name, or `TD15` for unnamed).
 String? get name;/// Observed past track.
 List<LatLng> get past;/// Predicted track.
 List<LatLng> get forecast;/// Track-potential (uncertainty) cone outline.
 List<LatLng> get cone;/// Symmetric level-7 wind circle (illustrative); null when too weak.
 List<LatLng>? get circle;/// Current centre; null when none.
 LatLng? get current;/// Labelled forecast waypoints.
 List<ForecastPoint> get points;
/// Create a copy of TyphoonPotential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TyphoonPotentialCopyWith<TyphoonPotential> get copyWith => _$TyphoonPotentialCopyWithImpl<TyphoonPotential>(this as TyphoonPotential, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TyphoonPotential&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.past, past)&&const DeepCollectionEquality().equals(other.forecast, forecast)&&const DeepCollectionEquality().equals(other.cone, cone)&&const DeepCollectionEquality().equals(other.circle, circle)&&(identical(other.current, current) || other.current == current)&&const DeepCollectionEquality().equals(other.points, points));
}


@override
int get hashCode => Object.hash(runtimeType,tdNo,name,const DeepCollectionEquality().hash(past),const DeepCollectionEquality().hash(forecast),const DeepCollectionEquality().hash(cone),const DeepCollectionEquality().hash(circle),current,const DeepCollectionEquality().hash(points));

@override
String toString() {
  return 'TyphoonPotential(tdNo: $tdNo, name: $name, past: $past, forecast: $forecast, cone: $cone, circle: $circle, current: $current, points: $points)';
}


}

/// @nodoc
abstract mixin class $TyphoonPotentialCopyWith<$Res>  {
  factory $TyphoonPotentialCopyWith(TyphoonPotential value, $Res Function(TyphoonPotential) _then) = _$TyphoonPotentialCopyWithImpl;
@useResult
$Res call({
 String? tdNo, String? name, List<LatLng> past, List<LatLng> forecast, List<LatLng> cone, List<LatLng>? circle, LatLng? current, List<ForecastPoint> points
});




}
/// @nodoc
class _$TyphoonPotentialCopyWithImpl<$Res>
    implements $TyphoonPotentialCopyWith<$Res> {
  _$TyphoonPotentialCopyWithImpl(this._self, this._then);

  final TyphoonPotential _self;
  final $Res Function(TyphoonPotential) _then;

/// Create a copy of TyphoonPotential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tdNo = freezed,Object? name = freezed,Object? past = null,Object? forecast = null,Object? cone = null,Object? circle = freezed,Object? current = freezed,Object? points = null,}) {
  return _then(_self.copyWith(
tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as List<LatLng>,forecast: null == forecast ? _self.forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<LatLng>,cone: null == cone ? _self.cone : cone // ignore: cast_nullable_to_non_nullable
as List<LatLng>,circle: freezed == circle ? _self.circle : circle // ignore: cast_nullable_to_non_nullable
as List<LatLng>?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as LatLng?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<ForecastPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [TyphoonPotential].
extension TyphoonPotentialPatterns on TyphoonPotential {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TyphoonPotential value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TyphoonPotential() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TyphoonPotential value)  $default,){
final _that = this;
switch (_that) {
case _TyphoonPotential():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TyphoonPotential value)?  $default,){
final _that = this;
switch (_that) {
case _TyphoonPotential() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? tdNo,  String? name,  List<LatLng> past,  List<LatLng> forecast,  List<LatLng> cone,  List<LatLng>? circle,  LatLng? current,  List<ForecastPoint> points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TyphoonPotential() when $default != null:
return $default(_that.tdNo,_that.name,_that.past,_that.forecast,_that.cone,_that.circle,_that.current,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? tdNo,  String? name,  List<LatLng> past,  List<LatLng> forecast,  List<LatLng> cone,  List<LatLng>? circle,  LatLng? current,  List<ForecastPoint> points)  $default,) {final _that = this;
switch (_that) {
case _TyphoonPotential():
return $default(_that.tdNo,_that.name,_that.past,_that.forecast,_that.cone,_that.circle,_that.current,_that.points);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? tdNo,  String? name,  List<LatLng> past,  List<LatLng> forecast,  List<LatLng> cone,  List<LatLng>? circle,  LatLng? current,  List<ForecastPoint> points)?  $default,) {final _that = this;
switch (_that) {
case _TyphoonPotential() when $default != null:
return $default(_that.tdNo,_that.name,_that.past,_that.forecast,_that.cone,_that.circle,_that.current,_that.points);case _:
  return null;

}
}

}

/// @nodoc


class _TyphoonPotential implements TyphoonPotential {
  const _TyphoonPotential({this.tdNo, this.name, required final  List<LatLng> past, required final  List<LatLng> forecast, required final  List<LatLng> cone, final  List<LatLng>? circle, this.current, required final  List<ForecastPoint> points}): _past = past,_forecast = forecast,_cone = cone,_circle = circle,_points = points;
  

/// CWA tropical-depression number — unique within a snapshot.
@override final  String? tdNo;
/// KML folder name (CWA Chinese name, or `TD15` for unnamed).
@override final  String? name;
/// Observed past track.
 final  List<LatLng> _past;
/// Observed past track.
@override List<LatLng> get past {
  if (_past is EqualUnmodifiableListView) return _past;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_past);
}

/// Predicted track.
 final  List<LatLng> _forecast;
/// Predicted track.
@override List<LatLng> get forecast {
  if (_forecast is EqualUnmodifiableListView) return _forecast;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_forecast);
}

/// Track-potential (uncertainty) cone outline.
 final  List<LatLng> _cone;
/// Track-potential (uncertainty) cone outline.
@override List<LatLng> get cone {
  if (_cone is EqualUnmodifiableListView) return _cone;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cone);
}

/// Symmetric level-7 wind circle (illustrative); null when too weak.
 final  List<LatLng>? _circle;
/// Symmetric level-7 wind circle (illustrative); null when too weak.
@override List<LatLng>? get circle {
  final value = _circle;
  if (value == null) return null;
  if (_circle is EqualUnmodifiableListView) return _circle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Current centre; null when none.
@override final  LatLng? current;
/// Labelled forecast waypoints.
 final  List<ForecastPoint> _points;
/// Labelled forecast waypoints.
@override List<ForecastPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}


/// Create a copy of TyphoonPotential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TyphoonPotentialCopyWith<_TyphoonPotential> get copyWith => __$TyphoonPotentialCopyWithImpl<_TyphoonPotential>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TyphoonPotential&&(identical(other.tdNo, tdNo) || other.tdNo == tdNo)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._past, _past)&&const DeepCollectionEquality().equals(other._forecast, _forecast)&&const DeepCollectionEquality().equals(other._cone, _cone)&&const DeepCollectionEquality().equals(other._circle, _circle)&&(identical(other.current, current) || other.current == current)&&const DeepCollectionEquality().equals(other._points, _points));
}


@override
int get hashCode => Object.hash(runtimeType,tdNo,name,const DeepCollectionEquality().hash(_past),const DeepCollectionEquality().hash(_forecast),const DeepCollectionEquality().hash(_cone),const DeepCollectionEquality().hash(_circle),current,const DeepCollectionEquality().hash(_points));

@override
String toString() {
  return 'TyphoonPotential(tdNo: $tdNo, name: $name, past: $past, forecast: $forecast, cone: $cone, circle: $circle, current: $current, points: $points)';
}


}

/// @nodoc
abstract mixin class _$TyphoonPotentialCopyWith<$Res> implements $TyphoonPotentialCopyWith<$Res> {
  factory _$TyphoonPotentialCopyWith(_TyphoonPotential value, $Res Function(_TyphoonPotential) _then) = __$TyphoonPotentialCopyWithImpl;
@override @useResult
$Res call({
 String? tdNo, String? name, List<LatLng> past, List<LatLng> forecast, List<LatLng> cone, List<LatLng>? circle, LatLng? current, List<ForecastPoint> points
});




}
/// @nodoc
class __$TyphoonPotentialCopyWithImpl<$Res>
    implements _$TyphoonPotentialCopyWith<$Res> {
  __$TyphoonPotentialCopyWithImpl(this._self, this._then);

  final _TyphoonPotential _self;
  final $Res Function(_TyphoonPotential) _then;

/// Create a copy of TyphoonPotential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tdNo = freezed,Object? name = freezed,Object? past = null,Object? forecast = null,Object? cone = null,Object? circle = freezed,Object? current = freezed,Object? points = null,}) {
  return _then(_TyphoonPotential(
tdNo: freezed == tdNo ? _self.tdNo : tdNo // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,past: null == past ? _self._past : past // ignore: cast_nullable_to_non_nullable
as List<LatLng>,forecast: null == forecast ? _self._forecast : forecast // ignore: cast_nullable_to_non_nullable
as List<LatLng>,cone: null == cone ? _self._cone : cone // ignore: cast_nullable_to_non_nullable
as List<LatLng>,circle: freezed == circle ? _self._circle : circle // ignore: cast_nullable_to_non_nullable
as List<LatLng>?,current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as LatLng?,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<ForecastPoint>,
  ));
}


}

/// @nodoc
mixin _$PotentialPayload {

 int get updated; List<TyphoonPotential> get cyclones;
/// Create a copy of PotentialPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PotentialPayloadCopyWith<PotentialPayload> get copyWith => _$PotentialPayloadCopyWithImpl<PotentialPayload>(this as PotentialPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PotentialPayload&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other.cyclones, cyclones));
}


@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(cyclones));

@override
String toString() {
  return 'PotentialPayload(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class $PotentialPayloadCopyWith<$Res>  {
  factory $PotentialPayloadCopyWith(PotentialPayload value, $Res Function(PotentialPayload) _then) = _$PotentialPayloadCopyWithImpl;
@useResult
$Res call({
 int updated, List<TyphoonPotential> cyclones
});




}
/// @nodoc
class _$PotentialPayloadCopyWithImpl<$Res>
    implements $PotentialPayloadCopyWith<$Res> {
  _$PotentialPayloadCopyWithImpl(this._self, this._then);

  final PotentialPayload _self;
  final $Res Function(PotentialPayload) _then;

/// Create a copy of PotentialPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_self.copyWith(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self.cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonPotential>,
  ));
}

}


/// Adds pattern-matching-related methods to [PotentialPayload].
extension PotentialPayloadPatterns on PotentialPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PotentialPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PotentialPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PotentialPayload value)  $default,){
final _that = this;
switch (_that) {
case _PotentialPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PotentialPayload value)?  $default,){
final _that = this;
switch (_that) {
case _PotentialPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updated,  List<TyphoonPotential> cyclones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PotentialPayload() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updated,  List<TyphoonPotential> cyclones)  $default,) {final _that = this;
switch (_that) {
case _PotentialPayload():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updated,  List<TyphoonPotential> cyclones)?  $default,) {final _that = this;
switch (_that) {
case _PotentialPayload() when $default != null:
return $default(_that.updated,_that.cyclones);case _:
  return null;

}
}

}

/// @nodoc


class _PotentialPayload implements PotentialPayload {
  const _PotentialPayload({required this.updated, required final  List<TyphoonPotential> cyclones}): _cyclones = cyclones;
  

@override final  int updated;
 final  List<TyphoonPotential> _cyclones;
@override List<TyphoonPotential> get cyclones {
  if (_cyclones is EqualUnmodifiableListView) return _cyclones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cyclones);
}


/// Create a copy of PotentialPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PotentialPayloadCopyWith<_PotentialPayload> get copyWith => __$PotentialPayloadCopyWithImpl<_PotentialPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PotentialPayload&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other._cyclones, _cyclones));
}


@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(_cyclones));

@override
String toString() {
  return 'PotentialPayload(updated: $updated, cyclones: $cyclones)';
}


}

/// @nodoc
abstract mixin class _$PotentialPayloadCopyWith<$Res> implements $PotentialPayloadCopyWith<$Res> {
  factory _$PotentialPayloadCopyWith(_PotentialPayload value, $Res Function(_PotentialPayload) _then) = __$PotentialPayloadCopyWithImpl;
@override @useResult
$Res call({
 int updated, List<TyphoonPotential> cyclones
});




}
/// @nodoc
class __$PotentialPayloadCopyWithImpl<$Res>
    implements _$PotentialPayloadCopyWith<$Res> {
  __$PotentialPayloadCopyWithImpl(this._self, this._then);

  final _PotentialPayload _self;
  final $Res Function(_PotentialPayload) _then;

/// Create a copy of PotentialPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,Object? cyclones = null,}) {
  return _then(_PotentialPayload(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,cyclones: null == cyclones ? _self._cyclones : cyclones // ignore: cast_nullable_to_non_nullable
as List<TyphoonPotential>,
  ));
}


}

// dart format on
