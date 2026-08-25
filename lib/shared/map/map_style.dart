/// MapLibre style definitions for the app's base map.
///
/// The base is the ExpTech vector map (palette by brightness, no API key),
/// shared by the live map tab and the home backdrop so both look identical.
library;

import 'dart:convert';
import 'dart:ui' show Brightness;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/shared/map/town_label_points.g.dart';
import 'package:dpip/core/network/api_paths.dart';

/// One brightness's cartographic hex colours — MapLibre paint strings only.
///
/// Do not invent map hexes at call sites; resolve via [MapColors.of].
///
/// A **value** type, deliberately: the palettes are no longer compile-time
/// constants (their colours run through `.vision` at their definition, so they
/// follow the colour-vision setting), which means every read builds a fresh
/// instance. `BaseMap` memoises the interpolated style JSON on the palette, and
/// with identity equality that cache would miss on every build and grow without
/// bound. Equal colours are the same palette; a vision change makes a different
/// one, and the style is rebuilt exactly once for it.
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPalette &&
          other.background == background &&
          other.fill == fill &&
          other.outline == outline &&
          other.townOutline == townOutline &&
          other.label == label &&
          other.labelHalo == labelHalo;

  @override
  int get hashCode =>
      Object.hash(background, fill, outline, townOutline, label, labelHalo);
}

/// Sole registry of base-map paint colours (light + dark).
///
/// Every hex below is the *standard-vision* value, routed through `.vision` at
/// its definition so the whole cartography is recoloured with the rest of the
/// app when a colour-vision correction is on. This is the only place the base
/// map's colours are declared, so it is the only place the transform belongs —
/// never in `colorFromHexRgb`/`toHexRgb`, which would double any colour that
/// round-trips between the map and a legend. The transform is not a
/// compile-time constant, so these are getters rather than `static const`;
/// [MapPalette] carries value equality so the style cache still hits.
abstract final class MapColors {
  /// Dark-mode cartography (default disaster-map look).
  static MapPalette get dark => MapPalette(
    background: '#1f2025'.vision,
    fill: '#3F4045'.vision,
    outline: '#a9b4bc'.vision,
    townOutline: '#6A6B72'.vision,
    label: '#FFFFFF'.vision,
    labelHalo: '#000000'.vision,
  );

  /// Light-mode cartography — pale sea, mid-grey land.
  static MapPalette get light => MapPalette(
    background: '#E0E0E0'.vision,
    fill: '#ADADAD'.vision,
    outline: '#6B6B6B'.vision,
    townOutline: '#9A9A9A'.vision,
    label: '#141414'.vision,
    labelHalo: '#FFFFFF'.vision,
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
/// township, in the middle of it (see [townLabelGeoJson]).
const String townLabelSourceId = 'town-label-src';

/// Empty GeoJSON FeatureCollection — the [exptechVectorStyle] default when no
/// directory is supplied (tests), so the baked style always parses.
const String emptyTownLabelData = '{"type":"FeatureCollection","features":[]}';

/// The last collection built, keyed by the directory it was built from.
///
/// Every `BaseMap.build` asks for this, and the answer is a ~41 KB string over
/// 368 features that only changes when the directory instance does — which is
/// once, at bootstrap. Rebuilding it per build is pure garbage.
TownDirectory? _labelCacheKey;
String? _labelCacheValue;

/// Builds the township-name label data — a GeoJSON FeatureCollection with one
/// Point per township, placed at the point inside it furthest from any edge.
///
/// Labels must NOT come from the vector tiles' `town` polygon layer: a township
/// polygon that crosses a tile boundary is clipped into several tile pieces,
/// each with its own centroid, so reading names off the polygons rendered the
/// same township name more than once after a zoom changed the tile grid. A
/// point per township is unique by construction, so exactly one label ever
/// places per name.
///
/// The position comes from [townLabelPoints], not from [TownDirectory]'s
/// `lat`/`lng`. The directory point is the administrative seat, so a label drawn
/// there sits whereever the district office happens to be — for a mountain
/// township, in the inhabited valley at one corner of a shape that runs tens of
/// kilometres into the range (臺中市和平區's was 42 km from the middle). The
/// directory point is deliberately left alone because `TownDirectory.nearest`
/// still needs it: that is the GPS→township fallback used at sea and in
/// boundary gaps, where the nearest *settlement* is the right answer and the
/// geometric middle is not.
///
/// A township with no baked point falls back to the directory — a label
/// slightly off is better than a name missing from the map.
String townLabelGeoJson(TownDirectory directory) {
  if (identical(_labelCacheKey, directory)) return _labelCacheValue!;
  final features = [
    for (final town in directory.all)
      if (townLabelPoints[town.code] case final point?)
        '{"type":"Feature",'
            '"geometry":{"type":"Point","coordinates":[${point.$2},${point.$1}]},'
            '"properties":{"name":${jsonEncode(town.townName)}}}'
      else
        '{"type":"Feature",'
            '"geometry":{"type":"Point","coordinates":[${town.lng},${town.lat}]},'
            '"properties":{"name":${jsonEncode(town.townName)}}}',
  ];
  final json =
      '{"type":"FeatureCollection","features":[${features.join(',')}]}';
  _labelCacheKey = directory;
  _labelCacheValue = json;
  return json;
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
  ,"$terrainSourceId": { "type": "raster-dem", "tiles": ["$terrainTileUrl"], "encoding": "mapbox", "tileSize": 512, "minzoom": 0, "maxzoom": 20, "bounds": [110, 10, 132, 35] }''';
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
///
/// A getter, not a `const`: `.vision` runs at the definition, so the highlight
/// is recoloured with the rest of the map.
String get selectedColor => '#7C4DFF'.vision;

/// Bright yellow country / county borders drawn **over** satellite imagery.
///
/// The hue that stays legible on true-colour satellite (which is overall
/// dark); tune it per channel if another imagery needs it. [AdminBoundary]
/// overlays keep their own white core — only satellite is yellow.
///
/// Transformed, unlike the imagery underneath it: this is a vector line the app
/// draws itself, not a description of the satellite pixels, so correcting it
/// costs nothing and keeps it distinct from the other borders on the map.
String get satelliteOutlineColor => '#FFD400'.vision;

/// Satellite township borders — dark yellow ([satelliteOutlineColor]'s
/// secondary), the fine mesh beneath the county/country frame.
String get satelliteTownOutlineColor => '#B79A00'.vision;

/// Runtime line layer: world land / country edges (`global` source-layer).
const String satelliteGlobalOutlineLayerId = 'satellite-global-outline';

/// Runtime line layer: Taiwan county edges (`city` source-layer).
const String satelliteCountyOutlineLayerId = 'satellite-county-outline';

/// Runtime line layer: Taiwan township edges (`town` source-layer).
const String satelliteTownOutlineLayerId = 'satellite-town-outline';
