/// Persisted custom order for the map layer picker.
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter/foundation.dart';

/// Holds the user's saved layer order as a list of layer ids, persisted across
/// launches and shared by every map surface (each surface resolves it against
/// its own layer set — see `orderedLayers` in `shared/map/map_layer_order.dart`).
class MapLayerOrderController extends ChangeNotifier {
  MapLayerOrderController(this._prefs)
    : _order = _prefs.getStringList(PreferenceKeys.mapLayerOrder) ?? const [];

  final Prefs _prefs;
  List<String> _order;

  /// Saved layer-id order, most-preferred first. Empty when the user has never
  /// customised it — layers then keep the surface's declared order.
  List<String> get order => List.unmodifiable(_order);

  /// Persists [order] and notifies watchers (the layer picker rebuilds in the
  /// new order). Ids of layers a surface doesn't offer are tolerated by
  /// `orderedLayers`, so no validation happens here.
  Future<void> setOrder(List<String> order) async {
    if (listEquals(order, _order)) return;
    _order = List.of(order);
    await _prefs.setStringList(PreferenceKeys.mapLayerOrder, _order);
    notifyListeners();
  }

  /// Clears the saved order — every surface falls back to its declared order.
  Future<void> reset() async {
    if (_order.isEmpty) return;
    _order = const [];
    await _prefs.remove(PreferenceKeys.mapLayerOrder);
    notifyListeners();
  }
}
