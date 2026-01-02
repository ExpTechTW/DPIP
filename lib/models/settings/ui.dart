import 'dart:developer';
import 'dart:io';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum HomeDisplaySection {
  radar,
  forecast,
  wind,
}

const reorderableSections = [
  HomeDisplaySection.radar,
  HomeDisplaySection.forecast,
  HomeDisplaySection.wind,
];

class SettingsUserInterfaceModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsUserInterfaceModel');

  late String _currentThemeMode;
  late int? _currentThemeColor;
  late String? _currentLocale;
  late bool _currentUseFahrenheit;
  late List<HomeDisplaySection> homeSections;

  SettingsUserInterfaceModel() {
    _currentThemeMode = Preference.themeMode ?? 'system';
    _currentThemeColor = Preference.themeColor;
    _currentLocale = Preference.locale;
    _currentUseFahrenheit = Preference.useFahrenheit ?? false;

    _log('Initialized: themeMode=$_currentThemeMode');

    final savedList = Preference.homeDisplaySections;
    if (savedList.isEmpty) {
      homeSections = HomeDisplaySection.values.toList();
    } else {
      final saved = savedList
          .map(
            (s) => HomeDisplaySection.values
                .cast<HomeDisplaySection?>()
                .firstWhere((e) => e?.name == s, orElse: () => null),
          )
          .whereType<HomeDisplaySection>()
          .toList();
      homeSections = saved;
    }
  }

  ThemeMode get themeMode => ThemeMode.values.byName(_currentThemeMode);
  void setThemeMode(ThemeMode value) {
    _currentThemeMode = value.name;
    Preference.themeMode = value.name;

    _log('Changed themeMode to $_currentThemeMode');
    notifyListeners();
  }

  Color? get themeColor =>
      _currentThemeColor == null ? null : Color(_currentThemeColor!);
  void setThemeColor(Color? color) {
    final colorInt = color?.toARGB32();
    _currentThemeColor = colorInt;
    Preference.themeColor = colorInt;

    _log('Changed themeColor to $_currentThemeColor');
    notifyListeners();
  }

  Locale? get locale => _currentLocale?.asLocale;
  void setLocale(Locale? value) {
    _currentLocale = value?.toLanguageTag();
    Preference.locale = _currentLocale;
    AppLocalizations.locale = value ?? Platform.localeName.asLocale;

    _log('Changed locale to $_currentLocale');
    notifyListeners();
  }

  bool get useFahrenheit => _currentUseFahrenheit;
  void setUseFahrenheit(bool value) {
    _currentUseFahrenheit = value;
    Preference.useFahrenheit = value;

    _log('Changed useFahrenheit to $_currentUseFahrenheit');
    notifyListeners();
  }

  bool isEnabled(HomeDisplaySection section) => homeSections.contains(section);

  void toggleSection(HomeDisplaySection section, bool enabled) {
    if (enabled) {
      homeSections.add(section);
    } else {
      homeSections.remove(section);
    }
    _saveHomeSections();
    notifyListeners();
  }

  void reorderSection(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = homeSections.removeAt(oldIndex);
    homeSections.insert(newIndex, item);
    _saveHomeSections();
    notifyListeners();
  }

  void _saveHomeSections() {
    Preference.homeDisplaySections = homeSections.map((e) => e.name).toList();
  }
}

extension SettingsUserInterfaceModelExtension on BuildContext {
  SettingsUserInterfaceModel get useUserInterface =>
      watch<SettingsUserInterfaceModel>();
  SettingsUserInterfaceModel get userInterface =>
      read<SettingsUserInterfaceModel>();
}
