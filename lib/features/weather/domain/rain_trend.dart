/// A single station's rainfall trend series, decoded from v5's delta time axis.
library;

import 'package:dpip/core/network/meteor_decode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rain_trend.freezed.dart';

/// The `/rain/trend/:id` series for one station over a [range] (`24h` | `7d`):
/// [times] is the delta-encoded axis restored to absolute Unix seconds, aligned
/// by index to [rain] (rolling 1-hour rainfall, mm; `-99` → null). Built from a
/// field-array payload, so it has no `fromJson`.
@freezed
abstract class RainTrend with _$RainTrend {
  const factory RainTrend({
    /// 6-char station code (the `/station` directory key).
    required String id,

    /// The requested range window (`24h` = 10-min native, `7d` = hourly rollup).
    required String range,

    /// Sample times, absolute Unix seconds ascending (oldest first).
    required List<int> times,

    /// Rolling 1-hour rainfall (mm) per sample, index-aligned to [times].
    required List<double?> rain,
  }) = _RainTrend;

  /// Decodes the raw `{ id, range, ts:[base, Δ, …], rain:[…] }` payload,
  /// restoring the delta-second axis and mapping `-99` → null.
  factory RainTrend.decode(Map<String, dynamic> json) => RainTrend(
    id: json['id'] as String,
    range: json['range'] as String,
    times: MeteorDecode.deltaSeconds((json['ts'] as List?) ?? const []),
    rain: [
      for (final value in (json['rain'] as List?) ?? const [])
        MeteorDecode.real(value),
    ],
  );
}
