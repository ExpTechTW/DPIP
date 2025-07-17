import 'dart:developer';

import 'package:dpip/core/preference.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class SettingsLocationModel extends ChangeNotifier {
  void _log(String message) => log(message, name: 'SettingsLocationModel');

  bool get _auto => Preference.locationAuto ?? false;
  final ValueNotifier<String?> codeNotifier = ValueNotifier(Preference.locationCode);
  final ValueNotifier<LatLng> coordinateNotifier = ValueNotifier(
    LatLng(Preference.locationLatitude ?? 0, Preference.locationLongitude ?? 0),
  );
  double? get _oldLongitude => Preference.locationOldLongitude;
  double? get _oldLatitude => Preference.locationOldLatitude;

  /// 自動定位
  ///
  /// 預設：不自動定位
  bool get auto => _auto;
  void setAuto(bool value) {
    Preference.locationAuto = value;
    _log('Changed ${PreferenceKeys.locationAuto} to ${Preference.locationAuto}');
    notifyListeners();
  }

  /// 縣市代碼
  String? get code => Preference.locationCode;
  void setCode(String? value) {
    Preference.locationCode = value;
    codeNotifier.value = value;
    _log('Changed ${PreferenceKeys.locationCode} to ${Preference.locationCode}');
    notifyListeners();
  }

  /// 經度
  double? get longitude => Preference.locationLongitude;

  /// 緯度
  double? get latitude => Preference.locationLatitude;
  void setLatLng({double? latitude, double? longitude}) {
    Preference.locationLatitude = latitude;
    _log('Changed ${PreferenceKeys.locationLatitude} to ${Preference.locationLatitude}');

    Preference.locationLongitude = longitude;
    _log('Changed ${PreferenceKeys.locationLongitude} to ${Preference.locationLongitude}');

    coordinateNotifier.value = LatLng(latitude ?? 0, longitude ?? 0);

    notifyListeners();
  }

  /// 經度
  double? get oldLongitude => _oldLongitude;
  void setOldLongitude(double? value) {
    Preference.locationOldLongitude = value;
    _log('Changed ${PreferenceKeys.locationOldLongitude} to ${Preference.locationOldLongitude}');
    notifyListeners();
  }

  /// 緯度
  double? get oldLatitude => _oldLatitude;
  void setOldLatitude(double? value) {
    Preference.locationOldLatitude = value;
    _log('Changed ${PreferenceKeys.locationOldLatitude} to ${Preference.locationOldLatitude}');
    notifyListeners();
  }
}
