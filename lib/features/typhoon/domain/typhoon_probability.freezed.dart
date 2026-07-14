// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'typhoon_probability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProbabilityLevel {

/// Strike probability (%).
 int get p;/// Closed contour ring, custom-decoded from `[lng, lat]` pairs.
 List<LatLng> get coords;
/// Create a copy of ProbabilityLevel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProbabilityLevelCopyWith<ProbabilityLevel> get copyWith => _$ProbabilityLevelCopyWithImpl<ProbabilityLevel>(this as ProbabilityLevel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProbabilityLevel&&(identical(other.p, p) || other.p == p)&&const DeepCollectionEquality().equals(other.coords, coords));
}


@override
int get hashCode => Object.hash(runtimeType,p,const DeepCollectionEquality().hash(coords));

@override
String toString() {
  return 'ProbabilityLevel(p: $p, coords: $coords)';
}


}

/// @nodoc
abstract mixin class $ProbabilityLevelCopyWith<$Res>  {
  factory $ProbabilityLevelCopyWith(ProbabilityLevel value, $Res Function(ProbabilityLevel) _then) = _$ProbabilityLevelCopyWithImpl;
@useResult
$Res call({
 int p, List<LatLng> coords
});




}
/// @nodoc
class _$ProbabilityLevelCopyWithImpl<$Res>
    implements $ProbabilityLevelCopyWith<$Res> {
  _$ProbabilityLevelCopyWithImpl(this._self, this._then);

  final ProbabilityLevel _self;
  final $Res Function(ProbabilityLevel) _then;

/// Create a copy of ProbabilityLevel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? p = null,Object? coords = null,}) {
  return _then(_self.copyWith(
p: null == p ? _self.p : p // ignore: cast_nullable_to_non_nullable
as int,coords: null == coords ? _self.coords : coords // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProbabilityLevel].
extension ProbabilityLevelPatterns on ProbabilityLevel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProbabilityLevel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProbabilityLevel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProbabilityLevel value)  $default,){
final _that = this;
switch (_that) {
case _ProbabilityLevel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProbabilityLevel value)?  $default,){
final _that = this;
switch (_that) {
case _ProbabilityLevel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int p,  List<LatLng> coords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProbabilityLevel() when $default != null:
return $default(_that.p,_that.coords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int p,  List<LatLng> coords)  $default,) {final _that = this;
switch (_that) {
case _ProbabilityLevel():
return $default(_that.p,_that.coords);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int p,  List<LatLng> coords)?  $default,) {final _that = this;
switch (_that) {
case _ProbabilityLevel() when $default != null:
return $default(_that.p,_that.coords);case _:
  return null;

}
}

}

/// @nodoc


class _ProbabilityLevel implements ProbabilityLevel {
  const _ProbabilityLevel({required this.p, required final  List<LatLng> coords}): _coords = coords;
  

/// Strike probability (%).
@override final  int p;
/// Closed contour ring, custom-decoded from `[lng, lat]` pairs.
 final  List<LatLng> _coords;
/// Closed contour ring, custom-decoded from `[lng, lat]` pairs.
@override List<LatLng> get coords {
  if (_coords is EqualUnmodifiableListView) return _coords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coords);
}


/// Create a copy of ProbabilityLevel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProbabilityLevelCopyWith<_ProbabilityLevel> get copyWith => __$ProbabilityLevelCopyWithImpl<_ProbabilityLevel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProbabilityLevel&&(identical(other.p, p) || other.p == p)&&const DeepCollectionEquality().equals(other._coords, _coords));
}


@override
int get hashCode => Object.hash(runtimeType,p,const DeepCollectionEquality().hash(_coords));

@override
String toString() {
  return 'ProbabilityLevel(p: $p, coords: $coords)';
}


}

/// @nodoc
abstract mixin class _$ProbabilityLevelCopyWith<$Res> implements $ProbabilityLevelCopyWith<$Res> {
  factory _$ProbabilityLevelCopyWith(_ProbabilityLevel value, $Res Function(_ProbabilityLevel) _then) = __$ProbabilityLevelCopyWithImpl;
@override @useResult
$Res call({
 int p, List<LatLng> coords
});




}
/// @nodoc
class __$ProbabilityLevelCopyWithImpl<$Res>
    implements _$ProbabilityLevelCopyWith<$Res> {
  __$ProbabilityLevelCopyWithImpl(this._self, this._then);

  final _ProbabilityLevel _self;
  final $Res Function(_ProbabilityLevel) _then;

/// Create a copy of ProbabilityLevel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? p = null,Object? coords = null,}) {
  return _then(_ProbabilityLevel(
p: null == p ? _self.p : p // ignore: cast_nullable_to_non_nullable
as int,coords: null == coords ? _self._coords : coords // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}


}

/// @nodoc
mixin _$TyphoonProbability {

 int get updated; List<ProbabilityLevel> get levels;
/// Create a copy of TyphoonProbability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TyphoonProbabilityCopyWith<TyphoonProbability> get copyWith => _$TyphoonProbabilityCopyWithImpl<TyphoonProbability>(this as TyphoonProbability, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TyphoonProbability&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other.levels, levels));
}


@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(levels));

@override
String toString() {
  return 'TyphoonProbability(updated: $updated, levels: $levels)';
}


}

/// @nodoc
abstract mixin class $TyphoonProbabilityCopyWith<$Res>  {
  factory $TyphoonProbabilityCopyWith(TyphoonProbability value, $Res Function(TyphoonProbability) _then) = _$TyphoonProbabilityCopyWithImpl;
@useResult
$Res call({
 int updated, List<ProbabilityLevel> levels
});




}
/// @nodoc
class _$TyphoonProbabilityCopyWithImpl<$Res>
    implements $TyphoonProbabilityCopyWith<$Res> {
  _$TyphoonProbabilityCopyWithImpl(this._self, this._then);

  final TyphoonProbability _self;
  final $Res Function(TyphoonProbability) _then;

/// Create a copy of TyphoonProbability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,Object? levels = null,}) {
  return _then(_self.copyWith(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,levels: null == levels ? _self.levels : levels // ignore: cast_nullable_to_non_nullable
as List<ProbabilityLevel>,
  ));
}

}


/// Adds pattern-matching-related methods to [TyphoonProbability].
extension TyphoonProbabilityPatterns on TyphoonProbability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TyphoonProbability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TyphoonProbability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TyphoonProbability value)  $default,){
final _that = this;
switch (_that) {
case _TyphoonProbability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TyphoonProbability value)?  $default,){
final _that = this;
switch (_that) {
case _TyphoonProbability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int updated,  List<ProbabilityLevel> levels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TyphoonProbability() when $default != null:
return $default(_that.updated,_that.levels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int updated,  List<ProbabilityLevel> levels)  $default,) {final _that = this;
switch (_that) {
case _TyphoonProbability():
return $default(_that.updated,_that.levels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int updated,  List<ProbabilityLevel> levels)?  $default,) {final _that = this;
switch (_that) {
case _TyphoonProbability() when $default != null:
return $default(_that.updated,_that.levels);case _:
  return null;

}
}

}

/// @nodoc


class _TyphoonProbability implements TyphoonProbability {
  const _TyphoonProbability({required this.updated, required final  List<ProbabilityLevel> levels}): _levels = levels;
  

@override final  int updated;
 final  List<ProbabilityLevel> _levels;
@override List<ProbabilityLevel> get levels {
  if (_levels is EqualUnmodifiableListView) return _levels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_levels);
}


/// Create a copy of TyphoonProbability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TyphoonProbabilityCopyWith<_TyphoonProbability> get copyWith => __$TyphoonProbabilityCopyWithImpl<_TyphoonProbability>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TyphoonProbability&&(identical(other.updated, updated) || other.updated == updated)&&const DeepCollectionEquality().equals(other._levels, _levels));
}


@override
int get hashCode => Object.hash(runtimeType,updated,const DeepCollectionEquality().hash(_levels));

@override
String toString() {
  return 'TyphoonProbability(updated: $updated, levels: $levels)';
}


}

/// @nodoc
abstract mixin class _$TyphoonProbabilityCopyWith<$Res> implements $TyphoonProbabilityCopyWith<$Res> {
  factory _$TyphoonProbabilityCopyWith(_TyphoonProbability value, $Res Function(_TyphoonProbability) _then) = __$TyphoonProbabilityCopyWithImpl;
@override @useResult
$Res call({
 int updated, List<ProbabilityLevel> levels
});




}
/// @nodoc
class __$TyphoonProbabilityCopyWithImpl<$Res>
    implements _$TyphoonProbabilityCopyWith<$Res> {
  __$TyphoonProbabilityCopyWithImpl(this._self, this._then);

  final _TyphoonProbability _self;
  final $Res Function(_TyphoonProbability) _then;

/// Create a copy of TyphoonProbability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,Object? levels = null,}) {
  return _then(_TyphoonProbability(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,levels: null == levels ? _self._levels : levels // ignore: cast_nullable_to_non_nullable
as List<ProbabilityLevel>,
  ));
}


}

// dart format on
