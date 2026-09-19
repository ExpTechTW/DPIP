/// The 強震監視器 map stack, defined once: the layer ids, the paint
/// expressions, and — the part that actually bites — the order the layers are
/// mounted in.
///
/// Two surfaces draw this stack: the map tab's live monitor (`RtsMapLayer`,
/// `features/map`) and the report replay map (`ReportReplayPage`,
/// `features/earthquake`). Features must not import each other's internals
/// (see ARCHITECTURE.md), so the replay map used to carry a hand-copied port
/// of the monitor's rendering. The copies drifted exactly where drift is
/// invisible: a stacking change made on one surface simply did not happen on
/// the other, and nothing failed — the map just looked wrong on one page.
///
/// So the ids, the expressions and [addMonitorLayers] live here, and both
/// surfaces call the same function. What stays with each caller is the part
/// that genuinely differs: where the station readings come from, and how each
/// page drives its own timers. Only the *shape* of the stack is shared.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/map/map_style.dart' show landLayerId;
import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Every source, layer and image id one monitor stack occupies, derived from a
/// [prefix] so two surfaces can mount the stack without colliding.
///
/// The ids are spelled out rather than generated ad-hoc because tests pin the
/// monitor's (`rts-circle`, `rts-box-line`, `rts-eew-epicenter`, …) and a
/// renamed layer is a silently dead `setLayerVisibility`, not a crash.
class MonitorLayerIds {
  const MonitorLayerIds(this.prefix);

  /// Namespace for this surface's copy of the stack — `rts` for the live
  /// monitor, `replay` for the report replay map.
  final String prefix;

  /// GeoJSON source holding one point per reporting station.
  String get stationSource => '$prefix-src';

  /// The station dot, coloured by the continuous instrumental ramp.
  String get stationDot => '$prefix-circle';

  /// Station id over its raw reading, pinned under the dot.
  String get stationLabel => '$prefix-label';

  /// Per-station discrete-reading badge — a circular version of the legacy
  /// monitor's square `intensity` layer (see [IntensityCircleRenderer]): while
  /// a large event's detection boxes are up, each shaking station gets a
  /// numbered badge over its dot instead of the plain colour, but the shape
  /// stays a circle — this is still live instrumental data, never the
  /// report/rapid-report square. `icon` is empty for a station with nothing to
  /// badge, so the plain dot underneath just keeps showing through.
  String get stationBadge => '$prefix-intensity-circle';

  /// GeoJSON source for a large event's detection-box grid.
  String get boxSource => '$prefix-box-src';

  /// Detection-box borders (no fill, so the map stays readable under them).
  String get boxLine => '$prefix-box-line';

  /// GeoJSON source for the EEW overlay — wave fronts plus epicentre.
  String get eewSource => '$prefix-eew-src';

  /// P wave-front ring: a heads-up leading edge, outline only.
  String get eewPWave => '$prefix-eew-p';

  /// S wave-front ring.
  String get eewSWave => '$prefix-eew-s';

  /// The S wave's translucent disc — the already-shaking zone.
  String get eewSWaveFill => '$prefix-eew-s-fill';

  /// The epicentre cross.
  String get eewEpicenter => '$prefix-eew-epicenter';

  /// Registered image id for the epicentre cross artwork.
  String get eewCrossIcon => '$prefix-eew-cross';

  /// Every layer, topmost first — the order [removeMonitorLayers] tears down
  /// and the reverse of the order [addMonitorLayers] mounts.
  List<String> get layers => [
    eewEpicenter,
    eewSWave,
    eewPWave,
    eewSWaveFill,
    boxLine,
    stationBadge,
    stationLabel,
    stationDot,
  ];

  /// Every source this stack owns.
  List<String> get sources => [stationSource, eewSource, boxSource];
}

/// The map tab's live 強震監視器.
const MonitorLayerIds rtsMonitorIds = MonitorLayerIds('rts');

/// The report replay map's own copy of the stack.
const MonitorLayerIds replayMonitorIds = MonitorLayerIds('replay');

/// An empty FeatureCollection — what every source is seeded with.
const Map<String, dynamic> monitorEmptyCollection = {
  'type': 'FeatureCollection',
  'features': <dynamic>[],
};

/// Dots scale with zoom so they stay legible zoomed in (legacy: 2px at z4 →
/// 8px at z12).
const List<Object> monitorDotRadius = [
  'interpolate',
  ['linear'],
  ['zoom'],
  4,
  2.0,
  12,
  8.0,
];

/// The discrete-reading badge's on-map scale of its 64px artwork. The legacy
/// monitor's own badge layer used 0.2 at z5 → 0.8 at z10, but that assumed
/// native-resolution PNG assets — applied to a baked canvas here it renders at
/// only device-pixel size, ~13px on a 3x display and effectively invisible.
/// `ReportDetailPage` already solved this for the same 64px canvas class (see
/// [IntensityIconRenderer]); this is its scale.
const List<Object> monitorBadgeIconSize = [
  'interpolate',
  ['linear'],
  ['zoom'],
  5,
  0.75,
  15,
  1.7,
];

/// Higher effective intensity draws on top (dot, badge and label all key off
/// this) — reads `sort`, the alert-aware value the badge is actually drawn
/// from, not the raw `i`. Stations without a `sort` sink.
const List<Object> monitorSortKey = [
  'coalesce',
  ['get', 'sort'],
  -5,
];

/// Labels place strongest-first: a symbol's *lower* sort key wins a collision,
/// so negate the intensity — a hot station's reading never loses to a calm one.
const List<Object> monitorLabelSortKey = [
  '-',
  0,
  [
    'coalesce',
    ['get', 'sort'],
    -5,
  ],
];

/// Box-grid border colour by intensity `i`: red ≥4, yellow 2–3, green below —
/// ported from the legacy monitor's box colour scheme.
const List<Object> monitorBoxColor = [
  'case',
  [
    '>=',
    ['get', 'i'],
    4,
  ],
  '#FF0000',
  [
    '>=',
    ['get', 'i'],
    2,
  ],
  '#EAC100',
  '#00DB00',
];

/// A neutral hairline separating overlapping dots — legacy uses the theme's
/// outlineVariant, but the render path has no `BuildContext`, so a mid-grey
/// that reads on both light and dark tiles stands in.
///
/// A getter, not a `const`: the colour-vision transform runs at the definition
/// and isn't a compile-time constant. (It is the identity on a pure grey —
/// routing it anyway keeps the rule uniform for whoever tints this later.)
String get monitorDotStroke => '#9E9E9E'.vision;

/// The circular badge icon id for scale index 1–9, dark or light artwork.
String monitorBadgeIcon(int level, {required bool dark}) =>
    dark ? 'circle-$level-dark' : 'circle-$level';

/// The full station-dot style at [opacity] — passed whole (not a partial
/// update), since `setLayerProperties` resets any property left null.
///
/// Colour comes from the shared instrumental-intensity palette, so the dots
/// and the legend can never drift — except a `grey`-flagged feature, which
/// paints the discrete scale's own 0-grey instead: a station on a large
/// event's alert list reading a flat 0 stays visibly part of the network
/// rather than fading into whatever pale colour the continuous ramp gives a
/// near-zero reading (ported from the legacy monitor's separate `intensity0`
/// grey layer).
CircleLayerProperties monitorDotProps({double opacity = 1}) =>
    CircleLayerProperties(
      circleColor: <Object>[
        'case',
        [
          '==',
          ['get', 'grey'],
          1,
        ],
        IntensityColors.discrete(0).toHexRgb(),
        InstrumentalIntensityColors.mapLibreInterpolate,
      ],
      circleRadius: monitorDotRadius,
      circleStrokeColor: monitorDotStroke,
      circleStrokeWidth: 1,
      circleOpacity: opacity,
      // Stronger stations sort above weaker ones so a hot dot is never hidden.
      circleSortKey: monitorSortKey,
    );

/// The full station-label style at [opacity] — station id over its raw
/// reading. Passed whole (`setLayerProperties` nulls anything omitted); the
/// sort key places the strongest stations first so a hot reading never loses.
SymbolLayerProperties monitorLabelProps({double opacity = 1}) =>
    stationLabelProps(
      textField: const <Object>['get', 'label'],
      textSize: 10,
      opacity: opacity,
      sortKey: monitorLabelSortKey,
    );

/// Mounts the whole stack on [controller], in the one order both surfaces use.
///
/// **The order is the contract.** Everything here is *appended* (no
/// `belowLayerId`), so the stack sits over the base style's township names
/// rather than under them: on this overlay the live readings are the content
/// and the names are the backdrop. Exactly one layer stays anchored — the EEW
/// S-wave disc, below [landLayerId], so its wash covers open sea only and
/// never Taiwan itself. The estimated-shaking wash is not mounted here at all:
/// it *is* the base style's `town` fill, recoloured in place, so it too stays
/// under the names. Township names therefore end up second from the bottom —
/// above the wash, below every reading.
///
/// Appending means insertion order alone decides the stacking (each call goes
/// to the very top, so the later one wins), and the resulting bottom-to-top
/// order is: dots → station labels → discrete badges → detection boxes → wave
/// fronts → epicentre cross. That matches the legacy monitor, and the
/// epicentre must stay last: it is the one mark that may never be buried.
///
/// MapLibre places symbols from the top layer down, so with the labels above
/// the township names it is the station labels that win a collision — which is
/// the point: a live reading must not be dropped to keep a place name. The
/// badge and cross layers set `iconIgnorePlacement`, so they never take part
/// in placement and never suppress a name.
///
/// [stationData] seeds the station source — live GeoJSON where the caller
/// already has a frame, [monitorEmptyCollection] otherwise. The box grid and
/// the EEW overlay are each isolated in their own try/catch, so a failure in
/// one can never take down the station dots; [logTag] names the surface in
/// whatever is logged.
Future<void> addMonitorLayers(
  MapLibreMapController controller,
  MonitorLayerIds ids, {
  Map<String, dynamic> stationData = monitorEmptyCollection,
  double dotOpacity = 1,
  required String logTag,
}) async {
  await controller.addSource(
    ids.stationSource,
    GeojsonSourceProperties(data: stationData),
  );
  await controller.addCircleLayer(
    ids.stationSource,
    ids.stationDot,
    monitorDotProps(opacity: dotOpacity),
  );
  await controller.addSymbolLayer(
    ids.stationSource,
    ids.stationLabel,
    monitorLabelProps(opacity: dotOpacity),
    minzoom: 10,
  );
  // The 18 circular discrete-reading badges (1–9 light + dark), drawn in code
  // and registered before the layer that names them.
  final badges = await IntensityCircleRenderer.renderAll();
  for (final entry in badges.entries) {
    await controller.addImage(entry.key, entry.value);
  }
  // Always on top of the plain dot (added after it); `icon` is empty for most
  // stations most of the time, so this is a no-op render for them.
  await controller.addSymbolLayer(
    ids.stationSource,
    ids.stationBadge,
    const SymbolLayerProperties(
      iconImage: <Object>['get', 'icon'],
      iconSize: monitorBadgeIconSize,
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      // Same "stronger wins" rule as the dot layer's circleSortKey — two
      // badges can overlap just like two dots can, and a low reading must
      // never paint over a high one. (`symbol-z-order` defaults to `auto`,
      // which honours the sort key; naming it `source` here would silently
      // drop back to feed-iteration order.)
      symbolSortKey: monitorSortKey,
    ),
  );
  try {
    await controller.addSource(
      ids.boxSource,
      GeojsonSourceProperties(data: monitorEmptyCollection),
    );
    await controller.addLineLayer(
      ids.boxSource,
      ids.boxLine,
      const LineLayerProperties(
        lineColor: monitorBoxColor,
        lineWidth: 2,
        visibility: 'none',
        // Red always draws over yellow/green — ported from the legacy
        // monitor's box layer (`lineSortKey: [Expressions.get, 'i']`).
        // Without this, overlapping boxes stack in whatever order the feed
        // happened to list them, so a low-intensity box could paint over a
        // red one.
        lineSortKey: <Object>['get', 'i'],
      ),
    );
  } catch (e, st) {
    Log.handle(e, st, '$logTag box layer render failed');
  }
  try {
    // The cross artwork is drawn in code, like every other map icon — the
    // legacy PNG `assets/map/icons/cross.png` does not exist and must not be
    // loaded.
    await controller.addImage(
      ids.eewCrossIcon,
      await IntensityIconRenderer.render('cross'),
    );
    await controller.addSource(
      ids.eewSource,
      GeojsonSourceProperties(data: monitorEmptyCollection),
    );
    await controller.addFillLayer(
      ids.eewSource,
      ids.eewSWaveFill,
      // Vector geometry we draw ourselves, so it recolours with the app.
      FillLayerProperties(fillColor: '#FF3B30'.vision, fillOpacity: 0.16),
      // The one anchored layer in the stack: below the whole land/county/town
      // area, not just its borders, so the wash shows over open sea only.
      belowLayerId: landLayerId,
      filter: const [
        '==',
        ['get', 'type'],
        's-fill',
      ],
    );
    await controller.addLineLayer(
      ids.eewSource,
      ids.eewPWave,
      LineLayerProperties(lineColor: '#00E5FF'.vision, lineWidth: 2),
      filter: const [
        '==',
        ['get', 'type'],
        'p-line',
      ],
    );
    await controller.addLineLayer(
      ids.eewSource,
      ids.eewSWave,
      LineLayerProperties(lineColor: '#FF3B30'.vision, lineWidth: 2),
      filter: const [
        '==',
        ['get', 'type'],
        's-line',
      ],
    );
    await controller.addSymbolLayer(
      ids.eewSource,
      ids.eewEpicenter,
      SymbolLayerProperties(
        iconImage: ids.eewCrossIcon,
        iconSize: 1.0,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      filter: const [
        '==',
        ['get', 'type'],
        'x',
      ],
    );
  } catch (e, st) {
    Log.handle(e, st, '$logTag EEW layer render failed');
  }
}

/// Takes the stack back off [controller] — layers before their sources,
/// tolerating anything not currently mounted (a style reload wipes runtime
/// layers, so a caller re-rendering after one finds most of this already gone).
Future<void> removeMonitorLayers(
  MapLibreMapController controller,
  MonitorLayerIds ids,
) async {
  for (final layerId in ids.layers) {
    try {
      await controller.removeLayer(layerId);
    } catch (_) {
      // Expected when the layer isn't on the map yet.
    }
  }
  for (final sourceId in ids.sources) {
    try {
      await controller.removeSource(sourceId);
    } catch (_) {
      // Expected when the source isn't on the map yet.
    }
  }
}
