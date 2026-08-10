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
    required this.label,
    required this.labelHalo,
  });

  /// Sea / canvas behind the land fills.
  final String background;

  /// Land, county, and town fills.
  final String fill;

  /// County (city) borders.
  final String outline;

  /// Township borders — quieter than [outline], close to [fill].
  final String townOutline;

  /// Township name text. Contrast against [fill]'s side of the map.
  final String label;

  /// Township name halo — the outline that lifts [label] off the fill.
  final String labelHalo;
}

/// Sole registry of base-map paint colours (light + dark).
abstract final class MapColors {
  /// Dark-mode cartography (default disaster-map look).
  static const dark = MapPalette(
    background: '#1f2025',
    fill: '#3F4045',
    outline: '#a9b4bc',
    townOutline: '#6A6B72',
    label: '#FFFFFF',
    labelHalo: '#000000',
  );

  /// Light-mode cartography — pale sea, mid-grey land.
  static const light = MapPalette(
    background: '#E0E0E0',
    fill: '#ADADAD',
    outline: '#6B6B6B',
    townOutline: '#9A9A9A',
    label: '#141414',
    labelHalo: '#FFFFFF',
  );

  /// Palette for the given UI [brightness].
  static MapPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Id of the base landmass fill layer — an overlay that should sit *under*
/// the whole Taiwan area (land/county/town fills), not wash over it, anchors
/// below this instead of [outlineLayerId].
const String landLayerId = 'land';

/// Id of the county-outline layer — overlays (radar) anchor below it so the
/// county borders stay legible on top.
const String outlineLayerId = 'county-outline';

/// Id of the faint township-outline layer (below the county borders).
const String townOutlineLayerId = 'town-outline';

/// Id of the township-name label layer. Invisible until [townLabelMinZoom]
/// when the 368-town mesh is dense enough that names can place without a pile-up.
const String townLabelLayerId = 'town-label';

/// Township labels start placing at this zoom; [townLabelFadeZoom] finishes the
/// fade-in. Below it the layer is not placed at all (a layer of near-invisible
/// symbols would still fight for placement space).
const double townLabelMinZoom = 8.5;

/// Zoom at which township labels reach full opacity (see [townLabelMinZoom]).
const double townLabelFadeZoom = 9.5;

/// Baked DPM source / layer ids — must match [DisasterMapLayer].
const String dpmAedSourceId = 'dpm-aed-src';
const String dpmAedPointsLayerId = 'dpm-aed-points';
const String dpmRestroomSourceId = 'dpm-restroom-src';
const String dpmRestroomPointsLayerId = 'dpm-restroom-points';
const String dpmShelterSourceId = 'dpm-shelter-src';
const String dpmShelterPointsLayerId = 'dpm-shelter-points';

/// Origin basemap XYZ (LB). Fetched by MapLibre, served from the app's tile
/// store through the Dart bridge, and warmed by `MapTileWarmer` — the same
/// three tiers as every other ExpTech tile.
const String basemapOriginTileUrl =
    'https://lb.exptech.dev/api/v1/map/tiles/{z}/{x}/{y}.pbf';

/// Origin glyph template — MapLibre HTTPS.
const String glyphsOriginUrl =
    'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf';

/// Builds the ExpTech vector base-map style as a MapLibre style JSON string.
///
/// Pass [MapColors.of] for the active brightness — never ad-hoc hexes. The base
/// declares a `glyphs` endpoint (the ExpTech map-assets CDN) so overlay layers
/// can render `text-field` symbols, and draws township names itself once the
/// map is zoomed in past [townLabelMinZoom] (the [TOWN] property of the `town`
/// source-layer). Overlays (radar) anchor below [outlineLayerId] so the county
/// borders stay legible.
///
/// [basemapTileUrl] / [glyphsUrl] are origin HTTPS templates fetched by
/// MapLibre and served from the app's tile store through the Dart bridge.
String exptechVectorStyle(
  MapPalette palette, {
  required String basemapTileUrl,
  required String glyphsUrl,
}) {
  final background = palette.background;
  final fill = palette.fill;
  final outline = palette.outline;
  final townOutline = palette.townOutline;
  final label = palette.label;
  final labelHalo = palette.labelHalo;
  return '''
{
  "version": 8,
  "glyphs": "$glyphsUrl",
  "sources": {
    "exptech": { "type": "vector", "tiles": ["$basemapTileUrl"], "maxzoom": 12 }
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$background" } },
    { "id": "$landLayerId", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$fill" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$fill" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$fill" } },
    { "id": "$townOutlineLayerId", "type": "line", "source": "exptech", "source-layer": "town", "paint": { "line-color": "$townOutline", "line-width": 0.4, "line-opacity": 0.7 } },
    { "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 1.0 } },
    { "id": "$townLabelLayerId", "type": "symbol", "source": "exptech", "source-layer": "town", "minzoom": $townLabelMinZoom, "layout": {
      "text-field": ["get", "TOWN"],
      "text-font": ["Noto Sans TC Regular"],
      "text-size": ["interpolate", ["linear"], ["zoom"], $townLabelMinZoom, 10, 12, 12.5],
      "text-allow-overlap": false,
      "text-ignore-placement": false,
      "text-padding": 2
    }, "paint": {
      "text-color": "$label",
      "text-halo-color": "$labelHalo",
      "text-halo-width": 1.2,
      "text-opacity": ["interpolate", ["linear"], ["zoom"], $townLabelMinZoom, 0, $townLabelFadeZoom, 1]
    } }
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
