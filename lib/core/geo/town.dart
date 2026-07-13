import 'package:freezed_annotation/freezed_annotation.dart';

part 'town.freezed.dart';
part 'town.g.dart';

/// One Taiwan township (鄉鎮市區) — the unit the user picks as a saved region and
/// that GPS resolves to.
///
/// Mirrors the bundled `assets/location.json.gz` entry (`code → {city, town,
/// lat, lng, cityLevel, townLevel}`); [code] is the map key, injected when the
/// directory is built. [lat]/[lng] are the township centroid, used for the
/// nearest-town GPS lookup and for framing the map.
@freezed
abstract class Town with _$Town {
  const Town._();

  const factory Town({
    required String code,
    required String city,
    required String town,
    required double lat,
    required double lng,
    required String cityLevel,
    required String townLevel,
  }) = _Town;

  factory Town.fromJson(Map<String, dynamic> json) => _$TownFromJson(json);

  /// The city with its level, e.g. `臺北市` / `花蓮縣`.
  String get cityName => '$city$cityLevel';

  /// The township with its level, e.g. `中正區` / `吉安鄉`.
  String get townName => '$town$townLevel';

  /// The full administrative name, e.g. `臺北市 中正區`.
  String get fullName => '$cityName $townName';
}
