import 'dart:developer';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/notify/notify_settings.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Notification channel identifiers used when updating server-side settings.
enum NotifyChannel {
  /// Earthquake early warning.
  eew,

  /// Seismic intensity monitor.
  monitor,

  /// Earthquake report.
  report,

  /// Intensity report.
  intensity,

  /// Real-time thunderstorm alerts.
  thunderstorm,

  /// Weather advisory alerts.
  weatherAdvisory,

  /// Disaster evacuation alerts.
  evacuation,

  /// Tsunami alerts.
  tsunami,

  /// General announcements.
  announcement,
}

/// Notification filter for earthquake early warning alerts.
enum EewNotifyType {
  /// Local intensity 4 or above.
  localIntensityAbove4,

  /// Local intensity 1 or above.
  localIntensityAbove1,

  /// All warnings.
  all,
}

/// Notification filter for earthquake events.
enum EarthquakeNotifyType {
  /// Disabled.
  off,

  /// Local intensity 1 or above.
  localIntensityAbove1,

  /// All events.
  all,
}

/// Notification filter for weather events.
enum WeatherNotifyType {
  /// Disabled.
  off,

  /// Local area only.
  local,
}

/// Notification filter for tsunami alerts.
enum TsunamiNotifyType {
  /// Tsunami warnings only.
  warningOnly,

  /// All tsunami alerts.
  all,
}

/// Notification filter for general announcements.
enum BasicNotifyType {
  /// Disabled.
  off,

  /// All announcements.
  all,
}

class _SettingsNotificationModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsNotificationModel');

  String get _eew =>
      Preference.notifyEew ?? EewNotifyType.localIntensityAbove1.name;

  String get _monitor =>
      Preference.notifyMonitor ??
      EarthquakeNotifyType.localIntensityAbove1.name;

  String get _report =>
      Preference.notifyReport ?? EarthquakeNotifyType.localIntensityAbove1.name;

  String get _intensity =>
      Preference.notifyIntensity ??
      EarthquakeNotifyType.localIntensityAbove1.name;

  String get _thunderstorm =>
      Preference.notifyThunderstorm ?? WeatherNotifyType.local.name;

  String get _weatherAdvisory =>
      Preference.notifyWeatherAdvisory ?? WeatherNotifyType.local.name;

  String get _evacuation =>
      Preference.notifyEvacuation ?? WeatherNotifyType.local.name;

  String get _tsunami => Preference.notifyTsunami ?? TsunamiNotifyType.all.name;

  String get _announcement =>
      Preference.notifyAnnouncement ?? BasicNotifyType.all.name;

  /// Applies notification settings received from the server.
  ///
  /// Overwrites all channel preferences with the values in [settings] and
  /// notifies all attached listeners.
  void apply(NotifySettings settings) {
    Preference.notifyEew = settings.eew.name;
    Preference.notifyMonitor = settings.monitor.name;
    Preference.notifyReport = settings.report.name;
    Preference.notifyIntensity = settings.intensity.name;
    Preference.notifyThunderstorm = settings.thunderstorm.name;
    Preference.notifyWeatherAdvisory = settings.weatherAdvisory.name;
    Preference.notifyEvacuation = settings.evacuation.name;
    Preference.notifyTsunami = settings.tsunami.name;
    Preference.notifyAnnouncement = settings.announcement.name;

    _log('Applied notification settings from server');
    notifyListeners();
  }

  /// The current earthquake early warning notification filter.
  ///
  /// Returns an [EewNotifyType] from preferences. Defaults to
  /// [EewNotifyType.localIntensityAbove1] if no value has been set.
  EewNotifyType get eew => EewNotifyType.values.byName(_eew);

  /// Sets the earthquake early warning notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setEew(EewNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.eew,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyEew = value.name;
    _log('Changed ${PreferenceKeys.notifyEew} to ${Preference.notifyEew}');
    notifyListeners();
  }

  /// The current seismic intensity monitor notification filter.
  ///
  /// Returns an [EarthquakeNotifyType] from preferences. Defaults to
  /// [EarthquakeNotifyType.localIntensityAbove1] if no value has been set.
  EarthquakeNotifyType get monitor =>
      EarthquakeNotifyType.values.byName(_monitor);

  /// Sets the seismic intensity monitor notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setMonitor(EarthquakeNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.monitor,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyMonitor = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyMonitor} to ${Preference.notifyMonitor}',
    );
    notifyListeners();
  }

  /// The current earthquake report notification filter.
  ///
  /// Returns an [EarthquakeNotifyType] from preferences. Defaults to
  /// [EarthquakeNotifyType.localIntensityAbove1] if no value has been set.
  EarthquakeNotifyType get report =>
      EarthquakeNotifyType.values.byName(_report);

  /// Sets the earthquake report notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setReport(EarthquakeNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.report,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyReport = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyReport} to ${Preference.notifyReport}',
    );
    notifyListeners();
  }

  /// The current intensity report notification filter.
  ///
  /// Returns an [EarthquakeNotifyType] from preferences. Defaults to
  /// [EarthquakeNotifyType.localIntensityAbove1] if no value has been set.
  EarthquakeNotifyType get intensity =>
      EarthquakeNotifyType.values.byName(_intensity);

  /// Sets the intensity report notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setIntensity(EarthquakeNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.intensity,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyIntensity = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyIntensity} to ${Preference.notifyIntensity}',
    );
    notifyListeners();
  }

  /// The current thunderstorm alert notification filter.
  ///
  /// Returns a [WeatherNotifyType] from preferences. Defaults to
  /// [WeatherNotifyType.local] if no value has been set.
  WeatherNotifyType get thunderstorm =>
      WeatherNotifyType.values.byName(_thunderstorm);

  /// Sets the thunderstorm alert notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setThunderstorm(WeatherNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.thunderstorm,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyThunderstorm = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyThunderstorm} to ${Preference.notifyThunderstorm}',
    );
    notifyListeners();
  }

  /// The current weather advisory notification filter.
  ///
  /// Returns a [WeatherNotifyType] from preferences. Defaults to
  /// [WeatherNotifyType.local] if no value has been set.
  WeatherNotifyType get weatherAdvisory =>
      WeatherNotifyType.values.byName(_weatherAdvisory);

  /// Sets the weather advisory notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setWeatherAdvisory(WeatherNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.weatherAdvisory,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyWeatherAdvisory = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyWeatherAdvisory} to ${Preference.notifyWeatherAdvisory}',
    );
    notifyListeners();
  }

  /// The current disaster evacuation notification filter.
  ///
  /// Returns a [WeatherNotifyType] from preferences. Defaults to
  /// [WeatherNotifyType.local] if no value has been set.
  WeatherNotifyType get evacuation =>
      WeatherNotifyType.values.byName(_evacuation);

  /// Sets the disaster evacuation notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setEvacuation(WeatherNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.evacuation,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyEvacuation = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyEvacuation} to ${Preference.notifyEvacuation}',
    );
    notifyListeners();
  }

  /// The current tsunami alert notification filter.
  ///
  /// Returns a [TsunamiNotifyType] from preferences. Defaults to
  /// [TsunamiNotifyType.all] if no value has been set.
  TsunamiNotifyType get tsunami => TsunamiNotifyType.values.byName(_tsunami);

  /// Sets the tsunami alert notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setTsunami(TsunamiNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.tsunami,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyTsunami = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyTsunami} to ${Preference.notifyTsunami}',
    );
    notifyListeners();
  }

  /// The current announcement notification filter.
  ///
  /// Returns a [BasicNotifyType] from preferences. Defaults to
  /// [BasicNotifyType.all] if no value has been set.
  BasicNotifyType get announcement =>
      BasicNotifyType.values.byName(_announcement);

  /// Sets the announcement notification filter.
  ///
  /// Sends [value] to the server, applies the returned settings, persists the
  /// value to preferences, and notifies all attached listeners.
  Future<void> setAnnouncement(BasicNotifyType value) async {
    final result = await ExpTech().setNotify(
      token: Preference.notifyToken,
      channel: NotifyChannel.announcement,
      status: value,
    );
    GlobalProviders.notification.apply(result);

    Preference.notifyAnnouncement = value.name;
    _log(
      'Changed ${PreferenceKeys.notifyAnnouncement} to ${Preference.notifyAnnouncement}',
    );
    notifyListeners();
  }
}

class SettingsNotificationModel extends _SettingsNotificationModel {}

extension SettingsNotificationModelExtension on BuildContext {
  /// Watches [SettingsNotificationModel] and rebuilds when it notifies listeners.
  SettingsNotificationModel get useMap => watch<SettingsNotificationModel>();

  /// Reads [SettingsNotificationModel] without subscribing to updates.
  SettingsNotificationModel get map => read<SettingsNotificationModel>();
}
