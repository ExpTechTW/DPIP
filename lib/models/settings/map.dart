import 'dart:collection';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/iterable.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';

class SettingsMapModel extends ChangeNotifier {
  void _log(String message) => TalkerManager.instance.info('[SettingsMapModel] $message');

  final updateIntervalNotifier = ValueNotifier(Preference.mapUpdateFps ?? 10);
  final baseMapNotifier = ValueNotifier(BaseMapType.values.asNameMap()[Preference.mapBase] ?? BaseMapType.exptech);
  final layersNotifier = ValueNotifier(
    Preference.mapLayers?.split(',').map((v) => MapLayer.values.byName(v)).toSet() ?? {MapLayer.monitor},
  );

  int get updateInterval => updateIntervalNotifier.value;
  void setUpdateInterval(int value) {
    Preference.mapUpdateFps = value;
    updateIntervalNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapUpdateFps} to ${Preference.mapUpdateFps}');
    notifyListeners();
  }

  BaseMapType get baseMap => baseMapNotifier.value;
  void setBaseMapType(BaseMapType value) {
    Preference.mapBase = value.name;
    baseMapNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapBase} to $value');
    notifyListeners();
  }

  UnmodifiableSetView<MapLayer> get layers => UnmodifiableSetView(layersNotifier.value.orderedBy(MapLayer.values));
  void setLayers(Set<MapLayer> value) {
    final sorted = value.orderedBy(MapLayer.values);
    Preference.mapLayers = sorted.map((e) => e.name).join(',');
    layersNotifier.value = sorted;
    _log('Changed ${PreferenceKeys.mapLayers} to $value');
    notifyListeners();
  }

  /// Refreshes the map settings from preferences.
  ///
  /// Updates the [updateInterval], [baseMap], and [layers] properties to reflect the current preferences.
  ///
  /// This method is used to refresh the map settings when the preferences are updated.
  void refresh() {
    updateIntervalNotifier.value = Preference.mapUpdateFps ?? 10;
    baseMapNotifier.value = BaseMapType.values.asNameMap()[Preference.mapBase] ?? BaseMapType.exptech;
    layersNotifier.value =
        Preference.mapLayers?.split(',').map((v) => MapLayer.values.byName(v)).toSet() ?? {MapLayer.monitor};
  }
}
