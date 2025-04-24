import 'package:dpip/util/extension/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKeys {
  static const themeMode = 'pref:theme:mode';
  static const themeColor = 'pref:theme:color';
  static const locale = 'pref:ui:locale';
}

class Preference {
  static late SharedPreferencesWithCache instance;

  static Future<void> init() async {
    instance = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  }

  static String? get themeMode => instance.getString(PreferenceKeys.themeMode);
  static set themeMode(String? value) => instance.set(PreferenceKeys.themeMode, value);

  static int? get themeColor => instance.getInt(PreferenceKeys.themeColor);
  static set themeColor(int? value) => instance.set(PreferenceKeys.themeColor, value);

  static String? get locale => instance.getString(PreferenceKeys.locale);
  static set locale(String? value) => instance.set(PreferenceKeys.locale, value);
}
