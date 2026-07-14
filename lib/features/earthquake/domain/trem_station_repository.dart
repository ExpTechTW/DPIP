/// Access to the seismic (TREM) station directory.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// The static seismic-station directory (id → location). Fetched once and joined
/// to the RTS shaking feed. Returns a [Result] so a failed fetch is explicit.
abstract interface class TremStationRepository {
  /// The directory keyed by station id (each station's latest coordinates).
  Future<Result<Map<String, SeismicStation>>> stations();
}
