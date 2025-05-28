import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';

class SettingsMapModel extends ChangeNotifier {
  void _log(String message) => TalkerManager.instance.info('[SettingsMapModel] $message');

  final updateIntervalNotifier = ValueNotifier(200);

  int get updateInterval => Preference.mapUpdateInterval ?? 200;
  void setUpdateInterval(int value) {
    Preference.mapUpdateInterval = value;
    updateIntervalNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapUpdateInterval} to ${Preference.mapUpdateInterval}');
    notifyListeners();
  }
}
