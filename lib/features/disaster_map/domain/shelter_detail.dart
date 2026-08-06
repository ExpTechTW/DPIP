/// Shelter detail payload from `GET /api/v2/tiles/dpm/shelter/{id}`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'shelter_detail.freezed.dart';
part 'shelter_detail.g.dart';

/// Full shelter (避難收容處所) record — tile features only carry a subset.
@freezed
abstract class ShelterDetail with _$ShelterDetail {
  const factory ShelterDetail({
    @Default(0) int id,
    @Default('') String name,
    @Default(0) int capacity,
    @Default(<String>[]) List<String> category,
    @Default(false) bool indoor,
    @Default(false) bool outdoor,
    @JsonKey(name: 'vulnerable_ok') @Default(false) bool vulnerableOk,
    @Default(0) double lat,
    @Default(0) double lng,
    @Default('') String address,
  }) = _ShelterDetail;

  factory ShelterDetail.fromJson(Map<String, dynamic> json) =>
      _$ShelterDetailFromJson(json);
}
