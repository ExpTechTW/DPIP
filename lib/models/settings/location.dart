import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dpip/core/preference.dart';

class SettingsLocationModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsLocationModel');

  bool _auto = Preference.locationAuto ?? false;
  String? _code = Preference.locationCode;
  double? _longitude = Preference.locationLongitude;
  double? _latitude = Preference.locationLatitude;

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

  /// 經度
  double? get longitude => _longitude;
  void setLongitude(double? value) {
    _longitude = value;
    Preference.locationLongitude = _longitude;
    _log('Changed ${PreferenceKeys.locationLongitude} to ${Preference.locationLongitude}');
    notifyListeners();
  }

  /// 緯度
  double? get latitude => _latitude;
  void setLatitude(double? value) {
    _latitude = value;
    Preference.locationLatitude = _latitude;
    _log('Changed ${PreferenceKeys.locationLatitude} to ${Preference.locationLatitude}');
    notifyListeners();
  }
}
