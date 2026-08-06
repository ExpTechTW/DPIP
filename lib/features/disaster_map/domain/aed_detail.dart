/// AED detail payload from `GET /api/v2/tiles/dpm/aed/{id}`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'aed_detail.freezed.dart';
part 'aed_detail.g.dart';

/// Full AED facility record — tile features only carry a subset; tap loads this.
@freezed
abstract class AedDetail with _$AedDetail {
  const factory AedDetail({
    required int id,
    @JsonKey(name: 'aed_id') required String aedId,
    required String name,
    @Default('') String city,
    @Default('') String district,
    @Default('') String category,
    @Default('') String type,
    @Default('') String place,
    required double lat,
    required double lng,
    @Default('') String address,
    @Default('') String description,
    @JsonKey(name: 'place_desc') @Default('') String placeDesc,
    @JsonKey(name: 'weekday_start') @Default('') String weekdayStart,
    @JsonKey(name: 'weekday_end') @Default('') String weekdayEnd,
    @JsonKey(name: 'saturday_start') @Default('') String saturdayStart,
    @JsonKey(name: 'saturday_end') @Default('') String saturdayEnd,
    @JsonKey(name: 'sunday_start') @Default('') String sundayStart,
    @JsonKey(name: 'sunday_end') @Default('') String sundayEnd,
    @JsonKey(name: 'open_remark') @Default('') String openRemark,
    @JsonKey(name: 'emergency_phone') @Default('') String emergencyPhone,
    @JsonKey(name: 'place_id') @Default('') String placeId,
  }) = _AedDetail;

  factory AedDetail.fromJson(Map<String, dynamic> json) =>
      _$AedDetailFromJson(json);
}
