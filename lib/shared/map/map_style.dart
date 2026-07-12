/// MapLibre style definitions for the app's base map.
///
/// A self-contained OpenStreetMap raster style (no API key), kept minimal so
/// overlays (radar, etc.) sit clearly on top. The ExpTech vector base from the
/// legacy design can be added as an alternative style later.
library;

/// Id of the base layer — overlays anchor above it.
const String baseLayerId = 'osm-base';

/// Taiwan framing shared by the live map and the home snapshot.
const double taiwanLat = 23.60;
const double taiwanLng = 120.85;
const double taiwanZoom = 6.4;

/// Builds the home backdrop style — the ExpTech vector base map plus an optional
/// [radarTileUrl] radar echo overlay — as a MapLibre style JSON string.
///
/// Colours mirror the legacy map (theme-driven, so it adapts to light/dark):
/// [sea] behind, [land] for the global fill, [countyTown] for county/town fills,
/// and [outline] for the county borders. Rendered off-screen to a static image
/// (see `MapSnapshot`); label-free, with radar under the outlines so borders
/// stay legible.
String homeSnapshotStyle({
  required String sea,
  required String land,
  required String countyTown,
  required String outline,
  String? radarTileUrl,
}) {
  final radarSource = radarTileUrl == null
      ? ''
      : ',"radar":{"type":"raster","tiles":["$radarTileUrl"],"tileSize":256}';
  final radarLayer = radarTileUrl == null
      ? ''
      : '{"id":"radar","type":"raster","source":"radar","paint":{"raster-opacity":0.8}},';
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
    $radarLayer{ "id": "county-outline", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 0.6 } }
  ]
}''';
}

/// A minimal OSM raster MapLibre style (GL Style Spec v8), as a JSON string.
const String osmRasterStyle =
    '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [
    { "id": "$baseLayerId", "type": "raster", "source": "osm" }
  ]
}
''';
