import 'dart:collection';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';

class SettingsMapModel extends ChangeNotifier {
  void _log(String message) => TalkerManager.instance.info('[SettingsMapModel] $message');

  final updateIntervalNotifier = ValueNotifier(200);
  final baseMapNotifier = ValueNotifier(BaseMapType.exptech);
  final layersNotifier = ValueNotifier([MapLayer.monitor]);

  int get updateInterval => Preference.mapUpdateInterval ?? 10;
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

  UnmodifiableListView<MapLayer> get layers => UnmodifiableListView(layersNotifier.value);
  void setLayer(List<MapLayer> value) {
    layersNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapLayer} to $value');
    notifyListeners();
  }
}
