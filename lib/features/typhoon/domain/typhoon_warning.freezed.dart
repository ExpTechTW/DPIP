// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typhoon_warning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WarningFix {

@JsonKey(name: 't') int get time;@JsonKey(name: 'lat') double get latitude;@JsonKey(name: 'lon') double get longitude;/// Sustained wind (m/s).
 double? get wind;/// Gust (m/s).
 double? get gust;/// Central pressure (hPa).
@JsonKey(name: 'pres') double? get pressure;/// Level-7 wind radius (km).
 double? get r15;/// Intensity as a `[中文, English]` pair; null when unclassified.
 List<String>? get scale;
/// Create a copy of WarningFix
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningFixCopyWith<WarningFix> get copyWith => _$WarningFixCopyWithImpl<WarningFix>(this as WarningFix, _$identity);

  /// Serializes this WarningFix to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarningFix&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.r15, r15) || other.r15 == r15)&&const DeepCollectionEquality().equals(other.scale, scale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,latitude,longitude,wind,gust,pressure,r15,const DeepCollectionEquality().hash(scale));

@override
String toString() {
  return 'WarningFix(time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, r15: $r15, scale: $scale)';
}


}

/// @nodoc
abstract mixin class $WarningFixCopyWith<$Res>  {
  factory $WarningFixCopyWith(WarningFix value, $Res Function(WarningFix) _then) = _$WarningFixCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? r15, List<String>? scale
});




}
/// @nodoc
class _$WarningFixCopyWithImpl<$Res>
    implements $WarningFixCopyWith<$Res> {
  _$WarningFixCopyWithImpl(this._self, this._then);

  final WarningFix _self;
  final $Res Function(WarningFix) _then;

/// Create a copy of WarningFix
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? r15 = freezed,Object? scale = freezed,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,r15: freezed == r15 ? _self.r15 : r15 // ignore: cast_nullable_to_non_nullable
as double?,scale: freezed == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [WarningFix].
extension WarningFixPatterns on WarningFix {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarningFix value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarningFix() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarningFix value)  $default,){
final _that = this;
switch (_that) {
case _WarningFix():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarningFix value)?  $default,){
final _that = this;
switch (_that) {
case _WarningFix() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? r15,  List<String>? scale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarningFix() when $default != null:
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.r15,_that.scale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? r15,  List<String>? scale)  $default,) {final _that = this;
switch (_that) {
case _WarningFix():
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.r15,_that.scale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int time, @JsonKey(name: 'lat')  double latitude, @JsonKey(name: 'lon')  double longitude,  double? wind,  double? gust, @JsonKey(name: 'pres')  double? pressure,  double? r15,  List<String>? scale)?  $default,) {final _that = this;
switch (_that) {
case _WarningFix() when $default != null:
return $default(_that.time,_that.latitude,_that.longitude,_that.wind,_that.gust,_that.pressure,_that.r15,_that.scale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarningFix implements WarningFix {
  const _WarningFix({@JsonKey(name: 't') required this.time, @JsonKey(name: 'lat') required this.latitude, @JsonKey(name: 'lon') required this.longitude, this.wind, this.gust, @JsonKey(name: 'pres') this.pressure, this.r15, final  List<String>? scale}): _scale = scale;
  factory _WarningFix.fromJson(Map<String, dynamic> json) => _$WarningFixFromJson(json);

@override@JsonKey(name: 't') final  int time;
@override@JsonKey(name: 'lat') final  double latitude;
@override@JsonKey(name: 'lon') final  double longitude;
/// Sustained wind (m/s).
@override final  double? wind;
/// Gust (m/s).
@override final  double? gust;
/// Central pressure (hPa).
@override@JsonKey(name: 'pres') final  double? pressure;
/// Level-7 wind radius (km).
@override final  double? r15;
/// Intensity as a `[中文, English]` pair; null when unclassified.
 final  List<String>? _scale;
/// Intensity as a `[中文, English]` pair; null when unclassified.
@override List<String>? get scale {
  final value = _scale;
  if (value == null) return null;
  if (_scale is EqualUnmodifiableListView) return _scale;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of WarningFix
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningFixCopyWith<_WarningFix> get copyWith => __$WarningFixCopyWithImpl<_WarningFix>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarningFixToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarningFix&&(identical(other.time, time) || other.time == time)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.wind, wind) || other.wind == wind)&&(identical(other.gust, gust) || other.gust == gust)&&(identical(other.pressure, pressure) || other.pressure == pressure)&&(identical(other.r15, r15) || other.r15 == r15)&&const DeepCollectionEquality().equals(other._scale, _scale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,time,latitude,longitude,wind,gust,pressure,r15,const DeepCollectionEquality().hash(_scale));

@override
String toString() {
  return 'WarningFix(time: $time, latitude: $latitude, longitude: $longitude, wind: $wind, gust: $gust, pressure: $pressure, r15: $r15, scale: $scale)';
}


}

/// @nodoc
abstract mixin class _$WarningFixCopyWith<$Res> implements $WarningFixCopyWith<$Res> {
  factory _$WarningFixCopyWith(_WarningFix value, $Res Function(_WarningFix) _then) = __$WarningFixCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int time,@JsonKey(name: 'lat') double latitude,@JsonKey(name: 'lon') double longitude, double? wind, double? gust,@JsonKey(name: 'pres') double? pressure, double? r15, List<String>? scale
});




}
/// @nodoc
class __$WarningFixCopyWithImpl<$Res>
    implements _$WarningFixCopyWith<$Res> {
  __$WarningFixCopyWithImpl(this._self, this._then);

  final _WarningFix _self;
  final $Res Function(_WarningFix) _then;

/// Create a copy of WarningFix
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? latitude = null,Object? longitude = null,Object? wind = freezed,Object? gust = freezed,Object? pressure = freezed,Object? r15 = freezed,Object? scale = freezed,}) {
  return _then(_WarningFix(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,wind: freezed == wind ? _self.wind : wind // ignore: cast_nullable_to_non_nullable
as double?,gust: freezed == gust ? _self.gust : gust // ignore: cast_nullable_to_non_nullable
as double?,pressure: freezed == pressure ? _self.pressure : pressure // ignore: cast_nullable_to_non_nullable
as double?,r15: freezed == r15 ? _self.r15 : r15 // ignore: cast_nullable_to_non_nullable
as double?,scale: freezed == scale ? _self._scale : scale // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$WarningTyphoon {

/// CWA typhoon number.
 String? get no; String get name; String? get cwaName;/// Bulletin report number.
 String? get reportNo;/// Category (e.g. `END`).
 String? get category; WarningFix get analysis; WarningFix? get prediction;
/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningTyphoonCopyWith<WarningTyphoon> get copyWith => _$WarningTyphoonCopyWithImpl<WarningTyphoon>(this as WarningTyphoon, _$identity);

  /// Serializes this WarningTyphoon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarningTyphoon&&(identical(other.no, no) || other.no == no)&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.reportNo, reportNo) || other.reportNo == reportNo)&&(identical(other.category, category) || other.category == category)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.prediction, prediction) || other.prediction == prediction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,no,name,cwaName,reportNo,category,analysis,prediction);

@override
String toString() {
  return 'WarningTyphoon(no: $no, name: $name, cwaName: $cwaName, reportNo: $reportNo, category: $category, analysis: $analysis, prediction: $prediction)';
}


}

/// @nodoc
abstract mixin class $WarningTyphoonCopyWith<$Res>  {
  factory $WarningTyphoonCopyWith(WarningTyphoon value, $Res Function(WarningTyphoon) _then) = _$WarningTyphoonCopyWithImpl;
@useResult
$Res call({
 String? no, String name, String? cwaName, String? reportNo, String? category, WarningFix analysis, WarningFix? prediction
});


$WarningFixCopyWith<$Res> get analysis;$WarningFixCopyWith<$Res>? get prediction;

}
/// @nodoc
class _$WarningTyphoonCopyWithImpl<$Res>
    implements $WarningTyphoonCopyWith<$Res> {
  _$WarningTyphoonCopyWithImpl(this._self, this._then);

  final WarningTyphoon _self;
  final $Res Function(WarningTyphoon) _then;

/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? no = freezed,Object? name = null,Object? cwaName = freezed,Object? reportNo = freezed,Object? category = freezed,Object? analysis = null,Object? prediction = freezed,}) {
  return _then(_self.copyWith(
no: freezed == no ? _self.no : no // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,reportNo: freezed == reportNo ? _self.reportNo : reportNo // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,analysis: null == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as WarningFix,prediction: freezed == prediction ? _self.prediction : prediction // ignore: cast_nullable_to_non_nullable
as WarningFix?,
  ));
}
/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningFixCopyWith<$Res> get analysis {
  
  return $WarningFixCopyWith<$Res>(_self.analysis, (value) {
    return _then(_self.copyWith(analysis: value));
  });
}/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningFixCopyWith<$Res>? get prediction {
    if (_self.prediction == null) {
    return null;
  }

  return $WarningFixCopyWith<$Res>(_self.prediction!, (value) {
    return _then(_self.copyWith(prediction: value));
  });
}
}


/// Adds pattern-matching-related methods to [WarningTyphoon].
extension WarningTyphoonPatterns on WarningTyphoon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarningTyphoon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarningTyphoon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarningTyphoon value)  $default,){
final _that = this;
switch (_that) {
case _WarningTyphoon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarningTyphoon value)?  $default,){
final _that = this;
switch (_that) {
case _WarningTyphoon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? no,  String name,  String? cwaName,  String? reportNo,  String? category,  WarningFix analysis,  WarningFix? prediction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarningTyphoon() when $default != null:
return $default(_that.no,_that.name,_that.cwaName,_that.reportNo,_that.category,_that.analysis,_that.prediction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? no,  String name,  String? cwaName,  String? reportNo,  String? category,  WarningFix analysis,  WarningFix? prediction)  $default,) {final _that = this;
switch (_that) {
case _WarningTyphoon():
return $default(_that.no,_that.name,_that.cwaName,_that.reportNo,_that.category,_that.analysis,_that.prediction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? no,  String name,  String? cwaName,  String? reportNo,  String? category,  WarningFix analysis,  WarningFix? prediction)?  $default,) {final _that = this;
switch (_that) {
case _WarningTyphoon() when $default != null:
return $default(_that.no,_that.name,_that.cwaName,_that.reportNo,_that.category,_that.analysis,_that.prediction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarningTyphoon implements WarningTyphoon {
  const _WarningTyphoon({this.no, required this.name, this.cwaName, this.reportNo, this.category, required this.analysis, this.prediction});
  factory _WarningTyphoon.fromJson(Map<String, dynamic> json) => _$WarningTyphoonFromJson(json);

/// CWA typhoon number.
@override final  String? no;
@override final  String name;
@override final  String? cwaName;
/// Bulletin report number.
@override final  String? reportNo;
/// Category (e.g. `END`).
@override final  String? category;
@override final  WarningFix analysis;
@override final  WarningFix? prediction;

/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningTyphoonCopyWith<_WarningTyphoon> get copyWith => __$WarningTyphoonCopyWithImpl<_WarningTyphoon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarningTyphoonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarningTyphoon&&(identical(other.no, no) || other.no == no)&&(identical(other.name, name) || other.name == name)&&(identical(other.cwaName, cwaName) || other.cwaName == cwaName)&&(identical(other.reportNo, reportNo) || other.reportNo == reportNo)&&(identical(other.category, category) || other.category == category)&&(identical(other.analysis, analysis) || other.analysis == analysis)&&(identical(other.prediction, prediction) || other.prediction == prediction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,no,name,cwaName,reportNo,category,analysis,prediction);

@override
String toString() {
  return 'WarningTyphoon(no: $no, name: $name, cwaName: $cwaName, reportNo: $reportNo, category: $category, analysis: $analysis, prediction: $prediction)';
}


}

/// @nodoc
abstract mixin class _$WarningTyphoonCopyWith<$Res> implements $WarningTyphoonCopyWith<$Res> {
  factory _$WarningTyphoonCopyWith(_WarningTyphoon value, $Res Function(_WarningTyphoon) _then) = __$WarningTyphoonCopyWithImpl;
@override @useResult
$Res call({
 String? no, String name, String? cwaName, String? reportNo, String? category, WarningFix analysis, WarningFix? prediction
});


@override $WarningFixCopyWith<$Res> get analysis;@override $WarningFixCopyWith<$Res>? get prediction;

}
/// @nodoc
class __$WarningTyphoonCopyWithImpl<$Res>
    implements _$WarningTyphoonCopyWith<$Res> {
  __$WarningTyphoonCopyWithImpl(this._self, this._then);

  final _WarningTyphoon _self;
  final $Res Function(_WarningTyphoon) _then;

/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? no = freezed,Object? name = null,Object? cwaName = freezed,Object? reportNo = freezed,Object? category = freezed,Object? analysis = null,Object? prediction = freezed,}) {
  return _then(_WarningTyphoon(
no: freezed == no ? _self.no : no // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,cwaName: freezed == cwaName ? _self.cwaName : cwaName // ignore: cast_nullable_to_non_nullable
as String?,reportNo: freezed == reportNo ? _self.reportNo : reportNo // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,analysis: null == analysis ? _self.analysis : analysis // ignore: cast_nullable_to_non_nullable
as WarningFix,prediction: freezed == prediction ? _self.prediction : prediction // ignore: cast_nullable_to_non_nullable
as WarningFix?,
  ));
}

/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningFixCopyWith<$Res> get analysis {
  
  return $WarningFixCopyWith<$Res>(_self.analysis, (value) {
    return _then(_self.copyWith(analysis: value));
  });
}/// Create a copy of WarningTyphoon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningFixCopyWith<$Res>? get prediction {
    if (_self.prediction == null) {
    return null;
  }

  return $WarningFixCopyWith<$Res>(_self.prediction!, (value) {
    return _then(_self.copyWith(prediction: value));
  });
}
}


/// @nodoc
mixin _$WarningSection {

 String get title; String get text;
/// Create a copy of WarningSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningSectionCopyWith<WarningSection> get copyWith => _$WarningSectionCopyWithImpl<WarningSection>(this as WarningSection, _$identity);

  /// Serializes this WarningSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarningSection&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text);

@override
String toString() {
  return 'WarningSection(title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class $WarningSectionCopyWith<$Res>  {
  factory $WarningSectionCopyWith(WarningSection value, $Res Function(WarningSection) _then) = _$WarningSectionCopyWithImpl;
@useResult
$Res call({
 String title, String text
});




}
/// @nodoc
class _$WarningSectionCopyWithImpl<$Res>
    implements $WarningSectionCopyWith<$Res> {
  _$WarningSectionCopyWithImpl(this._self, this._then);

  final WarningSection _self;
  final $Res Function(WarningSection) _then;

/// Create a copy of WarningSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? text = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WarningSection].
extension WarningSectionPatterns on WarningSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarningSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarningSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarningSection value)  $default,){
final _that = this;
switch (_that) {
case _WarningSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarningSection value)?  $default,){
final _that = this;
switch (_that) {
case _WarningSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarningSection() when $default != null:
return $default(_that.title,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String text)  $default,) {final _that = this;
switch (_that) {
case _WarningSection():
return $default(_that.title,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String text)?  $default,) {final _that = this;
switch (_that) {
case _WarningSection() when $default != null:
return $default(_that.title,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarningSection implements WarningSection {
  const _WarningSection({required this.title, required this.text});
  factory _WarningSection.fromJson(Map<String, dynamic> json) => _$WarningSectionFromJson(json);

@override final  String title;
@override final  String text;

/// Create a copy of WarningSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningSectionCopyWith<_WarningSection> get copyWith => __$WarningSectionCopyWithImpl<_WarningSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarningSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarningSection&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text);

@override
String toString() {
  return 'WarningSection(title: $title, text: $text)';
}


}

/// @nodoc
abstract mixin class _$WarningSectionCopyWith<$Res> implements $WarningSectionCopyWith<$Res> {
  factory _$WarningSectionCopyWith(_WarningSection value, $Res Function(_WarningSection) _then) = __$WarningSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, String text
});




}
/// @nodoc
class __$WarningSectionCopyWithImpl<$Res>
    implements _$WarningSectionCopyWith<$Res> {
  __$WarningSectionCopyWithImpl(this._self, this._then);

  final _WarningSection _self;
  final $Res Function(_WarningSection) _then;

/// Create a copy of WarningSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? text = null,}) {
  return _then(_WarningSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WarningArea {

 String get name; String get code;
/// Create a copy of WarningArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningAreaCopyWith<WarningArea> get copyWith => _$WarningAreaCopyWithImpl<WarningArea>(this as WarningArea, _$identity);

  /// Serializes this WarningArea to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarningArea&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,code);

@override
String toString() {
  return 'WarningArea(name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class $WarningAreaCopyWith<$Res>  {
  factory $WarningAreaCopyWith(WarningArea value, $Res Function(WarningArea) _then) = _$WarningAreaCopyWithImpl;
@useResult
$Res call({
 String name, String code
});




}
/// @nodoc
class _$WarningAreaCopyWithImpl<$Res>
    implements $WarningAreaCopyWith<$Res> {
  _$WarningAreaCopyWithImpl(this._self, this._then);

  final WarningArea _self;
  final $Res Function(WarningArea) _then;

/// Create a copy of WarningArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? code = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WarningArea].
extension WarningAreaPatterns on WarningArea {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarningArea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarningArea() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarningArea value)  $default,){
final _that = this;
switch (_that) {
case _WarningArea():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarningArea value)?  $default,){
final _that = this;
switch (_that) {
case _WarningArea() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarningArea() when $default != null:
return $default(_that.name,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String code)  $default,) {final _that = this;
switch (_that) {
case _WarningArea():
return $default(_that.name,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String code)?  $default,) {final _that = this;
switch (_that) {
case _WarningArea() when $default != null:
return $default(_that.name,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarningArea implements WarningArea {
  const _WarningArea({required this.name, required this.code});
  factory _WarningArea.fromJson(Map<String, dynamic> json) => _$WarningAreaFromJson(json);

@override final  String name;
@override final  String code;

/// Create a copy of WarningArea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningAreaCopyWith<_WarningArea> get copyWith => __$WarningAreaCopyWithImpl<_WarningArea>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarningAreaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarningArea&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,code);

@override
String toString() {
  return 'WarningArea(name: $name, code: $code)';
}


}

/// @nodoc
abstract mixin class _$WarningAreaCopyWith<$Res> implements $WarningAreaCopyWith<$Res> {
  factory _$WarningAreaCopyWith(_WarningArea value, $Res Function(_WarningArea) _then) = __$WarningAreaCopyWithImpl;
@override @useResult
$Res call({
 String name, String code
});




}
/// @nodoc
class __$WarningAreaCopyWithImpl<$Res>
    implements _$WarningAreaCopyWith<$Res> {
  __$WarningAreaCopyWithImpl(this._self, this._then);

  final _WarningArea _self;
  final $Res Function(_WarningArea) _then;

/// Create a copy of WarningArea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? code = null,}) {
  return _then(_WarningArea(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TyphoonWarning {

 bool get active; String get id;/// Bulletin send time (Unix seconds).
 int get sent; String get status; String get msgType; String get scope; String get event; String get urgency; String get severity; String get certainty;/// Effective / onset / expiry times (Unix seconds).
 int get effective; int get onset; int get expires; String get headline; String get senderName;/// The warned typhoon; null when the bulletin carries no typhoon block.
 WarningTyphoon? get typhoon;/// Warning body text, section by section.
 List<WarningSection> get sections;/// Affected counties/cities.
 List<WarningArea> get areas;
/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TyphoonWarningCopyWith<TyphoonWarning> get copyWith => _$TyphoonWarningCopyWithImpl<TyphoonWarning>(this as TyphoonWarning, _$identity);

  /// Serializes this TyphoonWarning to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TyphoonWarning&&(identical(other.active, active) || other.active == active)&&(identical(other.id, id) || other.id == id)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.status, status) || other.status == status)&&(identical(other.msgType, msgType) || other.msgType == msgType)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.event, event) || other.event == event)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.certainty, certainty) || other.certainty == certainty)&&(identical(other.effective, effective) || other.effective == effective)&&(identical(other.onset, onset) || other.onset == onset)&&(identical(other.expires, expires) || other.expires == expires)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.typhoon, typhoon) || other.typhoon == typhoon)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.areas, areas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,active,id,sent,status,msgType,scope,event,urgency,severity,certainty,effective,onset,expires,headline,senderName,typhoon,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(areas));

@override
String toString() {
  return 'TyphoonWarning(active: $active, id: $id, sent: $sent, status: $status, msgType: $msgType, scope: $scope, event: $event, urgency: $urgency, severity: $severity, certainty: $certainty, effective: $effective, onset: $onset, expires: $expires, headline: $headline, senderName: $senderName, typhoon: $typhoon, sections: $sections, areas: $areas)';
}


}

/// @nodoc
abstract mixin class $TyphoonWarningCopyWith<$Res>  {
  factory $TyphoonWarningCopyWith(TyphoonWarning value, $Res Function(TyphoonWarning) _then) = _$TyphoonWarningCopyWithImpl;
@useResult
$Res call({
 bool active, String id, int sent, String status, String msgType, String scope, String event, String urgency, String severity, String certainty, int effective, int onset, int expires, String headline, String senderName, WarningTyphoon? typhoon, List<WarningSection> sections, List<WarningArea> areas
});


$WarningTyphoonCopyWith<$Res>? get typhoon;

}
/// @nodoc
class _$TyphoonWarningCopyWithImpl<$Res>
    implements $TyphoonWarningCopyWith<$Res> {
  _$TyphoonWarningCopyWithImpl(this._self, this._then);

  final TyphoonWarning _self;
  final $Res Function(TyphoonWarning) _then;

/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? active = null,Object? id = null,Object? sent = null,Object? status = null,Object? msgType = null,Object? scope = null,Object? event = null,Object? urgency = null,Object? severity = null,Object? certainty = null,Object? effective = null,Object? onset = null,Object? expires = null,Object? headline = null,Object? senderName = null,Object? typhoon = freezed,Object? sections = null,Object? areas = null,}) {
  return _then(_self.copyWith(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,msgType: null == msgType ? _self.msgType : msgType // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,certainty: null == certainty ? _self.certainty : certainty // ignore: cast_nullable_to_non_nullable
as String,effective: null == effective ? _self.effective : effective // ignore: cast_nullable_to_non_nullable
as int,onset: null == onset ? _self.onset : onset // ignore: cast_nullable_to_non_nullable
as int,expires: null == expires ? _self.expires : expires // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,typhoon: freezed == typhoon ? _self.typhoon : typhoon // ignore: cast_nullable_to_non_nullable
as WarningTyphoon?,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<WarningSection>,areas: null == areas ? _self.areas : areas // ignore: cast_nullable_to_non_nullable
as List<WarningArea>,
  ));
}
/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningTyphoonCopyWith<$Res>? get typhoon {
    if (_self.typhoon == null) {
    return null;
  }

  return $WarningTyphoonCopyWith<$Res>(_self.typhoon!, (value) {
    return _then(_self.copyWith(typhoon: value));
  });
}
}


/// Adds pattern-matching-related methods to [TyphoonWarning].
extension TyphoonWarningPatterns on TyphoonWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TyphoonWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TyphoonWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TyphoonWarning value)  $default,){
final _that = this;
switch (_that) {
case _TyphoonWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TyphoonWarning value)?  $default,){
final _that = this;
switch (_that) {
case _TyphoonWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool active,  String id,  int sent,  String status,  String msgType,  String scope,  String event,  String urgency,  String severity,  String certainty,  int effective,  int onset,  int expires,  String headline,  String senderName,  WarningTyphoon? typhoon,  List<WarningSection> sections,  List<WarningArea> areas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TyphoonWarning() when $default != null:
return $default(_that.active,_that.id,_that.sent,_that.status,_that.msgType,_that.scope,_that.event,_that.urgency,_that.severity,_that.certainty,_that.effective,_that.onset,_that.expires,_that.headline,_that.senderName,_that.typhoon,_that.sections,_that.areas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool active,  String id,  int sent,  String status,  String msgType,  String scope,  String event,  String urgency,  String severity,  String certainty,  int effective,  int onset,  int expires,  String headline,  String senderName,  WarningTyphoon? typhoon,  List<WarningSection> sections,  List<WarningArea> areas)  $default,) {final _that = this;
switch (_that) {
case _TyphoonWarning():
return $default(_that.active,_that.id,_that.sent,_that.status,_that.msgType,_that.scope,_that.event,_that.urgency,_that.severity,_that.certainty,_that.effective,_that.onset,_that.expires,_that.headline,_that.senderName,_that.typhoon,_that.sections,_that.areas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool active,  String id,  int sent,  String status,  String msgType,  String scope,  String event,  String urgency,  String severity,  String certainty,  int effective,  int onset,  int expires,  String headline,  String senderName,  WarningTyphoon? typhoon,  List<WarningSection> sections,  List<WarningArea> areas)?  $default,) {final _that = this;
switch (_that) {
case _TyphoonWarning() when $default != null:
return $default(_that.active,_that.id,_that.sent,_that.status,_that.msgType,_that.scope,_that.event,_that.urgency,_that.severity,_that.certainty,_that.effective,_that.onset,_that.expires,_that.headline,_that.senderName,_that.typhoon,_that.sections,_that.areas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TyphoonWarning implements TyphoonWarning {
  const _TyphoonWarning({required this.active, required this.id, required this.sent, required this.status, required this.msgType, required this.scope, required this.event, required this.urgency, required this.severity, required this.certainty, required this.effective, required this.onset, required this.expires, required this.headline, required this.senderName, this.typhoon, required final  List<WarningSection> sections, required final  List<WarningArea> areas}): _sections = sections,_areas = areas;
  factory _TyphoonWarning.fromJson(Map<String, dynamic> json) => _$TyphoonWarningFromJson(json);

@override final  bool active;
@override final  String id;
/// Bulletin send time (Unix seconds).
@override final  int sent;
@override final  String status;
@override final  String msgType;
@override final  String scope;
@override final  String event;
@override final  String urgency;
@override final  String severity;
@override final  String certainty;
/// Effective / onset / expiry times (Unix seconds).
@override final  int effective;
@override final  int onset;
@override final  int expires;
@override final  String headline;
@override final  String senderName;
/// The warned typhoon; null when the bulletin carries no typhoon block.
@override final  WarningTyphoon? typhoon;
/// Warning body text, section by section.
 final  List<WarningSection> _sections;
/// Warning body text, section by section.
@override List<WarningSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Affected counties/cities.
 final  List<WarningArea> _areas;
/// Affected counties/cities.
@override List<WarningArea> get areas {
  if (_areas is EqualUnmodifiableListView) return _areas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_areas);
}


/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TyphoonWarningCopyWith<_TyphoonWarning> get copyWith => __$TyphoonWarningCopyWithImpl<_TyphoonWarning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TyphoonWarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TyphoonWarning&&(identical(other.active, active) || other.active == active)&&(identical(other.id, id) || other.id == id)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.status, status) || other.status == status)&&(identical(other.msgType, msgType) || other.msgType == msgType)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.event, event) || other.event == event)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.certainty, certainty) || other.certainty == certainty)&&(identical(other.effective, effective) || other.effective == effective)&&(identical(other.onset, onset) || other.onset == onset)&&(identical(other.expires, expires) || other.expires == expires)&&(identical(other.headline, headline) || other.headline == headline)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.typhoon, typhoon) || other.typhoon == typhoon)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._areas, _areas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,active,id,sent,status,msgType,scope,event,urgency,severity,certainty,effective,onset,expires,headline,senderName,typhoon,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_areas));

@override
String toString() {
  return 'TyphoonWarning(active: $active, id: $id, sent: $sent, status: $status, msgType: $msgType, scope: $scope, event: $event, urgency: $urgency, severity: $severity, certainty: $certainty, effective: $effective, onset: $onset, expires: $expires, headline: $headline, senderName: $senderName, typhoon: $typhoon, sections: $sections, areas: $areas)';
}


}

/// @nodoc
abstract mixin class _$TyphoonWarningCopyWith<$Res> implements $TyphoonWarningCopyWith<$Res> {
  factory _$TyphoonWarningCopyWith(_TyphoonWarning value, $Res Function(_TyphoonWarning) _then) = __$TyphoonWarningCopyWithImpl;
@override @useResult
$Res call({
 bool active, String id, int sent, String status, String msgType, String scope, String event, String urgency, String severity, String certainty, int effective, int onset, int expires, String headline, String senderName, WarningTyphoon? typhoon, List<WarningSection> sections, List<WarningArea> areas
});


@override $WarningTyphoonCopyWith<$Res>? get typhoon;

}
/// @nodoc
class __$TyphoonWarningCopyWithImpl<$Res>
    implements _$TyphoonWarningCopyWith<$Res> {
  __$TyphoonWarningCopyWithImpl(this._self, this._then);

  final _TyphoonWarning _self;
  final $Res Function(_TyphoonWarning) _then;

/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? active = null,Object? id = null,Object? sent = null,Object? status = null,Object? msgType = null,Object? scope = null,Object? event = null,Object? urgency = null,Object? severity = null,Object? certainty = null,Object? effective = null,Object? onset = null,Object? expires = null,Object? headline = null,Object? senderName = null,Object? typhoon = freezed,Object? sections = null,Object? areas = null,}) {
  return _then(_TyphoonWarning(
active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,msgType: null == msgType ? _self.msgType : msgType // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as String,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,certainty: null == certainty ? _self.certainty : certainty // ignore: cast_nullable_to_non_nullable
as String,effective: null == effective ? _self.effective : effective // ignore: cast_nullable_to_non_nullable
as int,onset: null == onset ? _self.onset : onset // ignore: cast_nullable_to_non_nullable
as int,expires: null == expires ? _self.expires : expires // ignore: cast_nullable_to_non_nullable
as int,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,typhoon: freezed == typhoon ? _self.typhoon : typhoon // ignore: cast_nullable_to_non_nullable
as WarningTyphoon?,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<WarningSection>,areas: null == areas ? _self._areas : areas // ignore: cast_nullable_to_non_nullable
as List<WarningArea>,
  ));
}

/// Create a copy of TyphoonWarning
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarningTyphoonCopyWith<$Res>? get typhoon {
    if (_self.typhoon == null) {
    return null;
  }

  return $WarningTyphoonCopyWith<$Res>(_self.typhoon!, (value) {
    return _then(_self.copyWith(typhoon: value));
  });
}
}

// dart format on
