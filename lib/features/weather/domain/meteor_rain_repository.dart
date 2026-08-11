/// Access to v5 meteor rain data (station directory + accumulation + trend).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/station_value_repository.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// Rainfall observations from the v5 meteor API. Returns a [Result] so a failed
/// fetch/decode is explicit (never a silently blank rain panel); the impl in
/// `data/` maps transport/decode errors to a typed `Failure`.
abstract interface class MeteorRainRepository
    implements StationValueRepository<RainSnapshot, RainTrend> {
  /// The static station directory, keyed by station code. Rain shares weather's
  /// `{n,c,t,alt,lat,lon}` catalogue shape, so it reuses [WeatherStation].
  @override
  Future<Result<Map<String, WeatherStation>>> stations();

  /// The latest accumulation snapshot.
  @override
  Future<Result<RainSnapshot>> latest();

  /// Available history snapshot times (Unix seconds, ascending); `Ok([])` when
  /// none.
  Future<Result<List<int>>> history();

  /// The historical snapshot at [second].
  Future<Result<RainSnapshot>> at(int second);

  /// The rainfall trend series for station [id] over [range] (`24h` | `7d`).
  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'});
}
