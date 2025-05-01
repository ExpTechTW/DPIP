import 'dart:developer';

import 'package:dpip/api/model/notify/notify_settings.dart';
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

  String get _eew => Preference.notifyEew ?? EewNotifyType.localIntensityAbove1.name;
  String get _monitor => Preference.notifyMonitor ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String get _report => Preference.notifyReport ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String get _intensity => Preference.notifyIntensity ?? EarthquakeNotifyType.localIntensityAbove1.name;
  String get _thunderstorm => Preference.notifyThunderstorm ?? WeatherNotifyType.local.name;
  String get _weatherAdvisory => Preference.notifyWeatherAdvisory ?? WeatherNotifyType.local.name;
  String get _evacuation => Preference.notifyEvacuation ?? WeatherNotifyType.local.name;
  String get _tsunami => Preference.notifyTsunami ?? TsunamiNotifyType.all.name;
  String get _announcement => Preference.notifyAnnouncement ?? BasicNotifyType.all.name;

  void apply(NotifySettings settings) {
    setEew(settings.eew);
    setMonitor(settings.monitor);
    setReport(settings.report);
    setIntensity(settings.intensity);
    setThunderstorm(settings.thunderstorm);
    setWeatherAdvisory(settings.weatherAdvisory);
    setEvacuation(settings.evacuation);
    setTsunami(settings.tsunami);
    setAnnouncement(settings.announcement);
  }

  /// 地震速報通知設定
  ///
  /// 預設：所在地震度1以上
  EewNotifyType get eew => EewNotifyType.values.byName(_eew);
  Future<void> setEew(EewNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.eew, status: value);

    Preference.notifyEew = value.name;
    _log('Changed ${PreferenceKeys.notifyEew} to ${Preference.notifyEew}');
    notifyListeners();
  }

  /// 強震監視器通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get monitor => EarthquakeNotifyType.values.byName(_monitor);
  Future<void> setMonitor(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.monitor, status: value);

    Preference.notifyMonitor = value.name;
    _log('Changed ${PreferenceKeys.notifyMonitor} to ${Preference.notifyMonitor}');
    notifyListeners();
  }

  /// 地震報告通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get report => EarthquakeNotifyType.values.byName(_report);
  Future<void> setReport(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.report, status: value);

    Preference.notifyReport = value.name;
    _log('Changed ${PreferenceKeys.notifyReport} to ${Preference.notifyReport}');
    notifyListeners();
  }

  /// 震度速報通知設定
  ///
  /// 預設：所在地震度1以上
  EarthquakeNotifyType get intensity => EarthquakeNotifyType.values.byName(_intensity);
  Future<void> setIntensity(EarthquakeNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.intensity, status: value);

    Preference.notifyIntensity = value.name;
    _log('Changed ${PreferenceKeys.notifyIntensity} to ${Preference.notifyIntensity}');
    notifyListeners();
  }

  /// 雷雨即時訊息通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get thunderstorm => WeatherNotifyType.values.byName(_thunderstorm);
  Future<void> setThunderstorm(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.thunderstorm, status: value);

    Preference.notifyThunderstorm = value.name;
    _log('Changed ${PreferenceKeys.notifyThunderstorm} to ${Preference.notifyThunderstorm}');
    notifyListeners();
  }

  /// 天氣景警特報通知設定
  ///
  /// 預設：接收所在地
  WeatherNotifyType get weatherAdvisory => WeatherNotifyType.values.byName(_weatherAdvisory);
  Future<void> setWeatherAdvisory(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.weatherAdvisory, status: value);

    Preference.notifyWeatherAdvisory = value.name;
    _log('Changed ${PreferenceKeys.notifyWeatherAdvisory} to ${Preference.notifyWeatherAdvisory}');
    notifyListeners();
  }

  /// 防災避難通知設定
  ///
  /// 預設：接收全部
  WeatherNotifyType get evacuation => WeatherNotifyType.values.byName(_evacuation);
  Future<void> setEvacuation(WeatherNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.evacuation, status: value);

    Preference.notifyEvacuation = value.name;
    _log('Changed ${PreferenceKeys.notifyEvacuation} to ${Preference.notifyEvacuation}');
    notifyListeners();
  }

  /// 海嘯通知設定
  ///
  /// 預設：海嘯警報、海嘯警報
  TsunamiNotifyType get tsunami => TsunamiNotifyType.values.byName(_tsunami);
  Future<void> setTsunami(TsunamiNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.tsunami, status: value);

    Preference.notifyTsunami = value.name;
    _log('Changed ${PreferenceKeys.notifyTsunami} to ${Preference.notifyTsunami}');
    notifyListeners();
  }

  /// 公告通知設定
  ///
  /// 預設：接收全部
  BasicNotifyType get announcement => BasicNotifyType.values.byName(_announcement);
  Future<void> setAnnouncement(BasicNotifyType value) async {
    await ExpTech().setNotify(token: Preference.notifyToken, channel: NotifyChannel.announcement, status: value);

    Preference.notifyAnnouncement = value.name;
    _log('Changed ${PreferenceKeys.notifyAnnouncement} to ${Preference.notifyAnnouncement}');
    notifyListeners();
  }
}
