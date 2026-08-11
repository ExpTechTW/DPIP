/// Safe ordering of a map surface's layers by a persisted preference.
library;

import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_category.dart';

/// [layers] ordered by [order] (layer ids, most-preferred first).
///
/// The saved order is a snapshot of ids that the surface can outgrow: a layer
/// added after the order was saved is **not** in it, and one that was removed
/// may still be. This merge is the tolerance for both:
/// - ids in [order] with no matching layer are ignored (a stale id can never
///   throw an index error);
/// - layers not in [order] keep the surface's declared relative order and are
///   appended after every ordered one, so a brand-new layer appears at the
///   bottom without the user being asked to place it;
/// - duplicate ids in [order] count once.
///
/// Every layer in [layers] appears exactly once.
List<MapLayer> orderedLayers(List<MapLayer> layers, List<String> order) {
  if (layers.isEmpty) return layers;
  final byId = {for (final layer in layers) layer.id: layer};
  final placed = <String>{};
  final ordered = <MapLayer>[];
  for (final id in order) {
    final layer = byId[id];
    if (layer == null || !placed.add(id)) continue;
    ordered.add(layer);
  }
  return [
    ...ordered,
    for (final layer in layers)
      if (placed.add(layer.id)) layer,
  ];
}

/// [all] (the declared category set, in declared order) re-ordered by [order]
/// (category names, most-preferred first).
///
/// Mirrors [orderedLayers]' tolerance so the persisted category order can
/// outgrow the code that wrote it:
/// - a name in [order] with no matching category is ignored;
/// - a category not in [order] keeps its declared position and is appended
///   after every ordered one, so a category added later — or the very first
///   launch, when nothing was saved — still shows up;
/// - duplicate names count once.
///
/// Every category in [all] appears exactly once.
List<MapLayerCategory> orderedCategories(
  List<MapLayerCategory> all,
  List<String> order,
) {
  final byName = {for (final category in all) category.name: category};
  final placed = <MapLayerCategory>{};
  final ordered = <MapLayerCategory>[];
  for (final name in order) {
    final category = byName[name];
    if (category == null || !placed.add(category)) continue;
    ordered.add(category);
  }
  return [
    ...ordered,
    for (final category in all)
      if (placed.add(category)) category,
  ];
}
