/// A township hourly weather forecast, from v5 `/weather/forecast/:code`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_forecast.freezed.dart';
part 'weather_forecast.g.dart';

/// The forecast for one 3-digit township code: an [updateTime] and an ordered
/// list of hourly [forecast] points. A plain JSON object, so it decodes via
/// `fromJson`.
///
/// ⚠️ Time here is **not** Unix seconds: [updateTime] is a 13-digit
/// **millisecond** epoch (read it as [updatedAt]), and each point's
/// [WeatherForecastPoint.time] is an `"HH:00"` clock string, not a timestamp.
@freezed
abstract class WeatherForecast with _$WeatherForecast {
  const WeatherForecast._();

  const factory WeatherForecast({
    /// Publish time, Unix **milliseconds** (13-digit) — see [updatedAt].
    required int updateTime,
    required List<WeatherForecastPoint> forecast,
  }) = _WeatherForecast;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      _$WeatherForecastFromJson(json);

  /// [updateTime] as a UTC [DateTime] (the epoch is milliseconds, not seconds).
  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updateTime, isUtc: true);
}

/// One hourly forecast point. All fields are model predictions (no `-99`
/// sentinel); [time] is an `"HH:00"` clock string, not a timestamp.
@freezed
abstract class WeatherForecastPoint with _$WeatherForecastPoint {
  const factory WeatherForecastPoint({
    /// Clock label for this hour (`"HH:00"`, e.g. `"14:00"`).
    required String time,

    /// Forecast air temperature, °C.
    required double temperature,

    /// Forecast apparent ("feels-like") temperature, °C.
    required double apparentTemp,

    /// Forecast relative humidity, %.
    required int humidity,

    /// Human-readable weather text (e.g. `多雲`).
    required String weather,

    /// Weather number code (hundreds: clear 100 / cloudy 200 / overcast 300).
    required int weatherCode,

    /// Probability of precipitation, %.
    required int pop,
    required ForecastWind wind,
  }) = _WeatherForecastPoint;

  factory WeatherForecastPoint.fromJson(Map<String, dynamic> json) =>
      _$WeatherForecastPointFromJson(json);
}

/// A forecast wind vector: [direction] is a compass **string** (e.g. `"NE"`, or
/// Chinese like `"偏東風"` when unmapped), not an angle; [speed] is m/s and
/// [beaufort] the force number.
@freezed
abstract class ForecastWind with _$ForecastWind {
  const factory ForecastWind({
    required String direction,
    required double speed,
    required int beaufort,
  }) = _ForecastWind;

  factory ForecastWind.fromJson(Map<String, dynamic> json) =>
      _$ForecastWindFromJson(json);
}
