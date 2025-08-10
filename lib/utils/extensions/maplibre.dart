import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/widgets/map/map.dart';

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
}
