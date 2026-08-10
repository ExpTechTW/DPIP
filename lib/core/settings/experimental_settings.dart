import 'package:dpip/core/settings/persisted.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter/foundation.dart';

/// App-wide experimental feature settings, persisted via [Prefs].
///
/// Provided near the app root so any feature (e.g. the home weather backdrop)
/// can react to changes.
///
/// The whole surface is gated behind [unlocked], which starts false and is
/// turned on by ten taps on the Developer page's version row — the More-menu
/// entry is hidden until then.
class ExperimentalSettings extends ChangeNotifier {
  /// Loads persisted values from [prefs].
  ExperimentalSettings(Prefs prefs)
    : _prefs = prefs,
      _weatherMode = PersistedEnum(
        prefs,
        key: PreferenceKeys.weatherMode,
        values: WeatherMode.values,
        fallback: WeatherMode.auto,
      ),
      _skyTimeMode = PersistedEnum(
        prefs,
        key: PreferenceKeys.skyTimeMode,
        values: SkyTimeMode.values,
        fallback: SkyTimeMode.auto,
      );

  final Prefs _prefs;
  final PersistedEnum<WeatherMode> _weatherMode;
  final PersistedEnum<SkyTimeMode> _skyTimeMode;

  /// Whether the experimental-features menu is unlocked. Defaults to false; see
  /// the class doc for how it flips.
  bool get unlocked =>
      _prefs.getBool(PreferenceKeys.experimentalUnlocked) ?? false;

  /// Persists the unlock and notifies listeners (the More menu shows the
  /// entry only after this).
  Future<void> unlock() async {
    await _prefs.setBool(PreferenceKeys.experimentalUnlocked, true);
    notifyListeners();
  }

  /// The forced weather-animation mode, or [WeatherMode.auto] to follow real
  /// conditions.
  WeatherMode get weatherMode => _weatherMode.value;

  set weatherMode(WeatherMode mode) {
    if (_weatherMode.set(mode)) notifyListeners();
  }

  /// The forced time of day for the backdrop, or [SkyTimeMode.auto] to follow
  /// the clock.
  SkyTimeMode get skyTimeMode => _skyTimeMode.value;

  set skyTimeMode(SkyTimeMode mode) {
    if (_skyTimeMode.set(mode)) notifyListeners();
  }
}
