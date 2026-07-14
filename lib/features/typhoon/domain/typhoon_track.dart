/// Tropical-cyclone track — v5 `GET /api/v5/meteor/typhoon/track` (dataset 005).
library;

import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'typhoon_track.freezed.dart';
part 'typhoon_track.g.dart';

/// One past-or-present fix on a cyclone's `analysis` track (ascending in time).
@freezed
abstract class TrackFix with _$TrackFix {
  const factory TrackFix({
    @JsonKey(name: 't') required int time,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,

    /// Sustained wind (m/s).
    double? wind,

    /// Gust (m/s).
    double? gust,

    /// Central pressure (hPa).
    @JsonKey(name: 'pres') double? pressure,
  }) = _TrackFix;

  factory TrackFix.fromJson(Map<String, dynamic> json) =>
      _$TrackFixFromJson(json);
}

/// The current fix's dynamics: translation, the bilingual motion forecast, and
/// the two storm circles (`[中文, English]` text pairs; circles null when weak).
@freezed
abstract class TrackNow with _$TrackNow {
  const factory TrackNow({
    /// Translation speed (km/hr).
    double? speed,

    /// Translation heading (e.g. `WNW`).
    @JsonKey(name: 'dir') String? direction,

    /// Motion forecast as a `[中文, English]` pair.
    List<String>? move,

    /// Level-7 (gale) storm circle; null when too weak.
    StormCircle? c15,

    /// Level-10 storm circle; null when too weak.
    StormCircle? c25,
  }) = _TrackNow;

  factory TrackNow.fromJson(Map<String, dynamic> json) =>
      _$TrackNowFromJson(json);
}

/// One predicted fix on the `forecast` track.
@freezed
abstract class TrackForecast with _$TrackForecast {
  const factory TrackForecast({
    /// Forecast lead time (hours).
    required int tau,
    @JsonKey(name: 't') required int time,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,

    /// Predicted sustained wind (m/s).
    double? wind,

    /// Predicted gust (m/s).
    double? gust,

    /// Predicted central pressure (hPa).
    @JsonKey(name: 'pres') double? pressure,

    /// Predicted translation speed (km/hr).
    double? speed,

    /// Predicted translation heading.
    @JsonKey(name: 'dir') String? direction,

    /// Level-7 wind radius (km).
    double? r15,

    /// 70%-probability circle radius (km).
    double? r70,

    /// Weakening / transition note as a `[中文, English]` pair.
    List<String>? state,
  }) = _TrackForecast;

  factory TrackForecast.fromJson(Map<String, dynamic> json) =>
      _$TrackForecastFromJson(json);
}

/// One cyclone's full track: past+present [analysis], the current [now]
/// dynamics, and the [forecast] positions.
@freezed
abstract class TyphoonTrack with _$TyphoonTrack {
  const factory TyphoonTrack({
    required String name,
    String? cwaName,
    required int year,
    String? tdNo,
    String? tyNo,
    required List<TrackFix> analysis,
    TrackNow? now,
    required List<TrackForecast> forecast,
  }) = _TyphoonTrack;

  factory TyphoonTrack.fromJson(Map<String, dynamic> json) =>
      _$TyphoonTrackFromJson(json);
}

/// The `GET /track` payload: the update time and every active cyclone's track.
/// `cyclones` is empty when nothing is active.
@freezed
abstract class TrackPayload with _$TrackPayload {
  const factory TrackPayload({
    required int updated,
    required List<TyphoonTrack> cyclones,
  }) = _TrackPayload;

  factory TrackPayload.fromJson(Map<String, dynamic> json) =>
      _$TrackPayloadFromJson(json);
}
