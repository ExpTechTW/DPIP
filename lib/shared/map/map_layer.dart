import 'package:dpip/core/error/result.dart';
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
  /// township-label setting, so a layer's menu can carry it alongside its own
  /// options (one affordance, not a second chip). Layers whose chrome is not a
  /// settings menu may ignore them — [MapScaffold] shows a standalone
  /// township-label menu for layers that return no chrome.
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
  });

  /// Flutter widgets painted over the map (screen-space callouts, etc.).
  ///
  /// Prefer this for readable text — MapLibre symbol glyphs can't mix CJK and
  /// Latin cleanly. Keep the subtree [IgnorePointer]-friendly (scaffold wraps
  /// it) so pan/zoom still hit the map. Return [SizedBox.shrink] when unused.
  /// Rebuilds on camera idle so projections stay in sync.
  Widget buildMapOverlay(BuildContext context);

  /// Camera settled after pan/zoom — sheet layers may prefetch viewport tiles.
  Future<void> onCameraIdle(MapLibreMapController controller);

  /// Ambient cache was wiped (e.g. after radar scrub + background). Layers that
  /// pin tiles via app HTTP should rehydrate from their ETag store.
  Future<void> onAmbientCacheCleared(MapLibreMapController controller);

  /// Finger/stylus went down on the map — hide ephemeral overlays (callouts).
  void onMapGestureStart();

  /// Gesture finished (pointer up with no camera motion, or camera idle).
  void onMapGestureEnd();

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
