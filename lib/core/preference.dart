import 'package:dpip/util/extension/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKeys {
  // #region User Interface
  static const themeMode = 'pref:ui:mode';
  static const themeColor = 'pref:ui:color';
  static const locale = 'pref:ui:locale';
  // #endregion

  // #region Notification
  static const notifyEew = 'pref:notify:eew';
  static const notifyMonitor = 'pref:notify:monitor';
  static const notifyIntensity = 'pref:notify:intensity';
  static const notifyReport = 'pref:notify:report';
  static const notifyThunderstorm = 'pref:notify:thunderstorm';
  static const notifyWeatherAdvisory = 'pref:notify:weatherAdvisory';
  static const notifyEvacuation = 'pref:notify:evacuation';
  static const notifyTsunami = 'pref:notify:tsunami';
  static const notifyAnnouncement = 'pref:notify:announcement';
  // #endregion
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

  // #region Notification
  static String? get notifyEew => instance.getString(PreferenceKeys.notifyEew);
  static set notifyEew(String? value) => instance.set(PreferenceKeys.notifyEew, value);

  static String? get notifyMonitor => instance.getString(PreferenceKeys.notifyMonitor);
  static set notifyMonitor(String? value) => instance.set(PreferenceKeys.notifyMonitor, value);

  static String? get notifyReport => instance.getString(PreferenceKeys.notifyReport);
  static set notifyReport(String? value) => instance.set(PreferenceKeys.notifyReport, value);

  static String? get notifyIntensity => instance.getString(PreferenceKeys.notifyIntensity);
  static set notifyIntensity(String? value) => instance.set(PreferenceKeys.notifyIntensity, value);

  static String? get notifyThunderstorm => instance.getString(PreferenceKeys.notifyThunderstorm);
  static set notifyThunderstorm(String? value) => instance.set(PreferenceKeys.notifyThunderstorm, value);

  static String? get notifyWeatherAdvisory => instance.getString(PreferenceKeys.notifyWeatherAdvisory);
  static set notifyWeatherAdvisory(String? value) => instance.set(PreferenceKeys.notifyWeatherAdvisory, value);

  static String? get notifyEvacuation => instance.getString(PreferenceKeys.notifyEvacuation);
  static set notifyEvacuation(String? value) => instance.set(PreferenceKeys.notifyEvacuation, value);

  static String? get notifyTsunami => instance.getString(PreferenceKeys.notifyTsunami);
  static set notifyTsunami(String? value) => instance.set(PreferenceKeys.notifyTsunami, value);

  static String? get notifyAnnouncement => instance.getString(PreferenceKeys.notifyAnnouncement);
  static set notifyAnnouncement(String? value) => instance.set(PreferenceKeys.notifyAnnouncement, value);
  // #endregion
}
