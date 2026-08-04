/// Accumulation windows for v5 meteor rainfall field-arrays.
library;

import 'package:dpip/features/weather/domain/rain_snapshot.dart';

/// Windows exposed by `/api/v5/meteor/rain` (`now` / `10m` / `1h` / …).
///
/// Labels live in presentation (l10n); this enum is the pure wire + value map.
enum RainInterval {
  now,
  min10,
  hour1,
  hour3,
  hour6,
  hour12,
  hour24,
  day2,
  day3;

  /// Wire / GeoJSON property key (matches the API column name).
  String get apiKey => switch (this) {
    RainInterval.now => 'now',
    RainInterval.min10 => '10m',
    RainInterval.hour1 => '1h',
    RainInterval.hour3 => '3h',
    RainInterval.hour6 => '6h',
    RainInterval.hour12 => '12h',
    RainInterval.hour24 => '24h',
    RainInterval.day2 => '2d',
    RainInterval.day3 => '3d',
  };

  /// The accumulation (mm) for this window, or `null` when missing.
  double? valueOf(RainObservation observation) => switch (this) {
    RainInterval.now => observation.now,
    RainInterval.min10 => observation.min10,
    RainInterval.hour1 => observation.hour1,
    RainInterval.hour3 => observation.hour3,
    RainInterval.hour6 => observation.hour6,
    RainInterval.hour12 => observation.hour12,
    RainInterval.hour24 => observation.hour24,
    RainInterval.day2 => observation.day2,
    RainInterval.day3 => observation.day3,
  };
}
