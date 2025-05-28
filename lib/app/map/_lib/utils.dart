import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/widgets/map/map.dart';

enum MapLayer { monitor, report, tsunami, radar, temperature, precipitation, wind }

class MapSourceIds {
  static const radar = 'radar';
}

class MapLayerIds {
  const MapLayerIds._();

  static const radar = 'radar';

  static Iterable<String> values() sync* {
    yield radar;
  }
}

Future<void> cleanupMap(MapLibreMapController controller) async {
  final layerIds =
      (await controller.getLayerIds()).cast<String>()..removeWhere((v) => BaseMapLayerIds.values().contains(v));
  final sourceIds = (await controller.getSourceIds())..removeWhere((v) => v == 'map');

  for (final layerId in layerIds) {
    await controller.removeLayer(layerId);
  }

  for (final sourceId in sourceIds) {
    await controller.removeSource(sourceId);
  }
}
