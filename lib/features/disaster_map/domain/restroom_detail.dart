/// Restroom detail payload from `GET /api/v2/tiles/dpm/restroom/{id}`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'restroom_detail.freezed.dart';
part 'restroom_detail.g.dart';

/// Full restroom (public toilet) record — tile features only carry a subset.
@freezed
abstract class RestroomDetail with _$RestroomDetail {
  const factory RestroomDetail({
    @Default('') String name,
    @Default('') String address,
    @Default(0) double latitude,
    @Default(0) double longitude,
    @Default(0) int type,
    @Default(0) int type2,
    @Default(0) int typegrade,
  }) = _RestroomDetail;

  factory RestroomDetail.fromJson(Map<String, dynamic> json) =>
      _$RestroomDetailFromJson(json);
}
