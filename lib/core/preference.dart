import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/preference.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceKeys {
  static const lastUpdateToServerTime = 'lastUpdateToServerTime';
  static const appVersion = 'app-version';

  // #region Location
  static const locationAuto = 'location:auto';
  static const locationCode = 'location:code';
  static const locationLongitude = 'location:longitude';
  static const locationLatitude = 'location:latitude';
  static const locationOldLongitude = 'location:oldLongitude';
  static const locationOldLatitude = 'location:oldLatitude';
  static const locationFavorited = 'location:favorite';
  // #endregion

  // #region User Interface
  static const themeMode = 'pref:ui:mode';
  static const themeColor = 'pref:ui:color';
  static const locale = 'pref:ui:locale';
  static const useFahrenheit = 'pref:ui:fahrenheit';
  static const mapUpdateFps = 'pref:ui:map:updateFps';
  static const mapBase = 'pref:ui:map:base';
  static const mapLayers = 'pref:ui:map:layers';
  static const mapAutoZoom = 'pref:ui:map:autoZoom';
  static const homeDisplaySections = 'pref:ui:homeDisplaySections';

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

  // #region ETag Cache
  static const weatherEtag = 'weather-etag';
  static const weatherCache = 'weather-cache';
  static const forecastEtag = 'forecast-etag';
  static const forecastCache = 'forecast-cache';
  // #endregion

  // #region Network
  static const proxyEnabled = 'network:proxy:enabled';
  static const proxyHost = 'network:proxy:host';
  static const proxyPort = 'network:proxy:port';
  // #endregion
}

class Preference {
  Preference._();

  static late SharedPreferencesWithCache instance;

  static Future<void> init() async {
    instance = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    AppLocalizations.locale = locale?.asLocale;
  }

  static Future<void> reload() async {
    await instance.reloadCache();
  }

  static String? get version => instance.getString(PreferenceKeys.appVersion);
  static set version(String? value) => instance.set(PreferenceKeys.appVersion, value);

  static int? get lastUpdateToServerTime => instance.getInt(PreferenceKeys.lastUpdateToServerTime);
  static set lastUpdateToServerTime(int? value) => instance.set(PreferenceKeys.lastUpdateToServerTime, value);

  static bool get isTosAccepted => instance.getInt('accepted-tos-version') == 1;
  static set isTosAccepted(bool value) => instance.set('accepted-tos-version', value ? 1 : null);

  static bool get isFirstLaunch => instance.getString('welcome') != 'done';
  static set isFirstLaunch(bool value) => instance.set('welcome', value ? null : 'done');

  static String get notifyToken => instance.getString('notify-token') ?? '';
  static set notifyToken(String? value) => instance.set('notify-token', value);

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

  static List<String> get locationFavorited => instance.getStringList(PreferenceKeys.locationFavorited) ?? [];
  static set locationFavorited(List<String> value) => instance.set(PreferenceKeys.locationFavorited, value);
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

  static int? get mapUpdateFps => instance.getInt(PreferenceKeys.mapUpdateFps);
  static set mapUpdateFps(int? value) => instance.set(PreferenceKeys.mapUpdateFps, value);

  static String? get mapBase => instance.getString(PreferenceKeys.mapBase);
  static set mapBase(String? value) => instance.set(PreferenceKeys.mapBase, value);

  static String? get mapLayers => instance.getString(PreferenceKeys.mapLayers);
  static set mapLayers(String? value) => instance.set(PreferenceKeys.mapLayers, value);

  static bool? get mapAutoZoom => instance.getBool(PreferenceKeys.mapAutoZoom);
  static set mapAutoZoom(bool? value) => instance.set(PreferenceKeys.mapAutoZoom, value);

  static List<String> get homeDisplaySections => instance.getStringList(PreferenceKeys.homeDisplaySections) ?? [];
  static set homeDisplaySections(List<String> value) => instance.set(PreferenceKeys.homeDisplaySections, value);
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

  // #region Network
  static bool? get proxyEnabled => instance.getBool(PreferenceKeys.proxyEnabled);
  static set proxyEnabled(bool? value) => instance.set(PreferenceKeys.proxyEnabled, value);

  static String? get proxyHost => instance.getString(PreferenceKeys.proxyHost);
  static set proxyHost(String? value) => instance.set(PreferenceKeys.proxyHost, value);

  static int? get proxyPort => instance.getInt(PreferenceKeys.proxyPort);
  static set proxyPort(int? value) => instance.set(PreferenceKeys.proxyPort, value);
  // #endregion
}
