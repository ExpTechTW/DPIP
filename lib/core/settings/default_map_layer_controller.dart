/// Persisted default map overlay for the Map tab (+ bottom-nav chrome).
library;

import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/persisted.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// Holds the user's chosen [DefaultMapLayer], persisted across launches.
///
/// Drives [MapScaffold]'s initial overlay and the Map tab's bottom-nav icon /
/// label. Fallback is [DefaultMapLayer.radar] (historical default).
class DefaultMapLayerController extends ChangeNotifier {
  DefaultMapLayerController(SettingsStore settings)
    : _layer = PersistedEnum(
        settings,
        key: SettingKeys.defaultMapLayer,
        values: DefaultMapLayer.values,
        fallback: DefaultMapLayer.radar,
      );

  final PersistedEnum<DefaultMapLayer> _layer;

  /// The overlay the map tab should open on.
  DefaultMapLayer get layer => _layer.value;

  /// Persists [next] and notifies watchers (nav chrome + map).
  void setLayer(DefaultMapLayer next) {
    if (_layer.set(next)) notifyListeners();
  }
}
