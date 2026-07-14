/// Typhoon warning bulletin — v5 `GET /api/v5/meteor/typhoon/warning`
/// (dataset 001).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'typhoon_warning.freezed.dart';
part 'typhoon_warning.g.dart';

/// A warning fix (`analysis` = observed, `prediction` = forecast): position,
/// intensity, and the bilingual [scale] label. Uses scalar `lat`/`lon` (not the
/// `[lng, lat]` geometry arrays of the other datasets).
@freezed
abstract class WarningFix with _$WarningFix {
  const factory WarningFix({
    @JsonKey(name: 't') required int time,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,

    /// Sustained wind (m/s).
    double? wind,

    /// Gust (m/s).
    double? gust,

    /// Central pressure (hPa).
    @JsonKey(name: 'pres') double? pressure,

    /// Level-7 wind radius (km).
    double? r15,

    /// Intensity as a `[中文, English]` pair; null when unclassified.
    List<String>? scale,
  }) = _WarningFix;

  factory WarningFix.fromJson(Map<String, dynamic> json) =>
      _$WarningFixFromJson(json);
}

/// The warned typhoon's identity plus its observed / predicted fixes.
@freezed
abstract class WarningTyphoon with _$WarningTyphoon {
  const factory WarningTyphoon({
    /// CWA typhoon number.
    String? no,
    required String name,
    String? cwaName,

    /// Bulletin report number.
    String? reportNo,

    /// Category (e.g. `END`).
    String? category,
    required WarningFix analysis,
    WarningFix? prediction,
  }) = _WarningTyphoon;

  factory WarningTyphoon.fromJson(Map<String, dynamic> json) =>
      _$WarningTyphoonFromJson(json);
}

/// One titled section of the warning body text.
@freezed
abstract class WarningSection with _$WarningSection {
  const factory WarningSection({required String title, required String text}) =
      _WarningSection;

  factory WarningSection.fromJson(Map<String, dynamic> json) =>
      _$WarningSectionFromJson(json);
}

/// One affected county/city (`code` is a `Taiwan_Geocode_112` code).
@freezed
abstract class WarningArea with _$WarningArea {
  const factory WarningArea({required String name, required String code}) =
      _WarningArea;

  factory WarningArea.fromJson(Map<String, dynamic> json) =>
      _$WarningAreaFromJson(json);
}

/// The `GET /warning` payload (a CAP-style envelope). [msgType] is `Alert`
/// (issue) / `Update` / `Cancel` (lift); off-season this is usually the most
/// recent `Cancel`.
@freezed
abstract class TyphoonWarning with _$TyphoonWarning {
  const factory TyphoonWarning({
    required bool active,
    required String id,

    /// Bulletin send time (Unix seconds).
    required int sent,
    required String status,
    required String msgType,
    required String scope,
    required String event,
    required String urgency,
    required String severity,
    required String certainty,

    /// Effective / onset / expiry times (Unix seconds).
    required int effective,
    required int onset,
    required int expires,
    required String headline,
    required String senderName,

    /// The warned typhoon; null when the bulletin carries no typhoon block.
    WarningTyphoon? typhoon,

    /// Warning body text, section by section.
    required List<WarningSection> sections,

    /// Affected counties/cities.
    required List<WarningArea> areas,
  }) = _TyphoonWarning;

  factory TyphoonWarning.fromJson(Map<String, dynamic> json) =>
      _$TyphoonWarningFromJson(json);
}
