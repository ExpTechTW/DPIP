/// Access to v5 meteor weather data (station directory + observation snapshots).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// Weather observations from the v5 meteor API. Returns a [Result] so a failed
/// fetch/decode is explicit (never a silently blank weather panel); the impl in
/// `data/` maps transport/decode errors to a typed `Failure`.
abstract interface class MeteorWeatherRepository {
  /// The static station directory, keyed by station code.
  Future<Result<Map<String, WeatherStation>>> stations();

  /// The latest observation snapshot.
  Future<Result<WeatherSnapshot>> latest();

  /// Available history snapshot times (Unix seconds, ascending); `Ok([])` when
  /// none.
  Future<Result<List<int>>> history();

  /// The historical snapshot at [second].
  Future<Result<WeatherSnapshot>> at(int second);
}
