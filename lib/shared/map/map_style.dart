/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (theme-driven colours, no API key), shared
/// by the live map tab and the home backdrop so both look identical.
library;

/// Id of the county-outline layer — overlays (radar) anchor below it so the
/// county borders stay legible on top.
const String outlineLayerId = 'county-outline';

/// Id of the faint township-outline layer (below the county borders).
const String townOutlineLayerId = 'town-outline';

/// Builds the ExpTech vector base-map style as a MapLibre style JSON string.
///
/// Colours are theme-driven so the map adapts to light/dark: [sea] behind,
/// [land] for the global fill, [countyTown] for the county/town fills,
/// [townOutline] for the faint township borders, and [outline] for the stronger
/// county borders drawn on top. The base draws no labels itself, but declares a
/// `glyphs` endpoint (the ExpTech map-assets CDN) so overlay layers can render
/// `text-field` symbols (e.g. station name/value labels). Overlays (radar)
/// anchor below [outlineLayerId] so the county borders stay legible. Used by
/// every map surface (live map tab, home backdrop) so they look identical.
String exptechVectorStyle({
  required String sea,
  required String land,
  required String countyTown,
  required String outline,
  required String townOutline,
}) {
  return '''
{
  "version": 8,
  "glyphs": "https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf",
  "sources": {
    "exptech": { "type": "vector", "tiles": ["https://lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf"], "maxzoom": 12 }
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$sea" } },
    { "id": "land", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$land" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$countyTown" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$countyTown" } },
    { "id": "$townOutlineLayerId", "type": "line", "source": "exptech", "source-layer": "town", "paint": { "line-color": "$townOutline", "line-width": 0.4 } },
    { "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 0.6 } }
  ]
}''';
}

/// Purple used to highlight the selected township (fill + border).
const String selectedColor = '#7C4DFF';
