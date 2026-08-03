/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (palette by brightness, no API key),
/// shared by the live map tab and the home backdrop so both look identical.
library;

import 'dart:ui' show Brightness;

/// One brightness's cartographic hex colours — MapLibre paint strings only.
///
/// Do not invent map hexes at call sites; resolve via [MapColors.of].
final class MapPalette {
  const MapPalette({
    required this.background,
    required this.fill,
    required this.outline,
    required this.townOutline,
  });

  /// Sea / canvas behind the land fills.
  final String background;

  /// Land, county, and town fills.
  final String fill;

  /// County (city) borders.
  final String outline;

  /// Township borders — quieter than [outline], close to [fill].
  final String townOutline;
}

/// Sole registry of base-map paint colours (light + dark).
abstract final class MapColors {
  /// Dark-mode cartography (default disaster-map look).
  static const dark = MapPalette(
    background: '#1f2025',
    fill: '#3F4045',
    outline: '#a9b4bc',
    townOutline: '#6A6B72',
  );

  /// Light-mode cartography — pale sea, mid-grey land.
  static const light = MapPalette(
    background: '#E0E0E0',
    fill: '#ADADAD',
    outline: '#6B6B6B',
    townOutline: '#9A9A9A',
  );

  /// Palette for the given UI [brightness].
  static MapPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Id of the county-outline layer — overlays (radar) anchor below it so the
/// county borders stay legible on top.
const String outlineLayerId = 'county-outline';

/// Id of the faint township-outline layer (below the county borders).
const String townOutlineLayerId = 'town-outline';

/// Baked DPM AED source / layer ids — must match [DisasterMapLayer].
const String dpmAedSourceId = 'dpm-aed-src';
const String dpmAedClustersLayerId = 'dpm-aed-clusters';
const String dpmAedClusterCountLayerId = 'dpm-aed-cluster-count';
const String dpmAedPointsLayerId = 'dpm-aed-points';

/// Origin basemap XYZ (LB) — MapLibre HTTPS (own ambient). Ambient pin via
/// [AmbientPrefetcher] is disabled (iOS preload race).
const String basemapOriginTileUrl =
    'https://lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf';

/// Origin glyph template — MapLibre HTTPS.
const String glyphsOriginUrl =
    'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf';

/// Builds the ExpTech vector base-map style as a MapLibre style JSON string.
///
/// Pass [MapColors.of] for the active brightness — never ad-hoc hexes. The base
/// draws no labels itself, but declares a `glyphs` endpoint (the ExpTech
/// map-assets CDN) so overlay layers can render `text-field` symbols. Overlays
/// (radar) anchor below [outlineLayerId] so the county borders stay legible.
///
/// [basemapTileUrl] / [glyphsUrl] / [aedTileUrl] are origin HTTPS templates
/// (MapLibre fetches them into its own ambient cache).
///
/// When [aedTileUrl] is set (XYZ MVT template), AED vector tiles are baked into
/// the style document — same path as the ExpTech basemap source. Runtime
/// `addSource(VectorSource…)` is avoided; it has been unreliable for this feed.
String exptechVectorStyle(
  MapPalette palette, {
  required String basemapTileUrl,
  required String glyphsUrl,
  String? aedTileUrl,
}) {
  final background = palette.background;
  final fill = palette.fill;
  final outline = palette.outline;
  final townOutline = palette.townOutline;
  final aedSource = aedTileUrl == null
      ? ''
      : '''
    , "$dpmAedSourceId": {
      "type": "vector",
      "tiles": ["$aedTileUrl"],
      "minzoom": 0,
      "maxzoom": 16
    }''';
  // AED layers sit *above* county outlines so markers stay readable.
  final aedLayers = aedTileUrl == null
      ? ''
      : '''
    , {
      "id": "$dpmAedClustersLayerId",
      "type": "circle",
      "source": "$dpmAedSourceId",
      "source-layer": "aed",
      "filter": ["has", "point_count"],
      "paint": {
        "circle-color": "#c0392b",
        "circle-opacity": 0.75,
        "circle-radius": ["step", ["get", "point_count"], 12, 10, 16, 50, 22, 200, 28]
      }
    }
    , {
      "id": "$dpmAedClusterCountLayerId",
      "type": "symbol",
      "source": "$dpmAedSourceId",
      "source-layer": "aed",
      "filter": ["has", "point_count"],
      "layout": {
        "text-field": ["to-string", ["get", "point_count"]],
        "text-size": 11,
        "text-allow-overlap": true
      },
      "paint": { "text-color": "#ffffff" }
    }
    , {
      "id": "$dpmAedPointsLayerId",
      "type": "circle",
      "source": "$dpmAedSourceId",
      "source-layer": "aed",
      "filter": ["!", ["has", "point_count"]],
      "paint": {
        "circle-color": "#e74c3c",
        "circle-radius": 5,
        "circle-stroke-width": 1.5,
        "circle-stroke-color": "#ffffff"
      }
    }''';
  return '''
{
  "version": 8,
  "glyphs": "$glyphsUrl",
  "sources": {
    "exptech": { "type": "vector", "tiles": ["$basemapTileUrl"], "maxzoom": 12 }$aedSource
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$background" } },
    { "id": "land", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$fill" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$fill" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$fill" } },
    { "id": "$townOutlineLayerId", "type": "line", "source": "exptech", "source-layer": "town", "paint": { "line-color": "$townOutline", "line-width": 0.4, "line-opacity": 0.7 } },
    { "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 1.0 } }$aedLayers
  ]
}''';
}

/// Purple used to highlight the selected township (fill + border).
const String selectedColor = '#7C4DFF';

/// Borders drawn on top of IR satellite imagery — black so they stay readable
/// on greyscale Himawari tiles (themed [MapPalette.outline] does not).
const String satelliteOutlineColor = '#000000';

/// Runtime line layer: world land / country edges (`global` source-layer).
const String satelliteGlobalOutlineLayerId = 'satellite-global-outline';

/// Runtime line layer: Taiwan county edges (`city` source-layer).
const String satelliteCountyOutlineLayerId = 'satellite-county-outline';
