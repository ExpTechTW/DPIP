/// Utilities, enumerations, and ID helpers shared across map layer managers.
library;

import 'package:dpip/widgets/map/map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The available overlay layers that can be toggled on the DPIP map.
enum MapLayer {
  /// Real-time seismic monitor showing station intensities and EEW circles.
  monitor,

  /// Historical earthquake report list and detail overlay.
  report,

  /// Tsunami warning boundaries and observation data.
  tsunami,

  /// Weather radar echo tile overlay.
  radar,

  /// Temperature station circles and labels.
  temperature,

  /// Precipitation station circles and labels.
  precipitation,

  /// Wind direction arrows and speed labels.
  wind,

  /// Lightning strike symbol overlay.
  lightning,
}

/// The subset of [MapLayer] values that relate to earthquake data.
const Set<MapLayer> kEarthquakeLayers = {
  MapLayer.monitor,
  MapLayer.report,
  MapLayer.tsunami,
};

/// The subset of [MapLayer] values that relate to weather data.
const Set<MapLayer> kWeatherLayers = {
  MapLayer.radar,
  MapLayer.temperature,
  MapLayer.precipitation,
  MapLayer.wind,
  MapLayer.lightning,
};

/// Defines which layer combinations are permitted when using overlay mode.
///
/// Each key maps to the full set of layers that may be active at the same time
/// as that layer.
const Map<MapLayer, Set<MapLayer>> kAllowedLayerCombinations = {
  MapLayer.monitor: {MapLayer.monitor},
  MapLayer.report: {MapLayer.report},
  MapLayer.tsunami: {MapLayer.tsunami},
  MapLayer.radar: {
    MapLayer.radar,
    MapLayer.temperature,
    MapLayer.precipitation,
    MapLayer.wind,
    MapLayer.lightning,
  },
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

/// Provides stable MapLibre GeoJSON source ID strings for each data type.
///
/// Pass an optional time or code suffix to obtain a time-specific ID,
/// or omit it to get the base ID.
class MapSourceIds {
  const MapSourceIds._();

  /// Returns the source ID for radar data, optionally scoped to [time].
  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';

  /// Returns the source ID for earthquake report data, optionally scoped to
  /// [time].
  static String report([String? time]) => time == null ? 'report' : 'report-$time';

  /// Returns the source ID for tsunami data, optionally scoped to [code].
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';

  /// Returns the source ID for real-time seismograph (RTS) data, optionally
  /// scoped to [time].
  static String rts([String? time]) => time == null ? 'rts' : 'rts-$time';

  /// Returns the source ID for EEW data, optionally scoped to [code].
  static String eew([String? code]) => code == null ? 'eew' : 'eew-$code';

  /// Returns the source ID for temperature data, optionally scoped to [time].
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';

  /// Returns the source ID for precipitation data, optionally scoped to
  /// [time].
  static String precipitation([String? time]) =>
      time == null ? 'precipitation' : 'precipitation-$time';

  /// Returns the source ID for wind data, optionally scoped to [time].
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';

  /// Returns the source ID for lightning data, optionally scoped to [time].
  static String lightning([String? time]) => time == null ? 'lightning' : 'lightning-$time';

  /// Returns the source ID for seismic intensity polygon data.
  static String intensity() => 'intensity';

  /// Returns the source ID for zero-intensity seismic polygon data.
  static String intensity0() => 'intensity0';

  /// Returns the source ID for detection box data.
  static String box() => 'box';
}

/// Provides stable MapLibre layer ID strings for each data type.
///
/// Pass an optional time or code suffix to obtain a time-specific ID,
/// or omit it to get the base ID.
class MapLayerIds {
  const MapLayerIds._();

  /// Returns the layer ID for radar data, optionally scoped to [time].
  static String radar([String? time]) => time == null ? 'radar' : 'radar-$time';

  /// Returns the layer ID for earthquake report data, optionally scoped to
  /// [time].
  static String report([String? time]) => time == null ? 'report' : 'report-$time';

  /// Returns the layer ID for tsunami data, optionally scoped to [code].
  static String tsunami([String? code]) => code == null ? 'tsunami' : 'tsunami-$code';

  /// Returns the layer ID for real-time seismograph (RTS) data, optionally
  /// scoped to [time].
  static String rts([String? time]) => time == null ? 'rts' : 'rts-$time';

  /// Returns the layer ID for EEW data, optionally scoped to [code].
  static String eew([String? code]) => code == null ? 'eew' : 'eew-$code';

  /// Returns the layer ID for temperature data, optionally scoped to [time].
  static String temperature([String? time]) => time == null ? 'temperature' : 'temperature-$time';

  /// Returns the layer ID for precipitation data, optionally scoped to [time].
  static String precipitation([String? time]) =>
      time == null ? 'precipitation' : 'precipitation-$time';

  /// Returns the layer ID for wind data, optionally scoped to [time].
  static String wind([String? time]) => time == null ? 'wind' : 'wind-$time';

  /// Returns the layer ID for lightning data, optionally scoped to [time].
  static String lightning([String? time]) => time == null ? 'lightning' : 'lightning-$time';

  /// Returns the layer ID for seismic intensity polygon data.
  static String intensity() => 'intensity';

  /// Returns the layer ID for zero-intensity seismic polygon data.
  static String intensity0() => 'intensity0';

  /// Returns the layer ID for detection box data.
  static String box() => 'box';
}

/// Removes all non-base-map layers and sources from [controller].
///
/// Preserves layers listed in [BaseMapLayerIds.values] and the `map` source.
Future<void> cleanupMap(MapLibreMapController controller) async {
  final layerIds = (await controller.getLayerIds()).cast<String>()
    ..removeWhere((v) => BaseMapLayerIds.values().contains(v));
  final sourceIds = (await controller.getSourceIds())..removeWhere((v) => v == 'map');

  for (final layerId in layerIds) {
    await controller.removeLayer(layerId);
  }

  for (final sourceId in sourceIds) {
    await controller.removeSource(sourceId);
  }
}
