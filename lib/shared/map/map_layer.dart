import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// One time-stamped frame of a [MapLayer] — the unit the timeline scrubs.
///
/// [id] is opaque to the scaffold (a layer decodes it into tiles/data); [time]
/// is what the timeline labels and orders by.
@immutable
class MapFrame {
  const MapFrame({required this.id, required this.time});

  /// The layer's raw frame identifier (e.g. a radar timestamp).
  final String id;

  /// When this frame is for — drives the timeline label and ordering.
  final DateTime time;

  @override
  bool operator ==(Object other) =>
      other is MapFrame && other.id == id && other.time == time;

  @override
  int get hashCode => Object.hash(id, time);
}

/// Index of the newest frame that is not in the future, or 0 when the list is
/// empty or entirely forecast.
///
/// Observed data only ever reaches the present, so for radar or satellite this
/// is the last frame and saying "the last one" would have done. A forecast runs
/// past it — GFS by sixteen days — and there the two answers are nothing alike:
/// treating the last frame as now opens the map on next week, labels it 現在,
/// and leaves the scrubber pinned at the right-hand end with the entire
/// forecast behind it and nothing ahead. The forecast is not missing at that
/// point, it is just all to the left of a scrubber that claims to be at the
/// present.
///
/// So: ask the clock, not the list. The present is the newest frame **at or
/// before** now — never a future step. At 21:43 with 3-hourly ECMWF steps
/// landing on 20:00 and 23:00, the present is 20:00; labelling the 23:00
/// forecast as now would present a prediction as though it had already
/// happened. For observations the answer is unchanged.
int nowFrameIndex(List<MapFrame> frames, {DateTime? now}) {
  if (frames.isEmpty) return 0;
  // The frame times are server timestamps, so the default clock must be the
  // calibrated one, not the device wall clock — a device clock that drifted
  // (or a timezone the device changed) would pick the wrong "now" frame.
  final at = now ?? AppTime.utc;
  // Frames are chronological, so scan from the newest backwards.
  for (var i = frames.length - 1; i >= 0; i--) {
    if (!frames[i].time.isAfter(at)) return i;
  }
  // Everything is in the future — the forecast opens on its first step.
  return 0;
}

/// A pluggable overlay on the shared map — radar today, rain / lightning /
/// typhoon / … as they land.
///
/// `MapScaffold` owns the map, the timeline, and the layer switcher; a layer
/// only supplies its identity (for the switcher), its available [frames] (for
/// the timeline), and how to [render] / [clear] a frame on the MapLibre
/// controller. Implement one per data type in a feature's `presentation/layers/`
/// so the map surface stays free of MapLibre-id bookkeeping.
///
/// A layer instance is bound to a single map and keeps its own MapLibre state.
/// The scaffold [prepare]s the whole frame set once (so tiles prefetch in the
/// background) and then [show]s individual frames — [show] must be cheap enough
/// to drive live timeline scrubbing, so the map animates like a loop instead of
/// stalling on a per-frame fetch.
abstract interface class MapLayer {
  /// Stable id; also namespaces this layer's MapLibre source/layer ids.
  String get id;

  /// The switcher label (localised by the implementation via [context]).
  String label(BuildContext context);

  /// Secondary switcher line under [label] — formula, band composition, or
  /// anything that differentiates the layer at a glance. `null` hides it.
  String? subtitle(BuildContext context);

  /// The switcher icon — outlined, per the app's icon convention.
  IconData get icon;

  /// Whether this layer is scrubbed with the bottom **timeline** (radar), or
  /// driven by a tap-to-open **sheet** ([buildSheet]) instead (station values,
  /// typhoon). Timeline layers use [frames]/[prepare]/[show]; sheet layers draw
  /// their static overlay in [render] and react to taps in [onMapTap].
  bool get usesTimeline;

  /// How much of the map's height this layer's **resting** chrome covers at the
  /// bottom, as a fraction (0–1) — a collapsed sheet's peek, a status strip.
  ///
  /// The map fills the screen and every layer's chrome is layered *over* it, so
  /// the band the user can actually see is shorter than the map. The scaffold
  /// subtracts this when framing, which is why switching layers re-frames: each
  /// layer hides a different amount. Report only the resting height — a sheet the
  /// user drags open is their own doing and must not move the camera.
  ///
  /// Timeline layers return 0: the scaffold owns the timeline widget and measures
  /// its real height instead of taking a declared number.
  double get bottomChromeFraction;

  /// Per-surface MapLibre zoom floor. Default matches [BaseMap.defaultMinZoom]
  /// (radar tiles); typhoon may go lower so the whole basin fits.
  double get mapMinZoom;

  /// Per-surface MapLibre zoom ceiling. Default matches [BaseMap.maxZoom].
  /// Disaster-prevention MVT goes to 16 so AED points can un-cluster.
  double get mapMaxZoom;

  /// Draws this sheet layer's static overlay when it becomes active. Called once
  /// per activation (behind the serial op queue). No-op for timeline layers.
  Future<void> render(MapLibreMapController controller);

  /// A map tap at [latLng] — sheet layers use it to select the nearest feature
  /// (opening [buildSheet]); no-op for timeline layers.
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller);

  /// Programmatically open a feature sheet for [id] (e.g. ranking → map
  /// handoff). No-op for layers without a selectable station/feature sheet.
  void selectFeature(String id);

  /// The bottom sheet for a sheet layer — a self-contained, collapsible panel
  /// that shows the tapped feature's detail. `SizedBox.shrink()` for timeline
  /// layers (the scaffold shows the timeline for those instead).
  Widget buildSheet(BuildContext context);

  /// Optional colour / key legend for the scaffold's top-left overlay.
  ///
  /// Return [SizedBox.shrink] when the layer has nothing to key (rare). Keep it
  /// compact — the map must stay readable beside the layer switcher.
  Widget buildLegend(BuildContext context);

  /// Optional chrome to the left of the layer switcher (top-right).
  ///
  /// Use for layer-specific toggles (e.g. typhoon overlay menu). Default is
  /// empty — most layers only need the shared switcher.
  ///
  /// [showTownLabels] / [onShowTownLabelsChanged] expose the base map's shared
  /// township-label setting, and [showTerrain] / [onShowTerrainChanged] the
  /// shared terrain-relief setting, so a layer's menu can carry them alongside
  /// its own options (one affordance, not extra chips). Layers whose chrome is
  /// not a settings menu may ignore them — [MapScaffold] shows a standalone
  /// base-map menu for layers that return no chrome.
  ///
  /// [onReloadActive] re-loads this layer from scratch — a chrome option that
  /// changes what the layer renders (e.g. the satellite colour style) calls it
  /// after mutating its source so the already-mounted tiles re-fetch.
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  });

  /// Flutter widgets painted over the map (screen-space callouts, etc.).
  ///
  /// Prefer this for readable text — MapLibre symbol glyphs can't mix CJK and
  /// Latin cleanly. Keep the subtree [IgnorePointer]-friendly (scaffold wraps
  /// it) so pan/zoom still hit the map. Return [SizedBox.shrink] when unused.
  /// Rebuilds on camera idle so projections stay in sync.
  Widget buildMapOverlay(BuildContext context);

  /// Whether [buildMapOverlay]'s subtree must be **rebuilt from scratch** on
  /// every camera settle so its screen-space projections are recomputed.
  ///
  /// True for a static overlay (typhoon callouts): it projects once per build,
  /// so a settle has to throw the subtree away. False for an overlay that reads
  /// the live camera itself every frame — re-keying one of those destroys its
  /// [State] on every pan, zoom and tap, which for an animation means the
  /// ticker, the simulation and the accumulated buffer are all rebuilt each
  /// time (see `WindParticleOverlay`).
  bool get overlayFollowsCamera => true;

  /// Camera settled after pan/zoom — sheet layers may prefetch viewport tiles.
  Future<void> onCameraIdle(MapLibreMapController controller);

  /// MapLibre's native renderer has fully loaded the current visible sources.
  ///
  /// This is stronger than [onCameraIdle] for raster timelines: Android's
  /// ambient cache can satisfy a source without passing its bytes through the
  /// app-owned L1 mirror, so native render readiness is the authoritative
  /// signal that a transparent frame can be revealed without a blank flash.
  void onMapIdle();

  /// A timeline drag started, before its first selected frame is dispatched.
  ///
  /// Raster layers use this edge to cancel speculative cache work immediately
  /// instead of letting it compete with the first interactive frame update.
  void onTimelineScrubStart();

  /// Ambient cache was wiped (e.g. after radar scrub + background). Layers that
  /// pin tiles via app HTTP should rehydrate from their ETag store.
  Future<void> onAmbientCacheCleared(MapLibreMapController controller);

  /// Finger/stylus went down on the map — hide ephemeral overlays (callouts).
  void onMapGestureStart();

  /// Gesture finished (pointer up with no camera motion, or camera idle).
  void onMapGestureEnd();

  /// The hosting surface was hidden or revealed — a tab switch, or a page
  /// pushed over the shell. A realtime layer should stop platform-channel
  /// writes while hidden (the data source keeps polling; the *map* is what
  /// nobody can see) and push one catch-up on the visible edge.
  void onSurfaceVisibility(bool visible);

  /// Android/iOS asked every process to give memory back.
  ///
  /// This is not a hint. `TRIM_MEMORY_RUNNING_CRITICAL` is the last notice
  /// before lmkd picks a victim, and a process that returns nothing is the
  /// process it picks — DPIP was OOM-killed at ~1 GB resident with 341 MB of
  /// it in mounted raster textures that no code path was willing to drop.
  ///
  /// Give back caches only. A layer must still be able to draw what the user
  /// is looking at when this returns: never release the displayed frame, and
  /// never let a release make a stale feed look current.
  Future<void> onMemoryPressure(MapLibreMapController controller);

  /// This layer's frames in **chronological order** (oldest first); the last is
  /// "now". `Ok(<empty>)` when the layer currently has nothing to show.
  Future<Result<List<MapFrame>>> frames();

  /// Registers the [frames] set (typically without touching [controller] — a
  /// layer adds tiles lazily in [show], so opening the map doesn't pay for every
  /// frame). Idempotent; called once per frame set.
  Future<void> prepare(MapLibreMapController controller, List<MapFrame> frames);

  /// Instantly reveals the already-[prepare]d [frame] (hiding the previous one).
  ///
  /// [scrubbing] is true while the timeline finger is down / flinging. Raster
  /// layers must not mount cold frames then (tile HTTP storms); they only
  /// opacity-switch among residents and load on settle (`scrubbing: false`).
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  });

  /// Removes this layer's sources/layers from [controller].
  Future<void> clear(MapLibreMapController controller);

  /// Forgets any on-map state after the base style reloaded (a theme / dark-mode
  /// change rebuilds the style, which drops every runtime source/layer). Must
  /// NOT touch the controller — the map is already wiped — so the next [prepare]
  /// re-adds from scratch instead of no-oping on stale "already added" state.
  void onStyleReset();
}

/// No-op bodies for the [MapLayer] members a given layer type doesn't use.
///
/// Timeline layers (radar, satellite, QPESUMS) draw nothing in [MapLayer.render]
/// and open no [MapLayer.buildSheet]; sheet layers (stations, typhoon) publish
/// no [MapLayer.frames]. A layer mixes this in and overrides only what it does —
/// the scaffold can then call the whole [MapLayer] surface without a chain of
/// empty implementations per layer.
mixin MapLayerDefaults implements MapLayer {
  @override
  String? subtitle(BuildContext context) => null;

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {}

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {}

  @override
  Future<void> render(MapLibreMapController controller) async {}

  @override
  Future<void> onMapTap(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {}

  @override
  void selectFeature(String id) {}

  @override
  Widget buildSheet(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildLegend(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => const SizedBox.shrink();

  @override
  bool get overlayFollowsCamera => true;

  @override
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {}

  @override
  void onMapIdle() {}

  @override
  void onTimelineScrubStart() {}

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {}

  @override
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  @override
  void onSurfaceVisibility(bool visible) {}

  @override
  Future<void> onMemoryPressure(MapLibreMapController controller) async {}

  @override
  double get mapMinZoom => BaseMap.defaultMinZoom;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  void onStyleReset() {}
}
