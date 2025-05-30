import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/widgets/map/map.dart';

enum MapLayer { monitor, report, tsunami, radar, temperature, precipitation, wind }

class MapSourceIds {
  const MapSourceIds._();

  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';
  static String report([String? time]) => time == null ? 'report' : 'report-$time';
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';
  static String monitor([String? code]) => code == null ? 'monitor' : 'monitor-$code';
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';
  static String precipitation([String? time]) => time == null ? 'precipitation' : 'precipitation-$time';
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';
}

class MapLayerIds {
  const MapLayerIds._();

  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';
  static String report([String? time]) => time == null ? 'report' : 'report-$time';
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';
  static String monitor([String? code]) => code == null ? 'monitor' : 'monitor-$code';
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';
  static String precipitation([String? time]) => time == null ? 'precipitation' : 'precipitation-$time';
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';
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
