import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/string.dart';

class SettingsUserInterfaceModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsUserInterfaceModel');

  String _themeMode = Preference.themeMode ?? 'system';
  int? _themeColor = Preference.themeColor;
  Locale? _locale = Preference.locale?.asLocale;
  bool _useFahrenheit = Preference.useFahrenheit ?? false;

  ThemeMode get themeMode => switch (_themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  void setThemeMode(ThemeMode value) {
    _themeMode = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    Preference.themeMode = _themeMode;

    _log('Changed ${PreferenceKeys.themeMode} to ${Preference.themeMode}');
    notifyListeners();
  }

  Color? get themeColor {
    final color = _themeColor;
    return color == null ? null : Color(color);
  }

  void setThemeColor(Color? color) {
    _themeColor = color?.toARGB32();

    Preference.themeColor = _themeColor;

    _log('Changed ${PreferenceKeys.themeColor} to ${Preference.themeColor}');
    notifyListeners();
  }

  Locale? get locale => _locale;
  void setLocale(Locale? value) {
    _locale = value;

    Preference.locale = value?.toLanguageTag();

    _log('Changed ${PreferenceKeys.locale} to ${Preference.locale}');
    notifyListeners();
  }

  bool get useFahrenheit => _useFahrenheit;
  void setUseFahrenheit(bool value) {
    _useFahrenheit = value;

    Preference.useFahrenheit = value;

    _log('Changed ${PreferenceKeys.useFahrenheit} to ${Preference.useFahrenheit}');
    notifyListeners();
  }
}
