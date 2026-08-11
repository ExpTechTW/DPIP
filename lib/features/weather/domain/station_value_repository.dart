/// The station-value surface the shared station map layer consumes — a common
/// shape for the weather and rain repositories so one base layer serves both.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// A repository exposing the station catalogue, a latest observation snapshot,
/// and per-station trends — the three calls the shared station layer makes.
///
/// [S] is the snapshot type (weather / rain) and [T] the trend type; both
/// implement the small contracts below so the layer can read them generically.
abstract interface class StationValueRepository<S, T> {
  /// The static station directory, keyed by station code.
  Future<Result<Map<String, WeatherStation>>> stations();

  /// The latest observation snapshot.
  Future<Result<S>> latest();

  /// The trend series for station [id] over [range] (`24h` | `7d`).
  Future<Result<T>> trend(String id, {String range = '24h'});
}

/// A decoded snapshot exposing the per-station observations, aligned by index
/// to the station directory.
abstract interface class StationSnapshot<O extends StationObservation> {
  /// One observation per station, in station-directory order.
  List<O> get stations;
}

/// A per-station observation carrying the station code it belongs to.
abstract interface class StationObservation {
  /// The 6-char station code (the `/station` directory key).
  String get id;
}

/// A trend payload exposing the sample time axis (Unix seconds, ascending).
abstract interface class TrendTimeAxis {
  /// Sample times, aligned by index to the trend values.
  List<int> get times;
}
