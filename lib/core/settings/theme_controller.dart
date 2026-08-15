/// The app's selected theme mode (light / dark / follow the system).
library;

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/material.dart';

/// Holds the user's chosen [ThemeMode], persisted across launches.
///
/// Absent/empty means [ThemeMode.system] (the default) — `MaterialApp` then
/// follows the OS light/dark setting. Choosing light or dark forces it app-wide;
/// the app root watches this and rebuilds `MaterialApp` with the new
/// `themeMode`. Persisted as `light` / `dark` (system is stored as absence, so
/// the default is a missing key, not a magic string).
class ThemeController extends ChangeNotifier {
  ThemeController(this._settings);

  final SettingsStore _settings;

  /// The chosen theme mode, or [ThemeMode.system] when unset.
  ThemeMode get mode => switch (_settings.getString(SettingKeys.themeMode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Sets the theme mode; [ThemeMode.system] clears the override (back to the OS
  /// setting).
  Future<void> setMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.system:
        await _settings.remove(SettingKeys.themeMode);
      case ThemeMode.light:
        await _settings.setString(SettingKeys.themeMode, 'light');
      case ThemeMode.dark:
        await _settings.setString(SettingKeys.themeMode, 'dark');
    }
    notifyListeners();
  }
}
