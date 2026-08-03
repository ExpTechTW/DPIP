/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (fixed palette, no API key), shared by
/// the live map tab and the home backdrop so both look identical.
library;

/// Fixed base-map palette — independent of [ColorScheme] so light/dark UI
/// doesn't recolour the cartography (overlays stay readable on a stable ground).
abstract final class MapColors {
  /// Sea / canvas behind the land fills.
  static const background = '#1f2025';

  /// Land, county, and town fills.
  static const fill = '#3F4045';

  /// County (city) borders.
  static const outline = '#a9b4bc';

  /// Township borders — a step lighter than [fill], still quieter than [outline].
  static const townOutline = '#6A6B72';
}

/// Id of the county-outline layer — overlays (radar) anchor below it so the
/// county borders stay legible on top.
const String outlineLayerId = 'county-outline';

/// Id of the faint township-outline layer (below the county borders).
const String townOutlineLayerId = 'town-outline';

/// Builds the ExpTech vector base-map style as a MapLibre style JSON string.
///
/// Defaults to [MapColors]. Optional overrides keep call sites / tests flexible.
/// The base draws no labels itself, but declares a `glyphs` endpoint (the
/// ExpTech map-assets CDN) so overlay layers can render `text-field` symbols.
/// Overlays (radar) anchor below [outlineLayerId] so the county borders stay
/// legible. Used by every map surface so they look identical.
String exptechVectorStyle({
  String background = MapColors.background,
  String fill = MapColors.fill,
  String outline = MapColors.outline,
  String townOutline = MapColors.townOutline,
}) {
  return '''
{
  "version": 8,
  "glyphs": "https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf",
  "sources": {
    "exptech": { "type": "vector", "tiles": ["https://lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf"], "maxzoom": 12 }
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$background" } },
    { "id": "land", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$fill" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$fill" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$fill" } },
    { "id": "$townOutlineLayerId", "type": "line", "source": "exptech", "source-layer": "town", "paint": { "line-color": "$townOutline", "line-width": 0.4, "line-opacity": 0.7 } },
    { "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 1.0 } }
  ]
}''';
}

/// Purple used to highlight the selected township (fill + border).
const String selectedColor = '#7C4DFF';
