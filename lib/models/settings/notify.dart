import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';

/// 通知類型
enum NotifyChannel {
  /// 緊急地震速報
  eew,

  /// 強震監視器
  monitor,

  /// 地震報告
  report,

  /// 震度速報
  intensity,

  /// 雷雨即時訊息
  thunderstorm,

  /// 天氣景警特報
  weatherAdvisory,

  /// 防災避難
  evacuation,

  /// 海嘯
  tsunami,

  /// 公告
  announcement,
}

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
  Future<void> setEew(EewNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.eew, status: value);

    _eew = value.name;
    Preference.notifyEew = _eew;
    _log('Changed ${PreferenceKeys.notifyEew} to ${Preference.notifyEew}');
    notifyListeners();
  }

  /// 強震監視器通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get monitor => EarthquakeNotifyType.values.byName(_monitor);
  Future<void> setMonitor(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.monitor, status: value);

    _monitor = value.name;
    Preference.notifyMonitor = _monitor;
    _log('Changed ${PreferenceKeys.notifyMonitor} to ${Preference.notifyMonitor}');
    notifyListeners();
  }

  /// 地震報告通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get report => EarthquakeNotifyType.values.byName(_report);
  Future<void> setReport(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.report, status: value);

    _report = value.name;
    Preference.notifyReport = _report;
    _log('Changed ${PreferenceKeys.notifyReport} to ${Preference.notifyReport}');
    notifyListeners();
  }

  /// 震度速報通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get intensity => EarthquakeNotifyType.values.byName(_intensity);
  Future<void> setIntensity(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.intensity, status: value);

    _intensity = value.name;
    Preference.notifyIntensity = _intensity;
    _log('Changed ${PreferenceKeys.notifyIntensity} to ${Preference.notifyIntensity}');
    notifyListeners();
  }

  /// 雷雨即時訊息通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get thunderstorm => WeatherNotifyType.values.byName(_thunderstorm);
  Future<void> setThunderstorm(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.thunderstorm, status: value);

    _thunderstorm = value.name;
    Preference.notifyThunderstorm = _thunderstorm;
    _log('Changed ${PreferenceKeys.notifyThunderstorm} to ${Preference.notifyThunderstorm}');
    notifyListeners();
  }

  /// 天氣景警特報通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get weatherAdvisory => WeatherNotifyType.values.byName(_weatherAdvisory);
  Future<void> setWeatherAdvisory(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.weatherAdvisory, status: value);

    _weatherAdvisory = value.name;
    Preference.notifyWeatherAdvisory = _weatherAdvisory;
    _log('Changed ${PreferenceKeys.notifyWeatherAdvisory} to ${Preference.notifyWeatherAdvisory}');
    notifyListeners();
  }

  /// 防災避難通知設定
  ///
  /// 預設：接收全部
  WeatherNotifyType get evacuation => WeatherNotifyType.values.byName(_evacuation);
  Future<void> setEvacuation(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.evacuation, status: value);

    _evacuation = value.name;
    Preference.notifyEvacuation = _evacuation;
    _log('Changed ${PreferenceKeys.notifyEvacuation} to ${Preference.notifyEvacuation}');
    notifyListeners();
  }

  /// 海嘯通知設定
  ///
  /// 預設：海嘯警報、海嘯警報
  TsunamiNotifyType get tsunami => TsunamiNotifyType.values.byName(_tsunami);
  Future<void> setTsunami(TsunamiNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.tsunami, status: value);

    _tsunami = value.name;
    Preference.notifyTsunami = _tsunami;
    _log('Changed ${PreferenceKeys.notifyTsunami} to ${Preference.notifyTsunami}');
    notifyListeners();
  }

  /// 公告通知設定
  ///
  /// 預設：接收全部
  BasicNotifyType get announcement => BasicNotifyType.values.byName(_announcement);
  Future<void> setAnnouncement(BasicNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.announcement, status: value);

    _announcement = value.name;
    Preference.notifyAnnouncement = _announcement;
    _log('Changed ${PreferenceKeys.notifyAnnouncement} to ${Preference.notifyAnnouncement}');
    notifyListeners();
  }
}
