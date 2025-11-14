import 'package:dpip/widgets/map/map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

extension MapLibreMapControllerExtension on MapLibreMapController {
  Future<void> setBaseMap(BaseMapType baseMapType) async {
    await Future.wait([
      setOSMVisibility(baseMapType == BaseMapType.osm),
      setGoogleVisibility(baseMapType == BaseMapType.google),
      setExptechVisibility(baseMapType == BaseMapType.exptech),
    ]);
  }

  Future<void> setOSMVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final osmLayers = layers.where((v) => v.startsWith('osm-'));

    await Future.wait(osmLayers.map((v) => setLayerVisibility(v, visible)));
  }

  Future<void> setGoogleVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final googleLayers = layers.where((v) => v.startsWith('google-'));

    await Future.wait(googleLayers.map((v) => setLayerVisibility(v, visible)));
  }

  Future<void> setExptechVisibility(bool visible) async {
    final layers = (await getLayerIds()).cast<String>();
    final exptechLayers = layers.where((v) => v.startsWith('exptech-'));

    await Future.wait(exptechLayers.map((v) => setLayerVisibility(v, visible)));
  }

  /// Checks if the provided [id] exists in the map as a source or layer.
  ///
  /// By default, checks both sources and layers. Use [source] and [layer]
  /// parameters to limit the search scope:
  /// - If [source] is `true`, only sources will be checked
  /// - If [layer] is `true`, only layers will be checked
  /// - If both are `true`, both sources and layers will be checked
  ///
  /// Returns `true` if the [id] exists in any of the checked categories, otherwise, returns `false`.
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
