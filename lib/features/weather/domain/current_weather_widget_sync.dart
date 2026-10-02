/// Synchronization contract for the selected region's current-weather Widget.
library;

import 'package:dpip/features/weather/domain/weather_realtime.dart';

/// Publishes or clears the current-weather Widget state.
abstract interface class CurrentWeatherWidgetSync {
  /// Publishes [weather] for the selected [regionCode] when it is valid.
  Future<void> publish({
    required String regionCode,
    required WeatherRealtime weather,
  });

  /// Clears the current-weather Widget state.
  Future<void> clear();
}
