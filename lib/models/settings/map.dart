import 'dart:collection';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/utils/extensions/iterable.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _SettingsMapModel extends ChangeNotifier {
  void _log(String message) => TalkerManager.instance.info('[SettingsMapModel] $message');

  /// The underlying [ValueNotifier] for the map update interval in frames per second.
  ///
  /// Returns the stored FPS value from preferences. Defaults to `10` if no
  /// value has been set.
  final updateIntervalNotifier = ValueNotifier(Preference.mapUpdateFps ?? 10);

  /// The current map update interval in frames per second.
  ///
  /// Returns the stored FPS value from preferences. Defaults to `10` if no
  /// value has been set.
  int get updateInterval => updateIntervalNotifier.value;

  /// Sets the map update interval in frames per second.
  ///
  /// Persists [value] to preferences, updates [updateIntervalNotifier], and
  /// notifies all attached listeners.
  void setUpdateInterval(int value) {
    Preference.mapUpdateFps = value;
    updateIntervalNotifier.value = value;
    _log(
      'Changed ${PreferenceKeys.mapUpdateFps} to ${Preference.mapUpdateFps}',
    );
    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the active base map type.
  ///
  /// Returns the stored [BaseMapType] from preferences. Defaults to
  /// [BaseMapType.exptech] if no value has been set.
  final baseMapNotifier = ValueNotifier(
    BaseMapType.values.asNameMap()[Preference.mapBase] ?? BaseMapType.exptech,
  );

  /// The active base map type.
  ///
  /// Returns the stored [BaseMapType] from preferences. Defaults to
  /// [BaseMapType.exptech] if no value has been set.
  BaseMapType get baseMap => baseMapNotifier.value;

  /// Sets the active base map type.
  ///
  /// Persists [value] to preferences, updates [baseMapNotifier], and notifies
  /// all attached listeners.
  void setBaseMapType(BaseMapType value) {
    Preference.mapBase = value.name;
    baseMapNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapBase} to $value');
    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the set of active map layers.
  ///
  /// Returns the stored [Set<MapLayer>] from preferences. Defaults to
  /// `{MapLayer.monitor}` if no value has been set.
  final layersNotifier = ValueNotifier(
    Preference.mapLayers?.split(',').map((v) => MapLayer.values.byName(v)).toSet() ??
        {MapLayer.monitor},
  );

  /// The set of active map layers, ordered by [MapLayer.values].
  ///
  /// Returns an [UnmodifiableSetView<MapLayer>] from preferences. Defaults to
  /// `{MapLayer.monitor}` if no value has been set.
  UnmodifiableSetView<MapLayer> get layers =>
      UnmodifiableSetView(layersNotifier.value.orderedBy(MapLayer.values));

  /// Sets the active map layers.
  ///
  /// Sorts [value] by [MapLayer.values] order, persists it to preferences,
  /// updates [layersNotifier], and notifies all attached listeners.
  void setLayers(Set<MapLayer> value) {
    final sorted = value.orderedBy(MapLayer.values);
    Preference.mapLayers = sorted.map((e) => e.name).join(',');
    layersNotifier.value = sorted;
    _log('Changed ${PreferenceKeys.mapLayers} to $value');
    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the auto-zoom setting.
  ///
  /// Returns a [bool] indicating whether the map should automatically zoom to
  /// relevant events. Defaults to `false` if no value has been set.
  final autoZoomNotifier = ValueNotifier(Preference.mapAutoZoom ?? false);

  /// Whether the map automatically zooms to relevant events.
  ///
  /// Returns a [bool] from preferences. Defaults to `false` if no value has
  /// been set.
  bool get autoZoom => autoZoomNotifier.value;

  /// Sets whether the map should automatically zoom to relevant events.
  ///
  /// Persists [value] to preferences, updates [autoZoomNotifier], and notifies
  /// all attached listeners.
  void setAutoZoom(bool value) {
    Preference.mapAutoZoom = value;
    autoZoomNotifier.value = value;
    _log('Changed ${PreferenceKeys.mapAutoZoom} to $value');
    notifyListeners();
  }

  /// Refreshes the map settings from preferences.
  ///
  /// Updates [updateInterval], [baseMap], [layers], and [autoZoom] to reflect
  /// the current preferences, then notifies all attached listeners.
  void refresh() {
    updateIntervalNotifier.value = Preference.mapUpdateFps ?? 10;
    baseMapNotifier.value =
        BaseMapType.values.asNameMap()[Preference.mapBase] ?? BaseMapType.exptech;
    layersNotifier.value =
        Preference.mapLayers?.split(',').map((v) => MapLayer.values.byName(v)).toSet() ??
        {MapLayer.monitor};
    autoZoomNotifier.value = Preference.mapAutoZoom ?? false;
  }
}

class SettingsMapModel extends _SettingsMapModel {}

extension SettingsMapModelExtension on BuildContext {
  /// Watches [SettingsMapModel] and rebuilds when it notifies listeners.
  SettingsMapModel get useMap => watch<SettingsMapModel>();

  /// Reads [SettingsMapModel] without subscribing to updates.
  SettingsMapModel get map => read<SettingsMapModel>();
}
