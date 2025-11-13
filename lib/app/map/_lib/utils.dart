import 'package:dpip/widgets/map/map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

enum MapLayer { monitor, report, tsunami, radar, temperature, precipitation, wind, lightning }

const Set<MapLayer> kEarthquakeLayers = {MapLayer.monitor, MapLayer.report, MapLayer.tsunami};

const Set<MapLayer> kWeatherLayers = {MapLayer.radar, MapLayer.temperature, MapLayer.precipitation, MapLayer.wind, MapLayer.lightning};

const Map<MapLayer, Set<MapLayer>> kAllowedLayerCombinations = {
  MapLayer.monitor: {MapLayer.monitor},
  MapLayer.report: {MapLayer.report},
  MapLayer.tsunami: {MapLayer.tsunami},
  MapLayer.radar: {MapLayer.radar, MapLayer.temperature, MapLayer.precipitation, MapLayer.wind, MapLayer.lightning},
  MapLayer.temperature: {MapLayer.radar, MapLayer.temperature},
  MapLayer.precipitation: {MapLayer.radar, MapLayer.precipitation},
  MapLayer.wind: {MapLayer.radar, MapLayer.wind},
  MapLayer.lightning: {MapLayer.radar, MapLayer.lightning},
};

/// Validates if a combination of map layers follows the defined rules.
///
/// Returns true if:
/// - earthquakeLayers.length ≤ 1 AND one of:
///   - weatherLayers.length == 0
///   - weatherLayers.length == 1
///   - weatherLayers.length == 2 AND weatherLayers contains radar AND
///     the other layer exists in _allowedRadarCombinations
///
/// Where:
/// - earthquakeLayers = layers ∩ _earthquakeLayers
/// - weatherLayers = layers ∩ _weatherLayers
bool isValidLayerCombination(Set<MapLayer> layers) {
  final earthquakeLayerCount = layers.where((l) => kEarthquakeLayers.contains(l)).length;
  if (earthquakeLayerCount > 1) return false;

  final weatherLayers = layers.where((l) => kWeatherLayers.contains(l)).toSet();

  if (weatherLayers.length == 1) return true;

  if (weatherLayers.length == 2) {
    if (weatherLayers.contains(MapLayer.radar)) {
      final otherLayer = weatherLayers.where((l) => l != MapLayer.radar).first;
      return kAllowedLayerCombinations.containsKey(otherLayer);
    }
  }

  return false;
}

class MapSourceIds {
  const MapSourceIds._();

  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';
  static String report([String? time]) => time == null ? 'report' : 'report-$time';
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';
  static String rts([String? time]) => time == null ? 'rts' : 'rts-$time';
  static String eew([String? code]) => code == null ? 'eew' : 'eew-$code';
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';
  static String precipitation([String? time]) => time == null ? 'precipitation' : 'precipitation-$time';
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';
  static String lightning([String? time]) => time == null ? 'lightning' : 'lightning-$time';
  static String intensity() => 'intensity';
  static String intensity0() => 'intensity0';
  static String box() => 'box';
}

class MapLayerIds {
  const MapLayerIds._();

  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';
  static String report([String? time]) => time == null ? 'report' : 'report-$time';
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';
  static String rts([String? time]) => time == null ? 'rts' : 'rts-$time';
  static String eew([String? code]) => code == null ? 'eew' : 'eew-$code';
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';
  static String precipitation([String? time]) => time == null ? 'precipitation' : 'precipitation-$time';
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';
  static String lightning([String? time]) => time == null ? 'lightning' : 'lightning-$time';
  static String intensity() => 'intensity';
  static String intensity0() => 'intensity0';
  static String box() => 'box';
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
