/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (theme-driven colours, no API key), shared
/// by the live map tab and the off-screen home snapshot so both look identical.
library;

/// Id of the county-outline layer — overlays (radar) can anchor below it so the
/// borders stay legible on top.
const String outlineLayerId = 'county-outline';

/// Taiwan framing shared by the live map and the home snapshot.
const double taiwanLat = 23.60;
const double taiwanLng = 120.85;
const double taiwanZoom = 6.4;

/// Builds the ExpTech vector base-map style — the ExpTech vector tiles plus an
/// optional [radarTileUrl] radar echo overlay — as a MapLibre style JSON string.
///
/// Colours are theme-driven so the map adapts to light/dark: [sea] behind,
/// [land] for the global fill, [countyTown] for county/town fills, and [outline]
/// for the county borders. Label-free, with radar under the outlines so borders
/// stay legible. Used by both the live map tab and the home snapshot.
String exptechVectorStyle({
  required String sea,
  required String land,
  required String countyTown,
  required String outline,
  String? radarTileUrl,
  int? selectedTownCode,
}) {
  final radarSource = radarTileUrl == null
      ? ''
      : ',"radar":{"type":"raster","tiles":["$radarTileUrl"],"tileSize":256}';
  final radarLayer = radarTileUrl == null
      ? ''
      : '{"id":"radar","type":"raster","source":"radar","paint":{"raster-opacity":0.8}},';
  // Selected township: a purple fill + border, filtered directly on the vector
  // `town` layer by its `CODE` property (an integer) — no extra GeoJSON source.
  final selectedFilter = '["==", ["get", "CODE"], $selectedTownCode]';
  final selectedLayers = selectedTownCode == null
      ? ''
      : ',{ "id": "selected-fill", "type": "fill", "source": "exptech", "source-layer": "town", "filter": $selectedFilter, "paint": { "fill-color": "$selectedColor", "fill-opacity": 0.1 } },'
            '{ "id": "selected-outline", "type": "line", "source": "exptech", "source-layer": "town", "filter": $selectedFilter, "paint": { "line-color": "$selectedColor", "line-width": 2.5 } }';
  return '''
{
  "version": 8,
  "sources": {
    "exptech": { "type": "vector", "tiles": ["https://lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf"], "maxzoom": 12 }$radarSource
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$sea" } },
    { "id": "land", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$land" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$countyTown" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$countyTown" } },
    $radarLayer{ "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 0.6 } }$selectedLayers
  ]
}''';
}

/// Purple used to highlight the selected township (fill + border).
const String selectedColor = '#7C4DFF';
