import 'package:shared_preferences/shared_preferences.dart';

import 'package:dpip/utils/extensions/preference.dart';

class PreferenceKeys {
  // #region Location
  static const locationAuto = 'location:auto';
  static const locationCode = 'location:code';
  static const locationLongitude = 'location:longitude';
  static const locationLatitude = 'location:latitude';
  static const locationOldLongitude = 'location:oldLongitude';
  static const locationOldLatitude = 'location:oldLatitude';
  // #endregion

  // #region User Interface
  static const themeMode = 'pref:ui:mode';
  static const themeColor = 'pref:ui:color';
  static const locale = 'pref:ui:locale';
  static const useFahrenheit = 'pref:ui:fahrenheit';
  // #endregion

  // #region Notification
  static const notifyEew = 'pref:notify:eew';
  static const notifyMonitor = 'pref:notify:monitor';
  static const notifyReport = 'pref:notify:report';
  static const notifyIntensity = 'pref:notify:intensity';
  static const notifyThunderstorm = 'pref:notify:thunderstorm';
  static const notifyWeatherAdvisory = 'pref:notify:weatherAdvisory';
  static const notifyEvacuation = 'pref:notify:evacuation';
  static const notifyTsunami = 'pref:notify:tsunami';
  static const notifyAnnouncement = 'pref:notify:announcement';
  // #endregion
}

class Preference {
  Preference._();

  static late SharedPreferencesWithCache instance;

  static Future<void> init() async {
    instance = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  }

  static String? get version => instance.getString('app-version');
  static set version(String? value) => instance.set('app-version', value);

  static bool get isTosAccepted => instance.getInt('accepted-tos-version') == 1;
  static set isTosAccepted(bool value) => instance.set('accepted-tos-version', value ? 1 : null);

  static bool get isFirstLaunch => instance.getString('welcome') != 'done';
  static set isFirstLaunch(bool value) => instance.set('welcome', value ? null : 'done');

  static String get notifyToken => instance.getString("notify-token") ?? "";
  static set notifyToken(String? value) => instance.set("notify-token", value);

  // #region Location
  static bool? get locationAuto => instance.getBool(PreferenceKeys.locationAuto);
  static set locationAuto(bool? value) => instance.set(PreferenceKeys.locationAuto, value);

  static String? get locationCode => instance.getString(PreferenceKeys.locationCode);
  static set locationCode(String? value) => instance.set(PreferenceKeys.locationCode, value);

  static double? get locationLongitude => instance.getDouble(PreferenceKeys.locationLongitude);
  static set locationLongitude(double? value) => instance.set(PreferenceKeys.locationLongitude, value);

  static double? get locationLatitude => instance.getDouble(PreferenceKeys.locationLatitude);
  static set locationLatitude(double? value) => instance.set(PreferenceKeys.locationLatitude, value);

  static double? get locationOldLongitude => instance.getDouble(PreferenceKeys.locationOldLongitude);
  static set locationOldLongitude(double? value) => instance.set(PreferenceKeys.locationOldLongitude, value);

  static double? get locationOldLatitude => instance.getDouble(PreferenceKeys.locationOldLatitude);
  static set locationOldLatitude(double? value) => instance.set(PreferenceKeys.locationOldLatitude, value);
  // #endregion

  // #region User Interface
  static String? get themeMode => instance.getString(PreferenceKeys.themeMode);
  static set themeMode(String? value) => instance.set(PreferenceKeys.themeMode, value);

  static int? get themeColor => instance.getInt(PreferenceKeys.themeColor);
  static set themeColor(int? value) => instance.set(PreferenceKeys.themeColor, value);

  static String? get locale => instance.getString(PreferenceKeys.locale);
  static set locale(String? value) => instance.set(PreferenceKeys.locale, value);

  static bool? get useFahrenheit => instance.getBool(PreferenceKeys.useFahrenheit);
  static set useFahrenheit(bool? value) => instance.set(PreferenceKeys.useFahrenheit, value);
  // #endregion

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
