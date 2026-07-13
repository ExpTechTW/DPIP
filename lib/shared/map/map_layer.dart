import 'package:dpip/core/error/result.dart';
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

  /// This layer's frames in **chronological order** (oldest first); the last is
  /// "now". `Ok(<empty>)` when the layer currently has nothing to show.
  Future<Result<List<MapFrame>>> frames();

  /// Preloads every [frames] entry onto [controller] up front — hidden, so their
  /// tiles fetch and cache in the background — making later [show] calls an
  /// instant swap rather than a fetch. Idempotent; called once per frame set.
  Future<void> prepare(MapLibreMapController controller, List<MapFrame> frames);

  /// Instantly reveals the already-[prepare]d [frame] (hiding the previous one).
  /// Cheap enough to call on every scrub tick, so the timeline can animate.
  Future<void> show(MapLibreMapController controller, MapFrame frame);

  /// Removes this layer's sources/layers from [controller].
  Future<void> clear(MapLibreMapController controller);

  /// Forgets any on-map state after the base style reloaded (a theme / dark-mode
  /// change rebuilds the style, which drops every runtime source/layer). Must
  /// NOT touch the controller — the map is already wiped — so the next [prepare]
  /// re-adds from scratch instead of no-oping on stale "already added" state.
  void onStyleReset();
}
