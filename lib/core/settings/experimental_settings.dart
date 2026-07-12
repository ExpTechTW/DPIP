import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide experimental feature settings, persisted to [SharedPreferences].
///
/// Provided near the app root so any feature (e.g. the home weather backdrop)
/// can react to changes.
class ExperimentalSettings extends ChangeNotifier {
  static const String _weatherModeKey = 'experimental.weatherMode';

  final SharedPreferences _prefs;
  WeatherMode _weatherMode;

  /// Loads persisted values from [prefs].
  ExperimentalSettings(this._prefs) : _weatherMode = _readWeatherMode(_prefs);

  /// The forced weather-animation mode, or [WeatherMode.auto] to follow real
  /// conditions.
  WeatherMode get weatherMode => _weatherMode;

  set weatherMode(WeatherMode mode) {
    if (mode == _weatherMode) return;
    _weatherMode = mode;
    _prefs.setString(_weatherModeKey, mode.name);
    notifyListeners();
  }

  static WeatherMode _readWeatherMode(SharedPreferences prefs) {
    final name = prefs.getString(_weatherModeKey);
    return WeatherMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => WeatherMode.auto,
    );
  }
}
