/// MapLibre style definitions for the app's base map.
///
/// A self-contained OpenStreetMap raster style (no API key), kept minimal so
/// overlays (radar, etc.) sit clearly on top. The ExpTech vector base from the
/// legacy design can be added as an alternative style later.
library;

/// Id of the base layer — overlays anchor above it.
const String baseLayerId = 'osm-base';

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
