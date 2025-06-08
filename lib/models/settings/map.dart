import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';

class SettingsMapModel extends ChangeNotifier {
  void _log(String message) => TalkerManager.instance.info('[SettingsMapModel] $message');

  final updateIntervalNotifier = ValueNotifier(200);
  final baseMapNotifier = ValueNotifier(BaseMapType.exptech);
  final layerNotifier = ValueNotifier(MapLayer.report);

  int get updateInterval => Preference.mapUpdateInterval ?? 200;
  void setUpdateInterval(int value) {
    Preference.mapUpdateInterval = value;
    updateIntervalNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapUpdateInterval} to ${Preference.mapUpdateInterval}');
    notifyListeners();
  }

  BaseMapType get baseMap => baseMapNotifier.value;
  void setBaseMapType(BaseMapType value) {
    baseMapNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapBase} to $value');
    notifyListeners();
  }

  MapLayer get layer => layerNotifier.value;
  void setLayer(MapLayer value) {
    layerNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapLayer} to $value');
    notifyListeners();
  }
}
