/// Access to the next-hour per-minute rain forecast.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';

/// The next-hour rain trend for a township, from the `rainforecast` endpoint.
/// Returns a [Result] so a failed fetch/decode is explicit (never a fabricated
/// trend in the home-sheet card); the impl in `data/` maps transport/decode
/// errors to a typed `Failure`.
abstract interface class RainHourTrendRepository {
  /// The next 60 minutes of per-minute rainfall for the 3-digit township
  /// [code].
  Future<Result<RainHourTrend>> hourTrend(String code);
}
