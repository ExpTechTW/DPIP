/// The nearest weather station to a coordinate, from v5 `/weather/realtime`.
library;

import 'package:dpip/core/network/meteor_decode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_realtime.freezed.dart';
part 'weather_realtime.g.dart';

/// A single-station realtime observation resolved by proximity to a `lat,lng`
/// coordinate. Unlike the field-array snapshots this is a plain per-station JSON
/// object, so it decodes via `fromJson`. Numeric [WeatherRealtimeData] fields
/// carry the API's `-99` missing sentinel, mapped to null on decode.
///
/// The endpoint returns `{}` for a coordinate outside Taiwan; that empty case is
/// handled by the repository (which yields `null`), not this model.
@freezed
abstract class WeatherRealtime with _$WeatherRealtime {
  const factory WeatherRealtime({
    /// Full 6-char station code (the `/station` directory key).
    required String id,
    required WeatherRealtimeStation station,

    /// Observation time, Unix seconds.
    required int time,
    required WeatherRealtimeData data,
  }) = _WeatherRealtime;

  factory WeatherRealtime.fromJson(Map<String, dynamic> json) =>
      _$WeatherRealtimeFromJson(json);
}

/// The resolved station's identity and its [distance] from the query point.
@freezed
abstract class WeatherRealtimeStation with _$WeatherRealtimeStation {
  const factory WeatherRealtimeStation({
    required String name,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,

    /// Station altitude, metres.
    required double altitude,

    /// Great-circle distance from the query coordinate, kilometres.
    required double distance,
  }) = _WeatherRealtimeStation;

  factory WeatherRealtimeStation.fromJson(Map<String, dynamic> json) =>
      _$WeatherRealtimeStationFromJson(json);
}

/// The station's current observed values. Numeric fields decode the `-99`
/// missing sentinel to null via [MeteorDecode].
@freezed
abstract class WeatherRealtimeData with _$WeatherRealtimeData {
  const factory WeatherRealtimeData({
    /// Human-readable weather text (e.g. `多雲`).
    required String weather,

    /// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
    required int weatherCode,
    @JsonKey(fromJson: MeteorDecode.real) double? temperature,
    @JsonKey(fromJson: MeteorDecode.integer) int? humidity,

    /// Rolling 1-hour rainfall, mm.
    @JsonKey(fromJson: MeteorDecode.real) double? rain,
    required WeatherWind wind,
    required WeatherWind gust,
    @JsonKey(fromJson: MeteorDecode.real) double? visibility,
    @JsonKey(name: 'visibility_text') String? visibilityText,
    @JsonKey(fromJson: MeteorDecode.real) double? pressure,

    /// Accumulated sunshine, hours.
    @JsonKey(fromJson: MeteorDecode.real) double? sunshine,
  }) = _WeatherRealtimeData;

  factory WeatherRealtimeData.fromJson(Map<String, dynamic> json) =>
      _$WeatherRealtimeDataFromJson(json);
}

/// A wind vector (used for both sustained `wind` and `gust`): [direction] is an
/// observed compass text (e.g. `南南西`; absent for gust), [speed] m/s and
/// [beaufort] force carry the `-99` missing sentinel decoded to null.
@freezed
abstract class WeatherWind with _$WeatherWind {
  const factory WeatherWind({
    String? direction,
    @JsonKey(fromJson: MeteorDecode.real) double? speed,
    @JsonKey(fromJson: MeteorDecode.integer) int? beaufort,
  }) = _WeatherWind;

  factory WeatherWind.fromJson(Map<String, dynamic> json) =>
      _$WeatherWindFromJson(json);
}
