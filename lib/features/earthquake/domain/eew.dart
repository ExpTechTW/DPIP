import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/models/serialization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'eew.freezed.dart';
part 'eew.g.dart';

/// An Earthquake Early Warning for an in-progress earthquake.
///
/// The template for the app's API models: a `@freezed` immutable value type with
/// generated `fromJson`/`toJson`, `@JsonKey` mapping the wire names, and
/// `boolishInt` coercing the API's `0`/`1` booleans. New payloads copy this
/// shape.
@freezed
abstract class Eew with _$Eew {
  const factory Eew({
    @JsonKey(name: 'author') required String agency,
    required String id,
    required int serial,
    required int status,
    @JsonKey(name: 'final', fromJson: boolishInt, toJson: intFromBool)
    required bool isFinal,
    @JsonKey(name: 'eq') required EewInfo info,
  }) = _Eew;

  factory Eew.fromJson(Map<String, dynamic> json) => _$EewFromJson(json);
}

/// The earthquake parameters carried by an [Eew].
@freezed
abstract class EewInfo with _$EewInfo {
  const EewInfo._();

  const factory EewInfo({
    required int time,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'lat') required double latitude,
    required double depth,
    @JsonKey(name: 'mag') required double magnitude,
    @JsonKey(name: 'loc') required String location,
    required int max,
  }) = _EewInfo;

  factory EewInfo.fromJson(Map<String, dynamic> json) =>
      _$EewInfoFromJson(json);

  /// The epicentre as a dependency-free coordinate for the EEW math.
  LatLng get latlng => LatLng(latitude, longitude);
}
