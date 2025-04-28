import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dpip/core/preference.dart';

class SettingsLocationModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsLocationModel');

  bool _auto = Preference.locationAuto ?? false;
  String? _code = Preference.locationCode;

  /// 自動定位
  ///
  /// 預設：不自動定位
  bool get auto => _auto;
  void setAuto(bool value) {
    _auto = value;
    Preference.locationAuto = _auto;
    _log('Changed ${PreferenceKeys.locationAuto} to ${Preference.locationAuto}');
    notifyListeners();
  }

  /// 縣市代碼
  String? get code => _code;
  void setCode(String? value) {
    _code = value;
    Preference.locationCode = _code;
    _log('Changed ${PreferenceKeys.locationCode} to ${Preference.locationCode}');
    notifyListeners();
  }
}
