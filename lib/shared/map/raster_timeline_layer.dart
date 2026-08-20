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
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A time-scrubbable raster overlay driven by a [RasterFrameSource].
///
/// ## The problem this solves
/// Every frame is its own MapLibre source. Making one visible is what makes
/// MapLibre load its tiles — so a fast scrub that toggled `visibility` per
/// frame issued a fresh viewport of tile requests for every frame the finger
/// swept past, and abandoned them a moment later.
///
/// ## Three tiers
/// - **The ring** — frames within [ringRadius] are mounted **visible**, only
///   the current one at full [opacity] and its neighbours at zero. During a
///   drag, an L1-complete frame may join this set on demand; [maxResident]
///   bounds the extra sources. A frame replaces the current timestamp only
///   after [RasterFrameSource.frameTileReadiness] proves that one complete
///   viewport zoom is in L1.
/// - **The warm window** — frames within [warmRadius] were included in the last
///   local-cache attempt. L2 hits are pushed into MapLibre memory; L2 misses
///   remain cold and are never mislabeled as display-ready.
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

  /// Farthest a fill warm reaches from the current frame, in either direction.
  ///
  /// A cap on the spread, not a target: a fill warm injects centre → ±1 → ±2 …
  /// and stops at the native mirror's cap ([MapTileCache.defaultMemoryBytes]),
  /// so beyond this only the most distant cached frames are considered. A cold
  /// database is not scanned during a scrub; this wider fill runs on settle.
  @protected
  int get maxWarmRadius => 64;

  /// Mounted-source ceiling. Beyond this the least-recently-shown frame is
  /// removed outright — `visibility: none` keeps GPU textures for a fast
  /// reveal, so `removeSource` is the actual memory release.
  @protected
  int get maxResident => 32;

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

  /// Whether [frames] are all one forecast-model run — the API serves only the
  /// latest run, so the oldest frame is that run's issue time (資料時間).
  ///
  /// Observed layers (radar, satellite) leave this false; a wind-forecast
  /// layer opts in so the timeline can name when the model was run.
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

  @override
  void onSurfaceVisibility(bool visible) {}

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

  /// Polling finishes outside MapScaffold's serial reveal lane. Its final style
  /// mutation rejoins this queue so a newly requested frame and an older tile
  /// completion can never write opacities concurrently.
  Future<void> _mutationTail = Future<void>.value();
  bool _attached = false;

  static const Duration _readyPoll = Duration(milliseconds: 40);
  static const Duration _decodeGrace = Duration(milliseconds: 32);
  static const Duration _readyTimeout = Duration(seconds: 2);

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
    _orderedIds = [for (final frame in frames) frame.id];
    _indexById = {for (var i = 0; i < frames.length; i++) frames[i].id: i};
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) {
    final index = _indexById[frame.id];
    if (index == null) return Future<void>.value();
    if (scrubbing) {
      _suspendWarm();
    } else {
      final resumeWarm = _warmSuspended;
      _warmSuspended = false;
      if (_shownFrameId == frame.id && _settledFrameId == frame.id) {
        if (resumeWarm) {
          // A tap/short drag can finish on the same timestamp. Its first move
          // still cancelled the old fill, so restart one debounced fill here.
          _warmCentre = null;
          unawaited(_warmBand(controller, index));
        }
        return Future<void>.value();
      }
    }
    if (scrubbing && _requestedFrameId == frame.id) {
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
  /// The two writes go out **together**. Awaiting the hide before sending the
  /// show cost two serial platform round-trips per frame, which is the budget
  /// for the whole frame; pipelined they cost one, and MapLibre applies them in
  /// order within a single render pass, so no in-between state is ever drawn.
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

    await Future.wait([
      if (previous != null && previous != frameId)
        controller.setLayerProperties(
          _layerId(previous),
          _ring.contains(previous) ? _opacity(0) : _hidden,
          skipNulls: true,
        ),
      controller.setLayerProperties(
        _layerId(frameId),
        _opacity(opacity),
        skipNulls: true,
      ),
    ]);
    MapTileCache.trace(
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
      'timeline=$id settle start frame=$frameId index=$index '
      'ring=$low..$high shown=$_shownFrameId',
    );

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
    final bounds = await controller.getVisibleRegion();
    if (!_isCurrent(frameId, generation)) return;
    final zoom = controller.cameraPosition?.zoom ?? 8;
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
    MapTileCache.trace(
      'timeline=$id readiness frame=$frameId phase=initial '
      'ready=${readiness.ready} resident=${readiness.resident}/'
      '${readiness.required} zoom=${zoom.toStringAsFixed(2)} '
      'dt=${elapsed.elapsedMilliseconds}ms',
    );
    if (readiness.ready) {
      if (!settling && !_ring.contains(frameId)) {
        // Readiness was an L1-only probe. Mounting after it succeeds lets
        // MapLibre satisfy the display tiles entirely from memory; doing this
        // in the opposite order would start native tile requests for every
        // cold tick crossed by a fast finger.
        await _stageScrubFrame(controller, frameId);
        if (!_isCurrent(frameId, generation)) return;
      }
      // L1 residency means native owns the encoded bytes, not that MapLibre has
      // decoded and painted them. Even a ring member may have mounted only one
      // input event ago, so give every frame's *first* reveal two render turns;
      // later reversals use _readyFrames and stay immediate.
      await Future<void>.delayed(_decodeGrace);
      if (!_isCurrent(frameId, generation)) return;
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
    while (elapsed.elapsed < _readyTimeout && _isCurrent(frameId, generation)) {
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
      if (readiness.ready) break;
    }
    if (!_isCurrent(frameId, generation)) return;
    if (!readiness.ready) {
      MapTileCache.trace(
        'timeline=$id readiness frame=$frameId phase=timeout hold=$_shownFrameId '
        'resident=${readiness.resident}/${readiness.required} '
        'dt=${elapsed.elapsedMilliseconds}ms',
      );
      return;
    }
    // Network bytes enter L1 before MapLibre finishes decoding them. Keep the
    // complete previous frame for two render intervals, then cut over once.
    await Future<void>.delayed(_decodeGrace);
    if (!_isCurrent(frameId, generation)) return;
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
      'timeline=$id readiness frame=$frameId phase=ready '
      'resident=${readiness.resident}/${readiness.required} '
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
      'timeline=$id settle complete frame=$frameId mounted=${ring.length} '
      'schedule-warm=true',
    );
    // Use the warmer's debounce. A new gesture cancels this before its SQLite
    // batch starts; an immediate fill here was the dominant high-speed scrub
    // stall when users reversed direction just after finger-up.
    unawaited(_warmBand(controller, index));
  }

  void _suspendWarm() {
    if (_warmSuspended) return;
    _warmSuspended = true;
    _warmCentre = null;
    source.cancelTileWarm();
    MapTileCache.trace('timeline=$id warm-suspend');
  }

  bool _isCurrent(String frameId, int generation) =>
      generation == _revealGeneration && _requestedFrameId == frameId;

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
      'timeline=${this.id} mount frame=$id opacity=$value source=new',
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
    await Future.wait([
      for (final id in retired)
        controller.setLayerProperties(_layerId(id), _hidden, skipNulls: true),
    ]);
    await source.abandonFrames(retired);
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
  }) async {
    if (_orderedIds.isEmpty) return;
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
      'timeline=$id warm-band start centre=$centre previous=$previous '
      'direction=${delta < 0 ? 'backward' : 'forward'} '
      'frames=${frames.length} immediate=$immediate',
    );
    try {
      final bounds = await controller.getVisibleRegion();
      await source.warmFrameTiles(
        frames: frames,
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: controller.cameraPosition?.zoom ?? 8,
        fill: true,
        immediate: immediate,
      );
      MapTileCache.trace(
        'timeline=$id warm-band done centre=$centre frames=${frames.length} '
        'dt=${elapsed.elapsedMilliseconds}ms',
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id band warm');
    }
  }

  /// Frame ids ordered nearest-the-finger first: the centre, then ±1, ±2, …
  /// out to [maxWarmRadius] (or the series edge). Fill warm injects in this
  /// order and stops at the mirror cap, so when memory is tight the most
  /// distant frames are exactly the ones that stay cold.
  List<String> _spreadFrames(int centre, {required int direction}) {
    final n = _orderedIds.length;
    final result = <String>[];
    void add(int i) {
      if (i >= 0 && i < n) result.add(_orderedIds[i]);
    }

    add(centre);
    for (var r = 1; r <= maxWarmRadius; r++) {
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
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    if (_warmSuspended) return;
    final centre = _shownIndex;
    if (centre == null) return;
    _readyFrames.clear();
    _warmCentre = null;
    // The viewport moved, so the warmed tiles are the wrong ones — re-warm for
    // where the camera actually is.
    MapTileCache.trace('timeline=$id camera-idle centre=$centre');
    unawaited(_warmBand(controller, centre, immediate: true));
  }

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {
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
    await _mutationTail;
    await source.releaseTiles();
    for (final id in List<String>.of(_resident)) {
      await _removeFrame(controller, id);
    }
    if (_attached) await onDetached(controller);
    await _removeSeam(controller);
    _reset();
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
    _resident.clear();
    _ring.clear();
    _readyFrames.clear();
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
  }
}

/// Decodes a frame id into its instant.
///
/// Ids are Unix seconds (or milliseconds — both are in use across endpoints);
/// an ISO-8601 string is accepted as a fallback. Memoised per id: the ids are
/// globally unique (timestamps), so a re-parse — every time a layer reloads
/// its frames — is pure waste.
@visibleForTesting
DateTime parseFrameTime(String id) =>
    _frameTimeCache.putIfAbsent(id, () => _parse(id));

final Map<String, DateTime> _frameTimeCache = {};

DateTime _parse(String id) {
  final epoch = int.tryParse(id);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(id)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
