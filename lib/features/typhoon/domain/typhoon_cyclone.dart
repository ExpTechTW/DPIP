/// In-progress tropical-cyclone index — v5 `GET /api/v5/meteor/typhoon`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'typhoon_cyclone.freezed.dart';
part 'typhoon_cyclone.g.dart';

/// One active tropical cyclone's latest fix in the summary index (dataset 005).
///
/// The index carries scalar `lat`/`lon` (not the `[lng, lat]` geometry arrays of
/// the other datasets). Typhoon uses `null` for missing (no `-99` sentinel), so
/// the dynamic fields are nullable.
@freezed
abstract class TyphoonCyclone with _$TyphoonCyclone {
  const factory TyphoonCyclone({
    /// International name (e.g. `HAISHEN`); a code like `TD11` when unnamed.
    required String name,

    /// CWA Chinese name (e.g. 海神); null before naming.
    String? cwaName,
    required int year,

    /// Tropical-depression number.
    String? tdNo,

    /// Typhoon number.
    String? tyNo,

    /// Latest fix time (Unix seconds).
    @JsonKey(name: 't') required int time,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,

    /// Sustained wind (m/s).
    double? wind,

    /// Gust (m/s).
    double? gust,

    /// Central pressure (hPa).
    @JsonKey(name: 'pres') double? pressure,

    /// Translation speed (km/hr).
    double? speed,

    /// Translation heading (e.g. `WNW`).
    @JsonKey(name: 'dir') String? direction,
  }) = _TyphoonCyclone;

  factory TyphoonCyclone.fromJson(Map<String, dynamic> json) =>
      _$TyphoonCycloneFromJson(json);
}

/// The `GET /` payload: the update time and every active cyclone's latest fix.
/// `cyclones` is empty when nothing is active.
@freezed
abstract class CycloneIndex with _$CycloneIndex {
  const factory CycloneIndex({
    required int updated,
    required List<TyphoonCyclone> cyclones,
  }) = _CycloneIndex;

  factory CycloneIndex.fromJson(Map<String, dynamic> json) =>
      _$CycloneIndexFromJson(json);
}
