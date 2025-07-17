import 'dart:developer';

import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:flutter/material.dart';

class SettingsUserInterfaceModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsUserInterfaceModel');

  String get _themeMode => Preference.themeMode ?? 'system';
  int? get _themeColor => Preference.themeColor;
  Locale? get _locale => Preference.locale?.asLocale;
  bool get _useFahrenheit => Preference.useFahrenheit ?? false;

  ThemeMode get themeMode => ThemeMode.values.byName(_themeMode);
  void setThemeMode(ThemeMode value) {
    Preference.themeMode = value.name;

    _log('Changed ${PreferenceKeys.themeMode} to ${Preference.themeMode}');
    notifyListeners();
  }

  Color? get themeColor => _themeColor == null ? null : Color(_themeColor!);
  void setThemeColor(Color? color) {
    final colorInt = color?.toARGB32();

    Preference.themeColor = colorInt;

    _log('Changed ${PreferenceKeys.themeColor} to ${Preference.themeColor}');
    notifyListeners();
  }

  Locale? get locale => _locale;
  void setLocale(Locale? value) {
    Preference.locale = value?.toLanguageTag();

    _log('Changed ${PreferenceKeys.locale} to ${Preference.locale}');
    notifyListeners();
  }

  bool get useFahrenheit => _useFahrenheit;
  void setUseFahrenheit(bool value) {
    Preference.useFahrenheit = value;

    _log('Changed ${PreferenceKeys.useFahrenheit} to ${Preference.useFahrenheit}');
    notifyListeners();
  }
}
