/// A single station's weather trend series, decoded from v5's delta time axis.
library;

import 'package:dpip/core/network/meteor_decode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_trend.freezed.dart';

/// The `/weather/trend/:id` series for one station over a [range] (`24h` | `7d`):
/// [times] is the delta-encoded axis restored to absolute Unix seconds, aligned
/// by index to the parallel value series ([temperature] °C, [humidity] %,
/// [pressure] hPa, [windSpeed] m/s, [windDirection] °; each `-99` → null). Built
/// from a field-array payload, so it has no `fromJson`.
@freezed
abstract class WeatherTrend with _$WeatherTrend {
  const factory WeatherTrend({
    /// 6-char station code (the `/station` directory key).
    required String id,

    /// The requested range window (`24h` = hourly native, `7d` = hourly rollup).
    required String range,

    /// Sample times, absolute Unix seconds ascending (oldest first).
    required List<int> times,

    /// Air temperature (°C) per sample, index-aligned to [times].
    required List<double?> temperature,

    /// Relative humidity (%) per sample, index-aligned to [times].
    required List<int?> humidity,

    /// Station pressure (hPa) per sample, index-aligned to [times].
    required List<double?> pressure,

    /// Wind speed (m/s) per sample, index-aligned to [times].
    required List<double?> windSpeed,

    /// Wind direction (°) per sample, index-aligned to [times].
    required List<int?> windDirection,
  }) = _WeatherTrend;

  /// Decodes the raw `{ id, range, ts:[base, Δ, …], temp[], rh[], pres[],
  /// wspd[], wdir[] }` payload, restoring the delta-second axis and mapping
  /// `-99` → null across each parallel series.
  factory WeatherTrend.decode(Map<String, dynamic> json) => WeatherTrend(
    id: json['id'] as String,
    range: json['range'] as String,
    times: MeteorDecode.deltaSeconds((json['ts'] as List?) ?? const []),
    temperature: [
      for (final value in (json['temp'] as List?) ?? const [])
        MeteorDecode.real(value),
    ],
    humidity: [
      for (final value in (json['rh'] as List?) ?? const [])
        MeteorDecode.integer(value),
    ],
    pressure: [
      for (final value in (json['pres'] as List?) ?? const [])
        MeteorDecode.real(value),
    ],
    windSpeed: [
      for (final value in (json['wspd'] as List?) ?? const [])
        MeteorDecode.real(value),
    ],
    windDirection: [
      for (final value in (json['wdir'] as List?) ?? const [])
        MeteorDecode.integer(value),
    ],
  );
}
