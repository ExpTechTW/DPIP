import 'package:dpip/widgets/map/map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Extension on [MapLibreMapController] that provides convenient utilities for map layer and base map management.
///
/// This extension adds helpful methods to simplify common map operations, including base map switching, layer
/// visibility control, and resource existence checking.
extension MapLibreMapControllerExtension on MapLibreMapController {
  /// Sets the base map type and updates the visibility of all base map layers accordingly.
  ///
  /// This method switches between different base map providers (OSM, Google, Exptech) by showing the selected base map
  /// and hiding the others. All visibility changes are applied concurrently for better performance.
  ///
  /// Example:
  /// ```dart
  /// await controller.setBaseMap(BaseMapType.exptech);
  /// ```
  Future<void> setBaseMap(BaseMapType baseMapType) async {
    await Future.wait([
      setOSMVisibility(baseMapType == BaseMapType.osm),
      setGoogleVisibility(baseMapType == BaseMapType.google),
      setExptechVisibility(baseMapType == BaseMapType.exptech),
    ]);
  }

  /// Sets the visibility of all OSM (OpenStreetMap) layers.
  ///
  /// Finds all layers with IDs starting with 'osm-' and sets their visibility to [visible]. All layer visibility
  /// changes are applied concurrently for better performance.
  ///
  /// Example:
  /// ```dart
  /// await controller.setOSMVisibility(true); // Show all OSM layers
  /// await controller.setOSMVisibility(false); // Hide all OSM layers
  /// ```
  Future<void> setOSMVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final osmLayers = layers.where((v) => v.startsWith('osm-'));

    await Future.wait(osmLayers.map((v) => setLayerVisibility(v, visible)));
  }

  /// Sets the visibility of all Google Maps layers.
  ///
  /// Finds all layers with IDs starting with 'google-' and sets their visibility to [visible]. All layer visibility
  /// changes are applied concurrently for better performance.
  ///
  /// Example:
  /// ```dart
  /// await controller.setGoogleVisibility(true); // Show all Google layers
  /// await controller.setGoogleVisibility(false); // Hide all Google layers
  /// ```
  Future<void> setGoogleVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final googleLayers = layers.where((v) => v.startsWith('google-'));

    await Future.wait(googleLayers.map((v) => setLayerVisibility(v, visible)));
  }

  /// Sets the visibility of all Exptech base map layers.
  ///
  /// Finds all layers with IDs starting with 'exptech-' and sets their visibility to [visible]. All layer visibility
  /// changes are applied concurrently for better performance.
  ///
  /// Example:
  /// ```dart
  /// await controller.setExptechVisibility(true); // Show all Exptech layers
  /// await controller.setExptechVisibility(false); // Hide all Exptech layers
  /// ```
  Future<void> setExptechVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final exptechLayers = layers.where((v) => v.startsWith('exptech-'));

    await Future.wait(exptechLayers.map((v) => setLayerVisibility(v, visible)));
  }

  /// Checks if the provided [id] exists in the map as a source or layer.
  ///
  /// By default, checks both sources and layers. Use [source] and [layer] parameters to limit the search scope:
  /// - If [source] is `true`, only sources will be checked
  /// - If [layer] is `true`, only layers will be checked
  /// - If both are `true`, both sources and layers will be checked
  ///
  /// Returns `true` if the [id] exists in any of the checked categories, otherwise, returns `false`.
  ///
  /// Example:
  /// ```dart
  /// // Check if a layer exists
  /// final layerExists = await controller.exists('my-layer', layer: true);
  ///
  /// // Check if a source exists
  /// final sourceExists = await controller.exists('my-source', source: true);
  ///
  /// // Check both (default behavior)
  /// final exists = await controller.exists('my-resource');
  /// ```
  Future<bool> exists(String id, {bool? source, bool? layer}) async {
    final shouldCheckBoth = source == null && layer == null;

    final checkSource = shouldCheckBoth || (source ?? false);
    final checkLayer = shouldCheckBoth || (layer ?? false);

    if (checkSource) {
      final sourceIds = await getSourceIds();
      if (sourceIds.contains(id)) return true;
    }

    if (checkLayer) {
      final layerIds = await getLayerIds();
      if (layerIds.contains(id)) return true;
    }

    return false;
  }
}
