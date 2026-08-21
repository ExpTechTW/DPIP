/// Shared machinery for scrubbable raster overlays (radar echo, satellite IR).
library;

import 'dart:async';
import 'dart:collection';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/map/map_trace.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

enum _IdlePreloadOutcome { ready, timeout, cancelled }

/// A time-scrubbable raster overlay driven by a [RasterFrameSource].
///
/// ## The problem this solves
/// Every frame is its own MapLibre source. Making one visible is what makes
/// MapLibre load its tiles — so a fast scrub that toggled `visibility` per
/// frame issued a fresh viewport of tile requests for every frame the finger
/// swept past, and abandoned them a moment later.
///
/// ## Four tiers
/// - **The ring** — frames within [ringRadius] are mounted **visible**, only
///   the current one at full [opacity] and its neighbours at zero. During a
///   drag, an L1-complete frame may join this set on demand; [maxResident]
///   bounds the extra sources. A frame replaces the current timestamp only
///   after [RasterFrameSource.frameTileReadiness] proves that one complete
///   viewport zoom is in L1.
/// - **Ready residents** — after settle, complete neighbours expand outward to
///   [maxResident], then hide. Their sources and tiles stay ready without an
///   ongoing raster draw pass.
/// - **The warm window** — up to [warmFrameBudget] centre-out candidates were
///   included in the last local-cache fill. L2 hits are pushed into MapLibre
///   memory; L2 misses remain cold and are never mislabeled as display-ready.
/// - **Cold** — anything further out. Revealing it mounts and loads normally.
///
/// A drag flips complete ring members immediately. Beyond the ring it first
/// performs an L1-only probe: a complete frame is mounted and shown, preserving
/// the timeline's GIF-like preview, while a cold frame leaves the last complete
/// raster on screen. Finger-up is the only Dart path allowed to warm from L2 or
/// load a cold target. This keeps SQLite, HTTP and MapLibre's source scheduler
/// bounded without making a warm drag look frozen.
///
/// ## Settling
/// A settle mounts the target and neighbours first, keeps the previous frame
/// visible until the target is complete, then performs one opacity cutover. It
/// retires everything outside the new ring and schedules a local-cache warm
/// only after the display is correct.
///
/// ## Colour
/// Nothing here declares any, and that is not an oversight: every pixel a frame
/// draws arrives as a finished server-rendered tile, and MapLibre's raster layer
/// exposes no colour matrix — so a colour-vision correction cannot reach these
/// frames at all. A subclass's scale/legend colours are therefore exempt too
/// (`ColorVisionFilter.rasterExempt`): a key that disagreed with the picture
/// would be worse than one that is merely hard to read. The only paint values
/// below are opacities, which the correction never touches.
abstract class RasterTimelineLayer implements MapLayer {
  RasterTimelineLayer(this.source);

  /// Frames, tile URLs, and tile-memory control for this overlay.
  @protected
  final RasterFrameSource source;

  /// Opacity of the frame currently under the scrubber.
  @protected
  double get opacity;

  /// How many frames either side of the current one are kept **mounted and
  /// drawn** (transparent), so they can load before a scrub reaches them.
  ///
  /// Each extra frame costs a raster draw call every rendered frame plus a
  /// viewport of loaded tiles, so this stays small — [warmRadius] is the cheap
  /// way to widen the range a drag handles smoothly.
  @protected
  int get ringRadius => 2;

  /// How many frames either side have their tiles pushed into MapLibre's
  /// memory ahead of demand.
  ///
  /// This is the preferred window for a local-only warm. It is not a readiness
  /// claim: a URL absent from L2 remains cold, and the exact target probe gates
  /// the later cutover.
  @protected
  int get warmRadius => 4;

  /// Maximum frame candidates considered by one settled fill.
  ///
  /// 512 candidates are intentionally wider than the 48 MiB mirror can usually
  /// hold. The fill reads them centre-out in bounded batches and stops at 90%
  /// of the real native cap, so this maximises the useful L1 range without
  /// loading every candidate body into Dart or allowing a slow device to turn
  /// one settle into an unbounded whole-history scan. Near a series edge the
  /// unused side is given to the other side instead of wasting half the budget.
  @protected
  int get warmFrameBudget => 512;

  /// Mounted-source ceiling. This is deliberately much smaller than
  /// [warmFrameBudget]: L1 holds compressed response bodies, while a mounted
  /// MapLibre raster source can retain a decoded 512 px texture for every tile
  /// in the viewport. Keeping 32 frames mounted pushed an iOS simulator above
  /// 800 MiB even though the byte cache itself was capped at 48 MiB.
  ///
  /// Five slots are the visible +/-[ringRadius] ring; seven more are decoded
  /// ahead through the bounded idle worker pool. Eight made even an ordinary
  /// two-hour radar preview cross the expensive source-mount path repeatedly;
  /// twelve keeps that common GIF-like gesture local while remaining far below
  /// the old 32-source / 800 MiB failure mode. Frames outside this window still
  /// come from the much wider L1 fill, so mounting one during a scrub is local
  /// without retaining a whole timeline of decoded textures.
  /// Beyond this ceiling the least-recently-shown source is removed outright —
  /// `visibility: none` alone does not release its native tile textures.
  @protected
  int get maxResident => 12;

  /// Hook for extra style work once this layer's first frame is on the map
  /// (e.g. an outline layer that only makes sense over this overlay).
  @protected
  /// Where this layer's frames are anchored in the style.
  ///
  /// Defaults to under the base style's county borders, which keeps them legible
  /// through the raster. A layer that supplies its **own** borders on top should
  /// return null instead: leaving the base ones showing through as well draws
  /// every boundary twice, at two weights, and the pair reads as a smear.
  @protected
  String? get rasterBelowLayerId => outlineLayerId;

  /// The seam between this layer's frames and the chrome drawn over them.
  ///
  /// Every frame mounts **below** this layer and every piece of chrome mounts
  /// **above** it, which is the only thing that keeps the two apart while the
  /// timeline is being scrubbed. `belowLayerId` inserts *immediately* below its
  /// anchor, so when the frames and the borders shared one anchor
  /// ([rasterBelowLayerId]) each newly-mounted frame landed on top of the
  /// borders that were added at attach — the county and township lines sank
  /// under the echo the moment the user dragged the timeline, and stayed there.
  ///
  /// It is an empty GeoJSON line layer: it draws nothing and costs nothing, it
  /// exists only to hold a position in the style's layer order.
  String get frameSeamLayerId => '$id-frame-seam';

  String get _frameSeamSourceId => '$id-frame-seam-src';

  /// Where chrome drawn *over* the frames anchors — above [frameSeamLayerId],
  /// under the same style layer the frames are held beneath.
  ///
  /// Chrome must not pick its own anchor: one that resolves below the seam puts
  /// the overlay under the raster it is supposed to annotate, which is how the
  /// radar scan-range circle came to be drawn beneath the echo.
  @protected
  String? get chromeBelowLayerId => rasterBelowLayerId;

  /// What the frame times *are*, for the timeline caption above the date.
  ///
  /// Observed data (radar, satellite) keeps the shared "observed" label; a
  /// forecast layer says so instead, so its frames are never read as
  /// measurements.
  String timelineCaption(BuildContext context) =>
      AppLocalizations.of(context).mapTimelineObserved;

  /// How long one frame's data represents, when a frame is a period rather
  /// than a point — `null` keeps the shared point-in-time timeline label.
  ///
  /// A next-hour forecast's frame at 21:00 estimates the 21:00–22:00 window,
  /// so a layer like QPESUMS returns the hour and the timeline renders the
  /// selected frame as a range instead of a bare instant.
  Duration? get framePeriod => null;

  /// Whether [frames] are all one forecast-model run — when true, the oldest
  /// valid frame is that run's issue time (資料時間).
  ///
  /// Observed layers leave this false; a forecast may opt in only when every
  /// returned valid time is guaranteed to come from the same cycle.
  @protected
  bool get framesAreOneRun => false;

  /// The model-run issue time behind these frames, when they are one run — the
  /// oldest frame *is* the run start. `null` before [prepare] fills the list.
  DateTime? get modelRunTime {
    final run = framesAreOneRun;
    if (!run || _orderedIds.isEmpty) return null;
    return parseFrameTime(_orderedIds.first);
  }

  Future<void> onAttached(MapLibreMapController controller) async {}

  /// Undoes [onAttached]. Called from [clear].
  @protected
  Future<void> onDetached(MapLibreMapController controller) async {}

  // --- MapLayer surface a raster timeline never varies -----------------------

  @override
  bool get usesTimeline => true;

  @override
  String? subtitle(BuildContext context) => null;

  @override
  double get bottomChromeFraction => 0;

  @override
  double get mapMinZoom => 4;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  Future<void> render(MapLibreMapController controller) async {}

  @override
  Future<void> onMapTap(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {}

  @override
  Widget buildSheet(BuildContext context) => const SizedBox.shrink();

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
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  @override
  bool get overlayFollowsCamera => true;

  @override
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  /// Whether the native map is actually being drawn.
  ///
  /// The shell keeps this layer mounted while another tab or route covers it.
  /// A wide settled warm must stop on that hidden edge: otherwise thousands of
  /// cached tile bodies can keep crossing the platform channel off-screen, then
  /// collide with MapLibre's queued decode work when rendering resumes.
  bool _surfaceVisible = true;

  /// Hidden surfaces cancel speculative work, but a return to the same settled
  /// timestamp must rebuild it. Without this hand-off the cancellation left
  /// only the five-frame core mounted forever; the wider ready-resident set
  /// that makes a drag look like a GIF was never restored.
  bool _resumeBackgroundWork = false;

  /// The next native map must receive the repaired SQLite bodies before its
  /// first raster sources are mounted. The iOS platform view is destroyed on
  /// tab return, but its process-wide L1 survives and can still contain the
  /// malformed empty GIF that arrived from the network before Dart normalised
  /// it. Re-injecting the small visible ring prevents one source from decoding
  /// stale L1 bytes while its neighbours resolve to the repaired PNG in L2.
  bool _refreshResidentOnNextSettle = false;

  /// Controller belonging to this layer's one map surface. Retained only so a
  /// hidden-tab edge can remove decoded speculative sources; tile bytes stay in
  /// L1/L2 and the visible ring remains mounted for a cheap return.
  MapLibreMapController? _mapController;

  @override
  void onSurfaceVisibility(bool visible) {
    if (_surfaceVisible == visible) return;
    _surfaceVisible = visible;
    if (visible) return;

    // Invalidate readiness polls and idle-preload workers immediately. Keep the
    // mounted/current frame intact so returning is a cheap render resume rather
    // than a clear + rebuild; MapScaffold will call show() if the server has a
    // genuinely newer current frame.
    _resumeBackgroundWork = _settledFrameId != null;
    _revealGeneration++;
    source.cancelTileWarm();
    final controller = _mapController;
    if (controller != null) unawaited(_trimHiddenResidents(controller));
    mapTrace(
      'timeline/$id',
      () =>
          'surface-hidden resident=${_resident.length} ring=${_ring.length} '
          'trim-scheduled=${controller != null}',
    );
    MapTileCache.trace(
      () => 'timeline=$id surface-hidden cancel-background-work',
    );
  }

  /// Stops all work tied to a platform view immediately before it is replaced.
  ///
  /// Unlike [onSurfaceVisibility], this must not remove layers through the old
  /// controller: the native map is already being torn down. The style reset
  /// clears bookkeeping, while [_refreshResidentOnNextSettle] deliberately
  /// survives it so the replacement view repairs its L1 before mounting.
  void onControllerInvalidated() {
    final hadFrame =
        _settledFrameId != null ||
        _shownFrameId != null ||
        _requestedFrameId != null;
    _refreshResidentOnNextSettle |= hadFrame;
    _surfaceVisible = false;
    _resumeBackgroundWork = false;
    _warmCentre = null;
    _revealGeneration++;
    source.cancelTileWarm();
    _mapController = null;
    // The rectangle belonged to the view being replaced. The camera is restored
    // onto the new one, so it would otherwise compare equal and be reused.
    _viewportCache = null;
    _viewportCamera = null;
    mapTrace(
      'timeline/$id',
      () => 'controller-invalidated refresh=$_refreshResidentOnNextSettle',
    );
  }

  // --- Frame bookkeeping -----------------------------------------------------

  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};

  /// Frames with a source + layer on the map.
  final Set<String> _resident = <String>{};

  /// Residents currently `visibility: visible`: the settled preload ring plus
  /// any L1-complete frames revealed during the active scrub.
  final Set<String> _ring = <String>{};

  /// Least-recently-shown first, for [maxResident] eviction.
  final Queue<String> _lru = Queue<String>();

  /// The frame the timeline most recently asked for. It can be newer than
  /// [_shownFrameId]: a cold target stays transparent until its viewport is
  /// complete, while the last complete timestamp remains on screen.
  String? _requestedFrameId;
  String? _shownFrameId;
  String? _settledFrameId;
  int _revealGeneration = 0;

  /// A timeline gesture has pre-empted the previous settle's speculative warm.
  /// It is cleared only by finger-up, which schedules one replacement around
  /// the final frame.
  bool _warmSuspended = false;

  /// Frames proven complete for the current viewport while their source stays
  /// resident. Camera movement invalidates this set.
  final Set<String> _readyFrames = <String>{};

  /// The last answer from [_viewport], with the camera it was read at.
  ///
  /// Every readiness probe and every warm needs the visible rectangle, and
  /// `getVisibleRegion` is a platform round-trip. A timeline scrub asked for
  /// one per crossed frame while the camera was, by construction, standing
  /// still — the finger is on the ruler, not on the map — so a fast drag spent
  /// a round-trip per tick re-deriving a rectangle that had not moved, on the
  /// same platform thread the tile bytes have to come back through.
  ({LatLngBounds bounds, double zoom})? _viewportCache;
  CameraPosition? _viewportCamera;

  /// Polling finishes outside MapScaffold's serial reveal lane. Its final style
  /// mutation rejoins this queue so a newly requested frame and an older tile
  /// completion can never write opacities concurrently.
  Future<void> _mutationTail = Future<void>.value();
  bool _attached = false;

  static const Duration _readyPoll = Duration(milliseconds: 40);
  static const Duration _decodeGrace = Duration(milliseconds: 32);
  static const Duration _readyTimeout = Duration(seconds: 2);
  static const int _idlePreloadConcurrency = 3;
  static const Duration _idleReadyPoll = Duration(milliseconds: 80);
  static const Duration _idleReadyTimeout = Duration(seconds: 8);

  /// Whether [frameSeamLayerId] is currently on the map.
  bool _seamMounted = false;

  /// Shared by parallel ring mounts. Without this, every cold neighbour could
  /// observe `_seamMounted == false` and race `addSource` for the same id.
  Future<void>? _seamMounting;

  /// The frame index the warm band is currently centred on — the gate that
  /// keeps a scrub from re-warming (or re-fetching the visible region) for
  /// every frame it crosses. Set synchronously by [_warmBand] before its first
  /// await, so concurrent scrub reveals past the band edge coalesce onto one
  /// re-warm instead of one per frame.
  int? _warmCentre;

  String _sourceId(String frameId) => '$id-src-$frameId';
  String _layerId(String frameId) => '$id-lyr-$frameId';

  /// Paint a frame is mounted with.
  ///
  /// The zero transition is what makes a scrub read as a loop rather than a
  /// smear: `raster-opacity` is an animated paint property whose style-spec
  /// default is a **300 ms** cross-fade, so every swap used to blend two frames
  /// for longer than the finger takes to cross the next one — the map could
  /// never catch up, however fast the tiles resolved.
  static RasterLayerProperties _mountPaint(double value) =>
      RasterLayerProperties(
        visibility: 'visible',
        rasterOpacity: value,
        // Separate from the opacity transition below: MapLibre also fades each
        // tile in for 300 ms when a source is mounted or a parent tile is
        // replaced. A timeline source that comes back from L1 therefore still
        // flashes transparent even though the cache hit itself takes ~2 ms.
        // Frames are discrete observations, so an in-between tile has no
        // truthful visual meaning; draw the cached/new tile atomically.
        rasterFadeDuration: 0,
        rasterOpacityTransition: _instantTransition,
      );

  /// The zero cross-fade every opacity write must carry.
  ///
  /// Declared at mount, `raster-opacity-transition` usually governs later
  /// changes for free — but only while the native layer keeps it. Some paths
  /// (a style reload, the platform's layer re-add, an update that only carries
  /// the changed property) can lose it, which silently restores the 300 ms
  /// style-spec default and ghosts every old frame behind a fast scrub. Sending
  /// it with every write makes the zero fade explicit instead of remembered.
  static const Map<String, Object> _instantTransition = {
    'duration': 0,
    'delay': 0,
  };

  /// Scrub-path paint: opacity + its zero transition.
  ///
  /// Sent with `skipNulls` so the platform call carries just these two
  /// properties instead of every raster property the layer type has — the full
  /// form makes the platform side re-assign eight values that did not change,
  /// on a path that runs for every frame the finger crosses.
  static RasterLayerProperties _opacity(double value) => RasterLayerProperties(
    rasterOpacity: value,
    rasterOpacityTransition: _instantTransition,
  );

  static const RasterLayerProperties _hidden = RasterLayerProperties(
    visibility: 'none',
    rasterOpacity: 0,
    rasterOpacityTransition: _instantTransition,
  );

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await source.frames();
    return result.map(
      (raw) =>
          [for (final id in raw) MapFrame(id: id, time: parseFrameTime(id))]
            ..sort((a, b) => a.time.compareTo(b.time)),
    );
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {
    _mapController = controller;
    _orderedIds = [for (final frame in frames) frame.id];
    _indexById = {for (var i = 0; i < frames.length; i++) frames[i].id: i};
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) {
    _mapController = controller;
    final index = _indexById[frame.id];
    if (index == null) return Future<void>.value();
    if (scrubbing) {
      _suspendWarm();
    } else {
      final resumeWarm = _warmSuspended;
      final resumeBackgroundWork = _surfaceVisible && _resumeBackgroundWork;
      if (_surfaceVisible) _resumeBackgroundWork = false;
      _warmSuspended = false;
      if (_shownFrameId == frame.id && _settledFrameId == frame.id) {
        if (resumeWarm || resumeBackgroundWork) {
          // A tap/short drag or a hidden surface can finish on the same
          // timestamp. Both cancelled the old fill, so restart the wide L1
          // fill and ready-resident preload instead of leaving only the core
          // ring available to the next scrub.
          _warmCentre = null;
          unawaited(
            _warmThenPreload(
              controller,
              index,
              frame.id,
              _revealGeneration,
              refreshResident: resumeBackgroundWork,
            ),
          );
        }
        return Future<void>.value();
      }
    }
    if (scrubbing &&
        _requestedFrameId == frame.id &&
        _shownFrameId == frame.id) {
      return Future<void>.value();
    }
    _requestedFrameId = frame.id;
    final generation = ++_revealGeneration;
    return _enqueueMutation(
      () => _showRequested(
        controller,
        index,
        frame.id,
        scrubbing: scrubbing,
        generation: generation,
      ),
    );
  }

  /// Whether [frameId] is the complete timestamp currently being drawn.
  ///
  /// During a fast scrub the requested frame can be newer than this value: an
  /// L1-incomplete target deliberately leaves the previous frame opaque. The
  /// scaffold uses that distinction to show its backpressure notice only when
  /// output has actually stopped following the timeline.
  bool isShowingFrame(String frameId) => _shownFrameId == frameId;

  Future<void> _showRequested(
    MapLibreMapController controller,
    int index,
    String frameId, {
    required bool scrubbing,
    required int generation,
  }) async {
    if (!_isCurrent(frameId, generation)) return;
    final tier = _ring.contains(frameId)
        ? 'ring'
        : _warmCovers(index)
        ? 'warm-window'
        : 'cold';
    MapTileCache.trace(
      () =>
          'timeline=$id show frame=$frameId index=$index '
          'scrubbing=$scrubbing tier=$tier previous=$_shownFrameId',
    );

    if (!scrubbing) {
      await _settle(controller, index, frameId, generation);
      return;
    }

    final inRing = _ring.contains(frameId);
    if (inRing) _touch(frameId);
    if (_readyFrames.contains(frameId)) {
      if (!inRing) {
        await _stageScrubFrame(controller, frameId);
        if (!_isCurrent(frameId, generation)) return;
        // Idle-preloaded sources are hidden to avoid permanent draw passes.
        // Restoring one is an L1 hit, but MapLibre still needs render turns to
        // decode/paint it before the opacity cutover.
        await Future<void>.delayed(_decodeGrace);
        if (!_isCurrent(frameId, generation)) return;
      }
      await _flip(controller, frameId);
      return;
    }
    await _beginReadyReveal(
      controller,
      index,
      frameId,
      generation,
      settling: false,
    );
  }

  /// Scrub hot path — never cancels and rarely touches `visibility`.
  ///
  /// The two writes cross the platform boundary as one native batch. Two
  /// separate MethodChannel calls still serialize on Android's platform thread
  /// even when their Dart futures start together, consuming most of a frame.
  /// One batch also prevents the renderer from observing the old frame hidden
  /// before the new frame is visible.
  ///
  /// The previous ring member only fades to zero — dropping it to `none` would
  /// evict its tiles and make a nearby reversal reload. The non-ring branch is
  /// defensive for a stale state after a style/source change; it hides that
  /// frame outright so it cannot ghost behind the current ring.
  Future<void> _flip(MapLibreMapController controller, String frameId) async {
    final elapsed = Stopwatch()..start();
    final previous = _shownFrameId;
    _shownFrameId = frameId;
    _touch(frameId);

    await controller.setLayerPropertiesBatch([
      if (previous != null && previous != frameId)
        (
          layerId: _layerId(previous),
          properties: _ring.contains(previous) ? _opacity(0) : _hidden,
        ),
      (layerId: _layerId(frameId), properties: _opacity(opacity)),
    ], skipNulls: true);
    MapTileCache.trace(
      () =>
          'timeline=$id reveal frame=$frameId path=flip previous=$previous '
          'dt=${elapsed.elapsedMilliseconds}ms',
    );
  }

  /// Re-centres the preload ring on [frameId] and reveals it.
  Future<void> _settle(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation,
  ) async {
    final elapsed = Stopwatch()..start();
    final (low, high, ring) = _ringAt(index);
    MapTileCache.trace(
      () =>
          'timeline=$id settle start frame=$frameId index=$index '
          'ring=$low..$high shown=$_shownFrameId',
    );

    if (_refreshResidentOnNextSettle) {
      _refreshResidentOnNextSettle = false;
      await _refreshRingTileBytes(controller, frameId, ring);
      if (!_isCurrent(frameId, generation)) {
        // A newer selection or another lifecycle edge won while the viewport
        // query/injection was in flight. Its settle now owns the one refresh.
        _refreshResidentOnNextSettle = true;
        return;
      }
    }

    final hadPrevious = _shownFrameId != null;
    // Mount the target and its neighbours transparent first. `visibility`
    // stays on, so MapLibre starts the cold requests while the last complete
    // timestamp remains fully opaque below them.
    await Future.wait([
      for (final id in ring)
        if (id != _shownFrameId) _mount(controller, id, 0),
    ]);
    _ring.addAll(ring);
    MapTileCache.trace(
      () =>
          'timeline=$id settle staged frame=$frameId mounted=${ring.length} '
          'previous=$_shownFrameId dt=${elapsed.elapsedMilliseconds}ms',
    );

    // There is no older raster to preserve on first attach. Show the initial
    // frame immediately; readiness gating starts with subsequent timestamps.
    if (!hadPrevious) {
      await _flip(controller, frameId);
      await _finishSettle(controller, index, frameId, generation);
      return;
    }
    if (_shownFrameId == frameId || _readyFrames.contains(frameId)) {
      if (_shownFrameId != frameId) await _flip(controller, frameId);
      await _finishSettle(controller, index, frameId, generation);
      return;
    }
    await _beginReadyReveal(
      controller,
      index,
      frameId,
      generation,
      settling: true,
    );
  }

  /// Overwrites the replacement map's visible L1 ring from the repaired L2.
  /// This is bounded to the frames MapLibre is about to mount; the wide
  /// centre-out fill resumes after reveal and can remain cooperative.
  Future<void> _refreshRingTileBytes(
    MapLibreMapController controller,
    String frameId,
    Set<String> ring,
  ) async {
    final elapsed = Stopwatch()..start();
    try {
      final viewport = await _viewport(controller);
      await source.warmFrameTiles(
        frames: [
          frameId,
          for (final id in ring)
            if (id != frameId) id,
        ],
        south: viewport.bounds.southwest.latitude,
        west: viewport.bounds.southwest.longitude,
        north: viewport.bounds.northeast.latitude,
        east: viewport.bounds.northeast.longitude,
        zoom: viewport.zoom,
        immediate: true,
        refreshResident: true,
      );
      MapTileCache.trace(
        () =>
            'timeline=$id recreate-refresh frame=$frameId ring=${ring.length} '
            'dt=${elapsed.elapsedMilliseconds}ms',
      );
    } catch (error, stackTrace) {
      // Mounting may still succeed from MapLibre's own cache. Keep the map
      // usable and let the later readiness/warm paths retry individual tiles.
      Log.handle(error, stackTrace, '$id recreate tile refresh');
    }
  }

  /// Starts one exact-viewport L1 check. A cold result is polled outside the
  /// mutation queue, so timeline input remains responsive while HTTP finishes.
  Future<void> _beginReadyReveal(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation, {
    required bool settling,
  }) async {
    if (!_isCurrent(frameId, generation)) return;
    final viewport = await _viewport(controller);
    if (!_isCurrent(frameId, generation)) return;
    final bounds = viewport.bounds;
    final zoom = viewport.zoom;
    final elapsed = Stopwatch()..start();
    final readiness = await source.frameTileReadiness(
      frame: frameId,
      south: bounds.southwest.latitude,
      west: bounds.southwest.longitude,
      north: bounds.northeast.latitude,
      east: bounds.northeast.longitude,
      zoom: zoom,
      // A scrub is an L1-only probe. SQLite and injection are reserved for the
      // final settle; otherwise every crossed tick starts an I/O batch even in
      // a region whose visible frame is already cached.
      warm: settling,
    );
    if (!_isCurrent(frameId, generation)) return;
    final nativeReady = _readyFrames.contains(frameId);
    MapTileCache.trace(
      () =>
          'timeline=$id readiness frame=$frameId phase=initial '
          'ready=${readiness.ready} resident=${readiness.resident}/'
          '${readiness.required} native=$nativeReady '
          'zoom=${zoom.toStringAsFixed(2)} '
          'dt=${elapsed.elapsedMilliseconds}ms',
    );
    if (readiness.ready || nativeReady) {
      if (!settling && !_ring.contains(frameId)) {
        // Readiness was an L1-only probe. Mounting after it succeeds lets
        // MapLibre satisfy the display tiles entirely from memory; doing this
        // in the opposite order would start native tile requests for every
        // cold tick crossed by a fast finger.
        await _stageScrubFrame(controller, frameId);
        if (!_isCurrent(frameId, generation)) return;
      }
      if (!nativeReady) {
        // L1 residency means native owns the encoded bytes, not that MapLibre
        // has decoded and painted them. Give the frame two render turns unless
        // the native renderer has already reported the whole ring idle.
        await Future<void>.delayed(_decodeGrace);
        if (!_isCurrent(frameId, generation)) return;
      }
      await _commitReveal(
        controller,
        index,
        frameId,
        generation,
        settling: settling,
      );
      return;
    }
    if (!settling) {
      MapTileCache.trace(
        () =>
            'timeline=$id readiness frame=$frameId phase=l1-hold '
            'resident=${readiness.resident}/${readiness.required} '
            'dt=${elapsed.elapsedMilliseconds}ms',
      );
      return;
    }
    unawaited(
      _pollReadyReveal(
        controller,
        index,
        frameId,
        generation,
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
        settling: settling,
      ),
    );
  }

  /// Makes an L1-complete scrub target drawable without letting a long gesture
  /// accumulate an unbounded number of MapLibre sources.
  ///
  /// A newer input may arrive while the platform is adding this source. The
  /// now-stale frame remains transparent and resident, then normal LRU eviction
  /// or the final settle retires it; removing it immediately would add another
  /// pair of platform calls to the input hot path.
  Future<void> _stageScrubFrame(
    MapLibreMapController controller,
    String frameId,
  ) async {
    await _mount(controller, frameId, 0);
    _ring.add(frameId);
    final keep = <String>{frameId};
    final shown = _shownFrameId;
    if (shown != null) keep.add(shown);
    await _evictOverflow(controller, keep: keep);
  }

  Future<void> _pollReadyReveal(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation, {
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    required bool settling,
  }) async {
    final elapsed = Stopwatch()..start();
    FrameTileReadiness readiness = (ready: false, resident: 0, required: 0);
    while (!_readyFrames.contains(frameId) &&
        elapsed.elapsed < _readyTimeout &&
        _isCurrent(frameId, generation)) {
      await Future<void>.delayed(_readyPoll);
      if (!_isCurrent(frameId, generation)) return;
      readiness = await source.frameTileReadiness(
        frame: frameId,
        south: south,
        west: west,
        north: north,
        east: east,
        zoom: zoom,
      );
      if (readiness.ready || _readyFrames.contains(frameId)) break;
    }
    if (!_isCurrent(frameId, generation)) return;
    final nativeReady = _readyFrames.contains(frameId);
    if (!readiness.ready && !nativeReady) {
      MapTileCache.trace(
        () =>
            'timeline=$id readiness frame=$frameId phase=timeout hold=$_shownFrameId '
            'resident=${readiness.resident}/${readiness.required} '
            'dt=${elapsed.elapsedMilliseconds}ms',
      );
      return;
    }
    if (!nativeReady) {
      // Network bytes enter L1 before MapLibre finishes decoding them. Keep the
      // complete previous frame for two render intervals, then cut over once.
      await Future<void>.delayed(_decodeGrace);
      if (!_isCurrent(frameId, generation)) return;
    }
    await _enqueueMutation(
      () => _commitReveal(
        controller,
        index,
        frameId,
        generation,
        settling: settling,
      ),
    );
    MapTileCache.trace(
      () =>
          'timeline=$id readiness frame=$frameId phase=ready '
          'resident=${readiness.resident}/${readiness.required} '
          'native=$nativeReady '
          'dt=${elapsed.elapsedMilliseconds}ms',
    );
  }

  Future<void> _commitReveal(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation, {
    required bool settling,
  }) async {
    if (!_isCurrent(frameId, generation)) return;
    await _flip(controller, frameId);
    if (!_isCurrent(frameId, generation)) return;
    _readyFrames.add(frameId);
    if (settling) {
      await _finishSettle(controller, index, frameId, generation);
    }
  }

  Future<void> _finishSettle(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation,
  ) async {
    if (!_isCurrent(frameId, generation)) return;
    final (_, _, ring) = _ringAt(index);
    if (!_attached) {
      _attached = true;
      await onAttached(controller);
      if (!_isCurrent(frameId, generation)) return;
    }
    await _retireOutside(controller, ring);
    if (!_isCurrent(frameId, generation)) return;
    _ring.addAll(ring);
    await _evictOverflow(controller, keep: ring);
    if (!_isCurrent(frameId, generation)) return;
    _settledFrameId = frameId;
    MapTileCache.trace(
      () =>
          'timeline=$id settle complete frame=$frameId mounted=${ring.length} '
          'schedule-warm=true',
    );
    // Use the warmer's debounce. A new gesture cancels this before its SQLite
    // batch starts; an immediate fill here was the dominant high-speed scrub
    // stall when users reversed direction just after finger-up. Once the local
    // fill finishes, idle time expands the real source preload one frame at a
    // time — never a second burst of parallel viewport requests.
    unawaited(_warmThenPreload(controller, index, frameId, generation));
  }

  Future<void> _warmThenPreload(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation, {
    bool refreshResident = false,
  }) async {
    if (!_surfaceVisible || !_isCurrent(frameId, generation)) return;
    await _warmBand(controller, index, refreshResident: refreshResident);
    if (!_surfaceVisible ||
        _warmSuspended ||
        !_isCurrent(frameId, generation)) {
      return;
    }
    try {
      await _preloadSettledNeighbours(controller, index, frameId, generation);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id idle timeline preload');
    }
  }

  /// Uses otherwise-idle time to prepare the largest source window the
  /// resident ceiling permits with a small, fixed worker pool.
  ///
  /// The immediate ±[ringRadius] ring remains visible. Extra sources are
  /// At most [_idlePreloadConcurrency] cold frames can issue viewport requests
  /// together. Each is hidden once complete: its encoded tiles stay in L1 and
  /// the source stays resident, but transparent rasters do not keep consuming
  /// draw passes. A later scrub restores one with [_stageScrubFrame].
  Future<void> _preloadSettledNeighbours(
    MapLibreMapController controller,
    int index,
    String frameId,
    int generation,
  ) async {
    if (_orderedIds.isEmpty || maxResident <= 0) return;
    final preload = _nearestFrames(index, maxResident);
    final preloadSet = preload.toSet();
    final core = _ringAt(index).$3;
    final candidates = [
      for (final candidate in preload)
        if (!core.contains(candidate)) candidate,
    ];
    if (candidates.isEmpty) return;
    final viewport = await _viewport(controller);
    final bounds = viewport.bounds;
    final zoom = viewport.zoom;
    final elapsed = Stopwatch()..start();
    final workers = candidates.length < _idlePreloadConcurrency
        ? candidates.length
        : _idlePreloadConcurrency;
    var next = 0;
    var complete = 0;
    var timedOut = 0;
    MapTileCache.trace(
      () =>
          'timeline=$id idle-preload start frame=$frameId '
          'candidates=${candidates.length} workers=$workers '
          'resident=${_resident.length}',
    );
    mapTrace(
      'timeline/$id',
      () =>
          'idle-preload start candidates=${candidates.length} workers=$workers '
          'resident=${_resident.length}/$maxResident',
    );

    Future<void> runWorker() async {
      while (!_warmSuspended && _isCurrent(frameId, generation)) {
        if (next >= candidates.length) return;
        final candidate = candidates[next++];
        final outcome = await _preloadSettledFrame(
          controller,
          candidate,
          preloadSet,
          frameId,
          generation,
          south: bounds.southwest.latitude,
          west: bounds.southwest.longitude,
          north: bounds.northeast.latitude,
          east: bounds.northeast.longitude,
          zoom: zoom,
        );
        switch (outcome) {
          case _IdlePreloadOutcome.ready:
            complete++;
          case _IdlePreloadOutcome.timeout:
            timedOut++;
          case _IdlePreloadOutcome.cancelled:
            return;
        }
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) runWorker()]);
    MapTileCache.trace(
      () =>
          'timeline=$id idle-preload done frame=$frameId complete=$complete '
          'timeout=$timedOut '
          'resident=${_resident.length}/$maxResident '
          'dt=${elapsed.elapsedMilliseconds}ms',
    );
    mapTrace(
      'timeline/$id',
      () =>
          'idle-preload done complete=$complete timeout=$timedOut '
          'resident=${_resident.length}/$maxResident '
          'dt=${elapsed.elapsedMilliseconds}ms',
    );
  }

  Future<_IdlePreloadOutcome> _preloadSettledFrame(
    MapLibreMapController controller,
    String candidate,
    Set<String> preloadSet,
    String frameId,
    int generation, {
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {
    bool current() =>
        _surfaceVisible && !_warmSuspended && _isCurrent(frameId, generation);

    await _enqueueMutation(() async {
      if (!current()) return;
      await _mount(controller, candidate, 0);
      _ring.add(candidate);
      await _evictOverflow(controller, keep: preloadSet);
    });
    if (!current()) {
      await _discardIdleFrame(controller, candidate);
      return _IdlePreloadOutcome.cancelled;
    }

    var readiness = await source.frameTileReadiness(
      frame: candidate,
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
    );
    final waiting = Stopwatch()..start();
    while (!readiness.ready &&
        !_readyFrames.contains(candidate) &&
        waiting.elapsed < _idleReadyTimeout &&
        current()) {
      await Future<void>.delayed(_idleReadyPoll);
      if (!current()) break;
      readiness = await source.frameTileReadiness(
        frame: candidate,
        south: south,
        west: west,
        north: north,
        east: east,
        zoom: zoom,
      );
    }
    if (!current()) {
      await _discardIdleFrame(controller, candidate);
      return _IdlePreloadOutcome.cancelled;
    }
    if (!readiness.ready && !_readyFrames.contains(candidate)) {
      MapTileCache.trace(
        () =>
            'timeline=$id idle-preload frame=$candidate reason=timeout '
            'resident=${readiness.resident}/${readiness.required}',
      );
      await _discardIdleFrame(controller, candidate);
      return _IdlePreloadOutcome.timeout;
    }

    await _enqueueMutation(() async {
      if (!current()) return;
      _readyFrames.add(candidate);
      _ring.remove(candidate);
      await controller.setLayerProperties(
        _layerId(candidate),
        _hidden,
        skipNulls: true,
      );
    });
    if (!current()) {
      await _discardIdleFrame(controller, candidate);
      return _IdlePreloadOutcome.cancelled;
    }
    return _IdlePreloadOutcome.ready;
  }

  /// Drops a speculative source that did not become display-ready. A frame the
  /// gesture has already adopted is left alone; removing the last complete
  /// timestamp while its replacement is cold would blank the map.
  Future<void> _discardIdleFrame(
    MapLibreMapController controller,
    String candidate,
  ) => _enqueueMutation(() async {
    // A hidden-surface trim may have removed this candidate while its
    // readiness worker was between polls. Do not issue duplicate native
    // removeLayer/removeSource calls when that worker observes cancellation.
    if (!_resident.contains(candidate)) return;
    if (candidate == _requestedFrameId || candidate == _shownFrameId) return;
    await source.abandonFrames([candidate]);
    _ring.remove(candidate);
    _resident.remove(candidate);
    _readyFrames.remove(candidate);
    _lru.remove(candidate);
    await _removeFrame(controller, candidate);
  });

  /// Releases decoded speculative sources once this retained tab is hidden.
  ///
  /// The settled ring stays mounted, so returning does not blank or rebuild the
  /// displayed timestamp. Only the extra ready-resident sources are removed;
  /// their compressed tile bodies remain in the native L1 and SQLite L2 caches
  /// and are rebuilt by the idle pool after the surface is visible again.
  Future<void> _trimHiddenResidents(MapLibreMapController controller) =>
      _enqueueMutation(() async {
        if (_surfaceVisible || _resident.isEmpty) return;
        final shown = _shownIndex;
        final keep = shown == null
            ? <String>{?_shownFrameId}
            : _ringAt(shown).$3;
        final stale = [
          for (final candidate in _resident)
            if (!keep.contains(candidate)) candidate,
        ];
        if (stale.isEmpty) return;
        mapTrace(
          'timeline/$id',
          () => 'hidden-trim start remove=${stale.length} keep=${keep.length}',
        );
        await source.abandonFrames(stale);
        for (final candidate in stale) {
          _resident.remove(candidate);
          _ring.remove(candidate);
          _readyFrames.remove(candidate);
          _lru.remove(candidate);
          await _removeFrame(controller, candidate);
        }
        mapTrace(
          'timeline/$id',
          () => 'hidden-trim done resident=${_resident.length}',
        );
      });

  void _suspendWarm() {
    if (_warmSuspended) return;
    _warmSuspended = true;
    _warmCentre = null;
    source.cancelTileWarm();
    MapTileCache.trace(() => 'timeline=$id warm-suspend');
  }

  bool _isCurrent(String frameId, int generation) =>
      _surfaceVisible &&
      generation == _revealGeneration &&
      _requestedFrameId == frameId;

  Future<void> _enqueueMutation(Future<void> Function() operation) {
    final next = _mutationTail.then((_) => operation());
    _mutationTail = next.catchError((Object error, StackTrace stackTrace) {
      Log.handle(error, stackTrace, '$id timeline mutation');
    });
    return next;
  }

  /// Mounts [id] if cold, then draws it at [value]. Always leaves it `visible`,
  /// so MapLibre keeps its tiles loaded.
  ///
  /// Ring membership is the caller's call. A settle mounts its cold window;
  /// scrubbing reaches this only after an L1-only readiness probe succeeds.
  Future<void> _mount(
    MapLibreMapController controller,
    String id,
    double value,
  ) async {
    _touch(id);
    if (_resident.contains(id)) {
      // Back into the ring from `none`: restore visibility *and* the opacity.
      await controller.setLayerProperties(
        _layerId(id),
        RasterLayerProperties(
          visibility: 'visible',
          rasterOpacity: value,
          rasterOpacityTransition: _instantTransition,
        ),
        skipNulls: true,
      );
      return;
    }
    MapTileCache.trace(
      () => 'timeline=${this.id} mount frame=$id opacity=$value source=new',
    );
    await _ensureSeam(controller);
    await controller.addSource(
      _sourceId(id),
      RasterSourceProperties(tiles: [source.tileUrl(id)], tileSize: 256),
    );
    await controller.addRasterLayer(
      _sourceId(id),
      _layerId(id),
      _mountPaint(value),
      // Under the seam, never under the shared anchor: chrome sits between the
      // two, and anchoring here is what stops a scrub from burying it.
      belowLayerId: _seamMounted ? frameSeamLayerId : rasterBelowLayerId,
    );
    _resident.add(id);
  }

  /// Puts the seam on the map once, before the first frame.
  ///
  /// Best-effort: if it cannot be added the frames fall back to the shared
  /// anchor, which is the old behaviour — a scrub that re-buries the borders is
  /// worse than the alternative, but a map with no echo at all is worse still.
  Future<void> _ensureSeam(MapLibreMapController controller) {
    if (_seamMounted) return Future<void>.value();
    final mounting = _seamMounting;
    if (mounting != null) return mounting;
    final future = _mountSeam(controller);
    _seamMounting = future;
    return future.whenComplete(() {
      if (identical(_seamMounting, future)) _seamMounting = null;
    });
  }

  Future<void> _mountSeam(MapLibreMapController controller) async {
    try {
      await controller.addGeoJsonSource(_frameSeamSourceId, const {
        'type': 'FeatureCollection',
        'features': <Object>[],
      });
      await controller.addLineLayer(
        _frameSeamSourceId,
        frameSeamLayerId,
        const LineLayerProperties(lineOpacity: 0),
        belowLayerId: rasterBelowLayerId,
        enableInteraction: false,
      );
      _seamMounted = true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id frame seam');
    }
  }

  Future<void> _removeSeam(MapLibreMapController controller) async {
    if (!_seamMounted) return;
    _seamMounted = false;
    try {
      await controller.removeLayer(frameSeamLayerId);
    } catch (_) {}
    try {
      await controller.removeSource(_frameSeamSourceId);
    } catch (_) {}
  }

  (int, int, Set<String>) _ringAt(int index) {
    final low = (index - ringRadius).clamp(0, _orderedIds.length - 1);
    final high = (index + ringRadius).clamp(0, _orderedIds.length - 1);
    return (
      low,
      high,
      <String>{for (var i = low; i <= high; i++) _orderedIds[i]},
    );
  }

  /// Hides every ring member that fell outside [keep] and abandons any remaining
  /// tile HTTP. The source stays resident for a cheap nearby reversal until the
  /// LRU ceiling removes it.
  Future<void> _retireOutside(
    MapLibreMapController controller,
    Set<String> keep,
  ) async {
    final retired = [
      for (final id in _ring)
        if (!keep.contains(id)) id,
    ];
    if (retired.isEmpty) return;
    _ring.removeAll(retired);
    await controller.setLayerPropertiesBatch([
      for (final id in retired) (layerId: _layerId(id), properties: _hidden),
    ], skipNulls: true);
    await source.abandonFrames(retired);
  }

  /// The camera's visible region and zoom, re-read only when the camera moved.
  ///
  /// [CameraPosition] has value equality and is maintained on the Dart side
  /// from the camera-move stream, so the check is free and exact: any pan,
  /// zoom, rotation or tilt misses. The position compared is the one observed
  /// *before* the platform answered, so a camera that moved while the query was
  /// in flight invalidates the entry instead of serving a rectangle that never
  /// existed. [onCameraIdle] clears it too, which covers a surface resize —
  /// the same event already invalidates [_readyFrames] for the same reason.
  Future<({LatLngBounds bounds, double zoom})> _viewport(
    MapLibreMapController controller,
  ) async {
    final camera = controller.cameraPosition;
    final cached = _viewportCache;
    if (cached != null && _viewportCamera == camera) return cached;
    final viewport = (
      bounds: await controller.getVisibleRegion(),
      zoom: camera?.zoom ?? 8,
    );
    _viewportCamera = camera;
    _viewportCache = viewport;
    return viewport;
  }

  /// Whether [index] falls inside the band last warmed around [_warmCentre].
  bool _warmCovers(int index) {
    final centre = _warmCentre;
    if (centre == null || _orderedIds.isEmpty) return false;
    final low = (centre - warmRadius).clamp(0, _orderedIds.length - 1);
    final high = (centre + warmRadius).clamp(0, _orderedIds.length - 1);
    return index >= low && index <= high;
  }

  /// Pushes the viewport tiles of every frame from [centre] outward into
  /// MapLibre's memory, in **fill** mode: nearest-the-finger frames first, then
  /// ±1, ±2, … until the mirror is nearly full.
  ///
  /// Deliberately far wider than the mounted ring: warming costs one local read
  /// and a memory push — no draw call, no tile pass, no network — so the band
  /// that a drag can cross **without touching disk** is far cheaper to widen
  /// than the band kept mounted. Each re-centre replaces its L1 working set:
  /// frames outside the new spread are evicted before the reclaimed bytes fill
  /// centre-outward, which keeps the memory budget full of *nearby* tiles.
  Future<void> _warmBand(
    MapLibreMapController controller,
    int centre, {
    bool immediate = false,
    bool refreshResident = false,
  }) async {
    if (!_surfaceVisible || _orderedIds.isEmpty) return;
    // Adopt the new centre before the first await: concurrent scrub reveals
    // that cross the old band edge coalesce onto this one re-warm instead of
    // each firing its own visible-region round-trip.
    final previous = _warmCentre;
    if (previous == centre) return;
    _warmCentre = centre;
    final delta = previous == null ? 1 : centre - previous;
    final frames = _spreadFrames(centre, direction: delta < 0 ? -1 : 1);
    if (frames.length <= 1) return;
    final elapsed = Stopwatch()..start();
    MapTileCache.trace(
      () =>
          'timeline=$id warm-band start centre=$centre previous=$previous '
          'direction=${delta < 0 ? 'backward' : 'forward'} '
          'frames=${frames.length} immediate=$immediate '
          'refresh=$refreshResident',
    );
    try {
      final viewport = await _viewport(controller);
      // Visibility can change while the platform answers the camera query. Do
      // not start a fresh warmer generation after the hidden-edge cancellation.
      if (!_surfaceVisible || _warmCentre != centre) return;
      await source.warmFrameTiles(
        frames: frames,
        south: viewport.bounds.southwest.latitude,
        west: viewport.bounds.southwest.longitude,
        north: viewport.bounds.northeast.latitude,
        east: viewport.bounds.northeast.longitude,
        zoom: viewport.zoom,
        fill: true,
        immediate: immediate,
        refreshResident: refreshResident,
      );
      MapTileCache.trace(
        () =>
            'timeline=$id warm-band done centre=$centre frames=${frames.length} '
            'dt=${elapsed.elapsedMilliseconds}ms',
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id band warm');
    }
  }

  /// Frame ids ordered nearest-the-finger first: the centre, then ±1, ±2, …
  /// until [warmFrameBudget] candidates (or the series edge). Fill warm injects
  /// in this order and stops at the mirror cap, so when memory is tight the most
  /// distant frames are exactly the ones that stay cold.
  List<String> _spreadFrames(int centre, {required int direction}) =>
      _nearestFrames(centre, warmFrameBudget, direction: direction);

  List<String> _nearestFrames(int centre, int budget, {int direction = 1}) {
    final n = _orderedIds.length;
    final limit = budget < n ? budget : n;
    final result = <String>[];
    void add(int i) {
      if (result.length < limit && i >= 0 && i < n) {
        result.add(_orderedIds[i]);
      }
    }

    add(centre);
    for (var r = 1; result.length < limit && r < n; r++) {
      // The direction the finger last moved gets each distance's first slot.
      // Under a tight cap this keeps the likely next frame, not the equally
      // distant frame behind the gesture.
      add(centre + r * direction);
      add(centre - r * direction);
    }
    return result;
  }

  Future<void> _evictOverflow(
    MapLibreMapController controller, {
    required Set<String> keep,
  }) async {
    while (_lru.length > maxResident) {
      final evict = _lru.firstWhere(
        (candidate) => !keep.contains(candidate),
        orElse: () => '',
      );
      if (evict.isEmpty) break;
      _lru.remove(evict);
      _resident.remove(evict);
      _ring.remove(evict);
      _readyFrames.remove(evict);
      await _removeFrame(controller, evict);
      MapTileCache.trace(
        () =>
            'timeline=$id source-evict frame=$evict '
            'resident=${_resident.length}/$maxResident',
      );
    }
  }

  void _touch(String id) {
    _lru.remove(id);
    _lru.addLast(id);
  }

  @override
  void onMapIdle() {
    if (!_surfaceVisible || _ring.isEmpty) return;
    final newlyReady = _ring.difference(_readyFrames);
    if (newlyReady.isEmpty) return;
    _readyFrames.addAll(newlyReady);
    MapTileCache.trace(
      () =>
          'timeline=$id native-idle ready=${newlyReady.length} '
          'ring=${_ring.length}',
    );
  }

  @override
  void onTimelineScrubStart() => _suspendWarm();

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    if (!_surfaceVisible) return;
    // Native readiness is viewport-specific. Invalidate it even while a
    // timeline gesture has suspended warming; the next map-idle event will
    // prove the newly visible tiles instead of reusing the old viewport. The
    // cached rectangle goes with it: a resize keeps the camera and moves the
    // rectangle, and this is the event that reports it.
    _readyFrames.clear();
    _viewportCache = null;
    _viewportCamera = null;
    if (_warmSuspended) return;
    final centre = _shownIndex;
    if (centre == null) return;
    _warmCentre = null;
    // The viewport moved, so the warmed tiles are the wrong ones — re-warm for
    // where the camera actually is.
    MapTileCache.trace(() => 'timeline=$id camera-idle centre=$centre');
    unawaited(_warmBand(controller, centre, immediate: true));
  }

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {
    if (!_surfaceVisible) return;
    final centre = _shownIndex;
    if (centre == null) return;
    _warmCentre = null;
    await _warmBand(controller, centre, immediate: true);
  }

  int? get _shownIndex {
    final id = _shownFrameId;
    return id == null ? null : _indexById[id];
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _requestedFrameId = null;
    _revealGeneration++;
    _refreshResidentOnNextSettle = false;
    await _mutationTail;
    await source.releaseTiles();
    for (final id in List<String>.of(_resident)) {
      await _removeFrame(controller, id);
    }
    if (_attached) await onDetached(controller);
    await _removeSeam(controller);
    _reset();
    _mapController = null;
  }

  Future<void> _removeFrame(MapLibreMapController controller, String id) async {
    _readyFrames.remove(id);
    try {
      await controller.removeLayer(_layerId(id));
    } catch (_) {}
    try {
      await controller.removeSource(_sourceId(id));
    } catch (_) {}
  }

  @override
  void selectFeature(String id) {}

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _revealGeneration++;
    _warmSuspended = false;
    _resumeBackgroundWork = false;
    _resident.clear();
    _ring.clear();
    _readyFrames.clear();
    _viewportCache = null;
    _viewportCamera = null;
    _lru.clear();
    _orderedIds = const [];
    _indexById = const {};
    _requestedFrameId = null;
    _shownFrameId = null;
    _settledFrameId = null;
    _warmCentre = null;
    _attached = false;
    // A style reload drops every runtime layer, the seam included.
    _seamMounted = false;
    _seamMounting = null;
    _mapController = null;
  }
}

/// Decodes a frame id into its instant.
///
/// Ids are Unix seconds (or milliseconds — both are in use across endpoints);
/// an ISO-8601 string is accepted as a fallback. A versioned id may append
/// `@revision`: the timestamp before it remains the instant while the complete
/// string remains the cache identity. Memoised per complete id.
@visibleForTesting
DateTime parseFrameTime(String id) =>
    _frameTimeCache.putIfAbsent(id, () => _parse(id));

final Map<String, DateTime> _frameTimeCache = {};

DateTime _parse(String id) {
  final separator = id.indexOf('@');
  final timeId = separator < 0 ? id : id.substring(0, separator);
  final epoch = int.tryParse(timeId);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(timeId)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
