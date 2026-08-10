/// Persisted custom order for the map layer picker — both the layer order and
/// the category order, so a reordered picker keeps its groups *and* their
/// internal layer sequence across launches.
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter/foundation.dart';

/// Holds the user's saved layer order (layer ids) and category order (category
/// names), persisted across launches and shared by every map surface. Each
/// surface resolves them against its own layer set / the current category set —
/// see `orderedLayers` / `orderedCategories` in `shared/map/map_layer_order.dart`.
class MapLayerOrderController extends ChangeNotifier {
  MapLayerOrderController(this._prefs)
    : _order = _prefs.getStringList(PreferenceKeys.mapLayerOrder) ?? const [],
      _categoryOrder =
          _prefs.getStringList(PreferenceKeys.mapLayerCategoryOrder) ??
          const [];

  final Prefs _prefs;
  List<String> _order;
  List<String> _categoryOrder;

  /// Saved layer-id order, most-preferred first. Empty when the user has never
  /// customised it — layers then keep the surface's declared order.
  List<String> get order => List.unmodifiable(_order);

  /// Saved category-name order, most-preferred first. Empty when the user has
  /// never customised it — categories then keep their declared order.
  List<String> get categoryOrder => List.unmodifiable(_categoryOrder);

  /// Persists [order] and notifies watchers (the layer picker rebuilds in the
  /// new order). Ids of layers a surface doesn't offer are tolerated by
  /// `orderedLayers`, so no validation happens here.
  Future<void> setOrder(List<String> order) async {
    if (listEquals(order, _order)) return;
    _order = List.of(order);
    await _prefs.setStringList(PreferenceKeys.mapLayerOrder, _order);
    notifyListeners();
  }

  /// Persists [order] (category names) and notifies watchers. Names of
  /// categories that no longer exist are tolerated by `orderedCategories`, so
  /// no validation happens here.
  Future<void> setCategoryOrder(List<String> order) async {
    if (listEquals(order, _categoryOrder)) return;
    _categoryOrder = List.of(order);
    await _prefs.setStringList(
      PreferenceKeys.mapLayerCategoryOrder,
      _categoryOrder,
    );
    notifyListeners();
  }

  /// Clears the saved layer and category order — every surface falls back to
  /// its declared order.
  Future<void> reset() async {
    var changed = false;
    if (_order.isNotEmpty) {
      _order = const [];
      await _prefs.remove(PreferenceKeys.mapLayerOrder);
      changed = true;
    }
    if (_categoryOrder.isNotEmpty) {
      _categoryOrder = const [];
      await _prefs.remove(PreferenceKeys.mapLayerCategoryOrder);
      changed = true;
    }
    if (changed) notifyListeners();
  }
}
