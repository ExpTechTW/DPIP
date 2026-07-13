import 'package:dpip/core/settings/persisted.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide experimental feature settings, persisted to [SharedPreferences].
///
/// Provided near the app root so any feature (e.g. the home weather backdrop)
/// can react to changes.
class ExperimentalSettings extends ChangeNotifier {
  /// Loads persisted values from [prefs].
  ExperimentalSettings(SharedPreferences prefs)
    : _weatherMode = PersistedEnum(
        prefs,
        key: 'experimental.weatherMode',
        values: WeatherMode.values,
        fallback: WeatherMode.auto,
      );

  final PersistedEnum<WeatherMode> _weatherMode;

  /// The forced weather-animation mode, or [WeatherMode.auto] to follow real
  /// conditions.
  WeatherMode get weatherMode => _weatherMode.value;

  set weatherMode(WeatherMode mode) {
    if (_weatherMode.set(mode)) notifyListeners();
  }
}
