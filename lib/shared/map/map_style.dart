/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (palette by brightness, no API key),
/// shared by the live map tab and the home backdrop so both look identical.
library;

import 'dart:convert';
import 'dart:ui' show Brightness;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_paths.dart';

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

/// Id of the base county-fill layer (`city` source-layer) — a runtime overlay
/// can recolour it to tint each county by a reading, and hide it while a
/// township-level tint takes over (the replay EEW area-intensity wash).
const String countyFillLayerId = 'county';

/// Id of the base township-fill layer (`town` source-layer) — recoloured the
/// same way, keyed per `CODE`, when an EEW wants the whole island tinted by
/// estimated shaking (legacy monitor behaviour).
const String townFillLayerId = 'town';

/// Id of the faint township-outline layer (below the county borders).
const String townOutlineLayerId = 'town-outline';

/// Id of the township-name label layer. Invisible until [townLabelMinZoom]
/// when the 368-town mesh is dense enough that names can place without a pile-up.
const String townLabelLayerId = 'town-label';

/// Id of the GeoJSON point source backing [townLabelLayerId] — one point per
/// township at its official centroid (see [townLabelGeoJson]).
const String townLabelSourceId = 'town-label-src';

/// Empty GeoJSON FeatureCollection — the [exptechVectorStyle] default when no
/// directory is supplied (tests), so the baked style always parses.
const String emptyTownLabelData = '{"type":"FeatureCollection","features":[]}';

/// Builds the township-name label data — a GeoJSON FeatureCollection with one
/// Point per township at the directory's official centroid.
///
/// Labels must NOT come from the vector tiles' `town` polygon layer: a township
/// polygon that crosses a tile boundary is clipped into several tile pieces,
/// each with its own centroid, so reading names off the polygons rendered the
/// same township name more than once after a zoom changed the tile grid. A
/// directory point is unique per township by construction, so exactly one label
/// ever places per name.
String townLabelGeoJson(TownDirectory directory) {
  final features = [
    for (final town in directory.all)
      '{"type":"Feature",'
          '"geometry":{"type":"Point","coordinates":[${town.lng},${town.lat}]},'
          '"properties":{"name":${jsonEncode(town.townName)}}}',
  ];
  return '{"type":"FeatureCollection","features":[${features.join(',')}]}';
}

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

/// Origin basemap XYZ (static LB CDN). Fetched by MapLibre, served from the
/// app's tile store through the Dart bridge, and warmed by `MapTileWarmer` —
/// the same three tiers as every other ExpTech tile.
const String basemapOriginTileUrl =
    'https://static.lb.exptech.dev${ApiPaths.mapTilesV1}{z}/{x}/{y}.pbf';

/// Origin terrain XYZ (static LB CDN) — the elevation mesh backing the
/// base map's hillshade relief.
///
/// The tiles are **Mapbox.com terrain-RGB PNGs**, which MapLibre's
/// `encoding: 'mapbox'` decodes natively — no app-side rewrite.
const String terrainOriginTileUrl =
    'https://static.lb.exptech.dev${ApiPaths.mapTerrainV1}{z}/{x}/{y}.png';

/// Origin glyph template — MapLibre HTTPS.
const String glyphsOriginUrl =
    'https://cdn.jsdelivr.net/gh/exptechtw/map-assets/{fontstack}/{range}.pbf';

/// Id of the raster-dem source backing [terrainHillshadeLayerId]. Also used by
/// [MapScaffold], which removes the source when the relief is switched off —
/// the id must match what the baked style declares.
const String terrainSourceId = 'terrain';

/// Terrain tiles start loading at this zoom.
///
/// Below it the relief is not worth its cost: a 512px DEM tile shrinks to a
/// few dozen screen pixels at whole-island zoom (where the home backdrop
/// sits), and the download/decode/memory bill is the same as at full zoom.
/// The hillshade's lit-edge detail only starts reading at about z7, so z6
/// keeps everything the eye can see and drops the rest.
const double terrainMinZoom = 6;

/// Hillshade lighting shared by the baked style and the runtime layer
/// [MapScaffold] adds back — one source of truth, so both can't drift.
const double terrainIlluminationDirection = 335;
const double terrainExaggeration = 0.3;

/// Id of the hillshade layer the base style bakes when [terrainTileUrl] is
/// given — [MapScaffold] adds/removes it for the "terrain relief" switch, so
/// the id must be stable across style reloads.
const String terrainHillshadeLayerId = 'terrain-hillshade';

/// Builds the ExpTech vector base-map style as a MapLibre style JSON string.
///
/// Pass [MapColors.of] for the active brightness — never ad-hoc hexes. The base
/// declares a `glyphs` endpoint (the ExpTech map-assets CDN) so overlay layers
/// can render `text-field` symbols, and draws township names itself once the
/// map is zoomed in past [townLabelMinZoom]. The names are placed from
/// [townLabelData] — a GeoJSON point per township (see [townLabelGeoJson]) —
/// **not** from the `town` source-layer's polygons: a polygon clipped across a
/// tile boundary yields a centroid per tile piece, so the same name rendered
/// twice after a zoom. A directory point is unique per township. Overlays
/// (radar) anchor below [outlineLayerId] so the county borders stay legible.
///
/// [basemapTileUrl] / [glyphsUrl] are origin HTTPS templates fetched by
/// MapLibre and served from the app's tile store through the Dart bridge. When
/// [terrainTileUrl] is given, a `raster-dem` source (`encoding: 'mapbox'` — the
/// tiles are natively Mapbox terrain-RGB) and a translucent hillshade layer sit
/// between the land fills and the borders, giving the base map a shaded-relief
/// depth. The `bounds` deliberately overshoot the DEM's own bbox (≈120–122°E,
/// 21.9–25.3°N): a hillshade edge on a plain background reads as a line, and
/// pushing the boundary past anywhere the user can pan hides it.
String exptechVectorStyle(
  MapPalette palette, {
  required String basemapTileUrl,
  required String glyphsUrl,
  String? terrainTileUrl,
  String townLabelData = emptyTownLabelData,
}) {
  final background = palette.background;
  final fill = palette.fill;
  final outline = palette.outline;
  final townOutline = palette.townOutline;
  final label = palette.label;
  final labelHalo = palette.labelHalo;
  final terrain = terrainTileUrl == null
      ? ''
      : '''
  ,"$terrainSourceId": { "type": "raster-dem", "tiles": ["$terrainTileUrl"], "encoding": "mapbox", "tileSize": 512, "minzoom": $terrainMinZoom, "maxzoom": 12, "bounds": [110, 10, 132, 35] }''';
  final hillshade = terrainTileUrl == null
      ? ''
      : '''
  ,{ "id": "$terrainHillshadeLayerId", "type": "hillshade", "source": "$terrainSourceId", "paint": {
      "hillshade-illumination-direction": $terrainIlluminationDirection,
      "hillshade-exaggeration": $terrainExaggeration
    } }''';
  return '''
{
  "version": 8,
  "glyphs": "$glyphsUrl",
  "sources": {
    "exptech": { "type": "vector", "tiles": ["$basemapTileUrl"], "maxzoom": 12 },
    "$townLabelSourceId": { "type": "geojson", "data": $townLabelData }$terrain
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "$background" } },
    { "id": "$landLayerId", "type": "fill", "source": "exptech", "source-layer": "global", "paint": { "fill-color": "$fill" } },
    { "id": "county", "type": "fill", "source": "exptech", "source-layer": "city", "paint": { "fill-color": "$fill" } },
    { "id": "town", "type": "fill", "source": "exptech", "source-layer": "town", "paint": { "fill-color": "$fill" } }$hillshade,
    { "id": "$townOutlineLayerId", "type": "line", "source": "exptech", "source-layer": "town", "paint": { "line-color": "$townOutline", "line-width": 0.4, "line-opacity": 0.7 } },
    { "id": "$outlineLayerId", "type": "line", "source": "exptech", "source-layer": "city", "paint": { "line-color": "$outline", "line-width": 1.0 } },
    { "id": "$townLabelLayerId", "type": "symbol", "source": "$townLabelSourceId", "minzoom": $townLabelMinZoom, "layout": {
      "text-field": ["get", "name"],
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

/// Bright yellow country / county borders drawn **over** satellite imagery.
///
/// The hue that stays legible on true-colour satellite (which is overall
/// dark); tune it per channel if another imagery needs it. [AdminBoundary]
/// overlays keep their own white core — only satellite is yellow.
const String satelliteOutlineColor = '#FFD400';

/// Satellite township borders — dark yellow ([satelliteOutlineColor]'s
/// secondary), the fine mesh beneath the county/country frame.
const String satelliteTownOutlineColor = '#B79A00';

/// Runtime line layer: world land / country edges (`global` source-layer).
const String satelliteGlobalOutlineLayerId = 'satellite-global-outline';

/// Runtime line layer: Taiwan county edges (`city` source-layer).
const String satelliteCountyOutlineLayerId = 'satellite-county-outline';

/// Runtime line layer: Taiwan township edges (`town` source-layer).
const String satelliteTownOutlineLayerId = 'satellite-town-outline';
