import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dpip/core/preference.dart';

/// 緊急地震速報通知設定
enum EewNotifyType {
  /// 所在地震度4以上
  localIntensityAbove4,

  /// 所在地震度1以上
  localIntensityAbove1,

  /// 接收全部
  all,
}

/// 地震通知設定
enum EarthquakeNotifyType {
  /// 不接收
  off,

  /// 所在地震度1以上
  localIntensityAbove1,

  /// 接收全部
  all,
}

/// 天氣通知設定
enum WeatherNotifyType {
  /// 不接收
  off,

  /// 接收所在地
  local,
}

/// 海嘯通知設定
enum TsunamiNotifyType {
  /// 海嘯警報
  warningOnly,

  /// 海嘯警報、海嘯警報
  all,
}

/// 基本通知設定
enum BasicNotifyType {
  /// 不接收
  off,

  /// 接收全部
  all,
}

class SettingsNotificationModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsNotificationModel');

  String _eew = Preference.notifyEew ?? EewNotifyType.localIntensityAbove1.name;
  String _monitor = Preference.notifyMonitor ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String _report = Preference.notifyReport ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String _intensity = Preference.notifyIntensity ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String _thunderstorm = Preference.notifyThunderstorm ?? WeatherNotifyType.local.name;
  String _weatherAdvisory = Preference.notifyWeatherAdvisory ?? WeatherNotifyType.local.name;
  String _evacuation = Preference.notifyEvacuation ?? WeatherNotifyType.local.name;
  String _tsunami = Preference.notifyTsunami ?? TsunamiNotifyType.all.name;
  String _announcement = Preference.notifyAnnouncement ?? BasicNotifyType.all.name;

  /// 地震速報通知設定
  ///
  /// 預設：所在地震度1以上
  EewNotifyType get eew => EewNotifyType.values.byName(_eew);
  void setEew(EewNotifyType value) {
    _eew = value.name;
    Preference.notifyEew = _eew;
    _log('Changed ${PreferenceKeys.notifyEew} to ${Preference.notifyEew}');
    notifyListeners();
  }

  /// 強震監視器通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get monitor => EarthquakeNotifyType.values.byName(_monitor);
  void setMonitor(EarthquakeNotifyType value) {
    _monitor = value.name;
    Preference.notifyMonitor = _monitor;
    _log('Changed ${PreferenceKeys.notifyMonitor} to ${Preference.notifyMonitor}');
    notifyListeners();
  }

  /// 地震報告通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get report => EarthquakeNotifyType.values.byName(_report);
  void setReport(EarthquakeNotifyType value) {
    _report = value.name;
    Preference.notifyReport = _report;
    _log('Changed ${PreferenceKeys.notifyReport} to ${Preference.notifyReport}');
    notifyListeners();
  }

  /// 震度速報通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get intensity => EarthquakeNotifyType.values.byName(_intensity);
  void setIntensity(EarthquakeNotifyType value) {
    _intensity = value.name;
    Preference.notifyIntensity = _intensity;
    _log('Changed ${PreferenceKeys.notifyIntensity} to ${Preference.notifyIntensity}');
    notifyListeners();
  }

  /// 雷雨即時訊息通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get thunderstorm => WeatherNotifyType.values.byName(_thunderstorm);
  void setThunderstorm(WeatherNotifyType value) {
    _thunderstorm = value.name;
    Preference.notifyThunderstorm = _thunderstorm;
    _log('Changed ${PreferenceKeys.notifyThunderstorm} to ${Preference.notifyThunderstorm}');
    notifyListeners();
  }

  /// 天氣景警特報通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get weatherAdvisory => WeatherNotifyType.values.byName(_weatherAdvisory);
  void setWeatherAdvisory(WeatherNotifyType value) {
    _weatherAdvisory = value.name;
    Preference.notifyWeatherAdvisory = _weatherAdvisory;
    _log('Changed ${PreferenceKeys.notifyWeatherAdvisory} to ${Preference.notifyWeatherAdvisory}');
    notifyListeners();
  }

  /// 防災避難通知設定
  ///
  /// 預設：接收全部
  WeatherNotifyType get evacuation => WeatherNotifyType.values.byName(_evacuation);
  void setEvacuation(WeatherNotifyType value) {
    _evacuation = value.name;
    Preference.notifyEvacuation = _evacuation;
    _log('Changed ${PreferenceKeys.notifyEvacuation} to ${Preference.notifyEvacuation}');
    notifyListeners();
  }

  /// 海嘯通知設定
  ///
  /// 預設：海嘯警報、海嘯警報
  TsunamiNotifyType get tsunami => TsunamiNotifyType.values.byName(_tsunami);
  void setTsunami(TsunamiNotifyType value) {
    _tsunami = value.name;
    Preference.notifyTsunami = _tsunami;
    _log('Changed ${PreferenceKeys.notifyTsunami} to ${Preference.notifyTsunami}');
    notifyListeners();
  }

  /// 公告通知設定
  ///
  /// 預設：接收全部
  BasicNotifyType get announcement => BasicNotifyType.values.byName(_announcement);
  void setAnnouncement(BasicNotifyType value) {
    _announcement = value.name;
    Preference.notifyAnnouncement = _announcement;
    _log('Changed ${PreferenceKeys.notifyAnnouncement} to ${Preference.notifyAnnouncement}');
  }
}
