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
  history,
  wind,
  community,
}

class SettingsUserInterfaceModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsUserInterfaceModel');

  String get _themeMode => Preference.themeMode ?? 'system';
  int? get _themeColor => Preference.themeColor;
  Locale? get _locale => Preference.locale?.asLocale;
  bool get _useFahrenheit => Preference.useFahrenheit ?? false;
  late List<HomeDisplaySection> homeSections;
  final savedList = Preference.homeDisplaySections;

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
    AppLocalizations.locale = value ?? Platform.localeName.asLocale;

    _log('Changed ${PreferenceKeys.locale} to ${Preference.locale}');
    notifyListeners();
  }

  bool get useFahrenheit => _useFahrenheit;
  void setUseFahrenheit(bool value) {
    Preference.useFahrenheit = value;

    _log(
      'Changed ${PreferenceKeys.useFahrenheit} to ${Preference.useFahrenheit}',
    );
    notifyListeners();
  }

  SettingsUserInterfaceModel() {
    if (savedList.isEmpty) {
      // 預設全部啟用
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

  bool isEnabled(HomeDisplaySection section) => homeSections.contains(section);

  void toggleSection(HomeDisplaySection section, bool enabled) {
    final newList = List<HomeDisplaySection>.from(homeSections);
    if (enabled) {
      if (!newList.contains(section)) {
        newList.add(section);
      }
    } else {
      newList.remove(section);
    }
    homeSections = newList;
    Preference.homeDisplaySections = homeSections.map((e) => e.name).toList();
    notifyListeners();
  }

  void reorderSection(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newList = List<HomeDisplaySection>.from(homeSections);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    homeSections = newList;

    Preference.homeDisplaySections = homeSections.map((e) => e.name).toList();
    notifyListeners();
  }
}

extension SettingsUserInterfaceModelExtension on BuildContext {
  SettingsUserInterfaceModel get useUserInterface =>
      watch<SettingsUserInterfaceModel>();
  SettingsUserInterfaceModel get userInterface =>
      read<SettingsUserInterfaceModel>();
}
