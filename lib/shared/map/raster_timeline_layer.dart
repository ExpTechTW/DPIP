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
///   the current one at full [opacity] and its neighbours at zero. Their tiles
///   are already loaded and on the GPU, so scrubbing across them is a pure
///   opacity flip: two property sets, **zero** tile requests, no `addSource`,
///   no cancels. That is the only thing that keeps up with a finger.
/// - **The warm band** — frames within [warmRadius] have their tiles pushed
///   into MapLibre's memory but are not mounted. Revealing one costs a mount,
///   but no disk and no network.
/// - **Cold** — anything further out. Revealing it mounts and loads normally.
///
/// A drag reveals whichever tier the frame is in; only the ring is free, but
/// none of them stall. (Cold frames used to be skipped outright while the
/// finger was down, which froze the map until release — see [_revealBeyondRing]
/// for why that is no longer necessary.) Frames outside the ring sit at
/// `visibility: none`, which stops them both drawing and loading.
///
/// ## Settling
/// A settle reveals the target first (it is what the user is waiting for), then
/// retires everything outside the new ring — abandoning those frames' in-flight
/// HTTP through [RasterFrameSource.abandonFrames], scoped so the basemap and the
/// target keep loading. Only then does it re-warm the band and mount the new
/// neighbours transparent, so the next drag across them touches neither disk
/// nor network.
abstract class RasterTimelineLayer implements MapLayer {
  RasterTimelineLayer(this.source);

  /// Frames, tile URLs, and tile-memory control for this overlay.
  @protected
  final RasterFrameSource source;

  /// Opacity of the frame currently under the scrubber.
  @protected
  double get opacity;

  /// How many frames either side of the current one are kept **mounted and
  /// drawn** (transparent), so scrubbing onto them is a pure opacity flip.
  ///
  /// Each extra frame costs a raster draw call every rendered frame plus a
  /// viewport of loaded tiles, so this stays small — [warmRadius] is the cheap
  /// way to widen the range a drag handles smoothly.
  @protected
  int get ringRadius => 2;

  /// How many frames either side have their tiles pushed into MapLibre's
  /// memory ahead of demand.
  ///
  /// This is the **guaranteed** band: [fill] warm always covers it. Beyond it,
  /// [MapTileCache.warm]'s fill mode keeps topping the mirror up outward from
  /// the current frame until it is nearly full — the actual reach is set by
  /// the memory cap, not by taste, so a 48 MB mirror easily covers far more.
  @protected
  int get warmRadius => 4;

  /// Farthest a fill warm reaches from the current frame, in either direction.
  ///
  /// A cap on the spread, not a target: a fill warm injects centre → ±1 → ±2 …
  /// and stops at the native mirror's cap ([MapTileCache.defaultMemoryBytes]),
  /// so beyond this only the most distant frames stay cold. Sized to what a
  /// 48 MB mirror can actually hold — a radar frame's viewport is roughly
  /// 100–400 KB of webp, so a ±64 band is a believable full-mirror working set
  /// rather than a number that silently under-fills the new budget.
  @protected
  int get maxWarmRadius => 64;

  /// Mounted-source ceiling. Beyond this the least-recently-shown frame is
  /// removed outright — `visibility: none` keeps GPU textures for a fast
  /// reveal, so `removeSource` is the actual memory release.
  @protected
  int get maxResident => 16;

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
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  // --- Frame bookkeeping -----------------------------------------------------

  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};

  /// Frames with a source + layer on the map.
  final Set<String> _resident = <String>{};

  /// The preload ring: residents currently `visibility: visible`. A scrub onto
  /// any of these is an opacity flip.
  final Set<String> _ring = <String>{};

  /// Least-recently-shown first, for [maxResident] eviction.
  final Queue<String> _lru = Queue<String>();

  String? _shownFrameId;
  bool _attached = false;

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
  }) async {
    if (_shownFrameId == frame.id) return;
    final index = _indexById[frame.id];
    if (index == null) return;

    // Hot path: already in the preload ring, so its tiles are loaded and this
    // is nothing but two opacity writes.
    if (_ring.contains(frame.id)) {
      await _flip(controller, frame.id);
      return;
    }
    // Past the ring, still dragging: reveal it anyway. Re-centring the ring
    // here would cost a retire + warm + a mount per neighbour, so that waits
    // for the settle.
    if (scrubbing) {
      await _revealBeyondRing(controller, frame.id);
      return;
    }
    await _settle(controller, index, frame.id);
  }

  /// Reveals a frame the preload ring does not cover, mid-drag.
  ///
  /// Dragging past the ring used to do **nothing** until the finger came up:
  /// mounting costs two platform calls plus a tile pass, and back when the
  /// scaffold fired one unawaited reveal per frame crossed, doing that mid-drag
  /// meant a request storm. It no longer does — reveals are driven latest-wins
  /// with a single op in flight, so the cost is bounded to the frames the drag
  /// actually lands on rather than every frame it sweeps over, and the warm band
  /// ([warmRadius]) usually has their tiles in MapLibre's memory already.
  Future<void> _revealBeyondRing(
    MapLibreMapController controller,
    String frameId,
  ) async {
    final previous = _shownFrameId;
    _shownFrameId = frameId;

    await Future.wait([
      if (previous != null && previous != frameId)
        controller.setLayerProperties(
          _layerId(previous),
          // A ring member only fades out — it keeps its tiles for the next
          // flip. Anything else stops drawing *and* loading outright, so a long
          // drag can't leave a trail of live sources behind it.
          _ring.contains(previous) ? _opacity(0) : _hidden,
          skipNulls: true,
        ),
      _mount(controller, frameId, opacity),
    ]);
    await _evictOverflow(controller, keep: {..._ring, frameId});

    // The warm band follows the finger: revealing a frame the last-warmed band
    // did not cover re-warms around it, so the rest of a long drag stays on
    // memory hits instead of re-reading every mount from the store. Warmed
    // frames only cost the debounced local read + push in [warmFrameTiles] —
    // nothing drawn, nothing loaded — so this is the cheap tier to keep ahead
    // of the finger.
    final index = _indexById[frameId];
    if (index != null && !_warmCovers(index)) {
      unawaited(_warmBand(controller, index));
    }
  }

  /// Scrub hot path — never mounts, never cancels, rarely touches `visibility`.
  ///
  /// The two writes go out **together**. Awaiting the hide before sending the
  /// show cost two serial platform round-trips per frame, which is the budget
  /// for the whole frame; pipelined they cost one, and MapLibre applies them in
  /// order within a single render pass, so no in-between state is ever drawn.
  ///
  /// The previous frame is hidden either way. A ring member only fades out —
  /// dropping it to `none` would evict its tiles and make scrubbing back a
  /// reload — but a frame revealed mid-drag sits **outside** the ring, and
  /// leaving it at full opacity while the scrub bounces back over it ghosts
  /// the old frame behind the ring (`visibility: none` hides it outright).
  Future<void> _flip(MapLibreMapController controller, String frameId) async {
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
  }

  /// Re-centres the preload ring on [frameId] and reveals it.
  Future<void> _settle(
    MapLibreMapController controller,
    int index,
    String frameId,
  ) async {
    final low = (index - ringRadius).clamp(0, _orderedIds.length - 1);
    final high = (index + ringRadius).clamp(0, _orderedIds.length - 1);
    final ring = <String>{for (var i = low; i <= high; i++) _orderedIds[i]};

    // The target first — it is what the user stopped on.
    await _mount(controller, frameId, opacity);
    _ring.add(frameId);
    _shownFrameId = frameId;
    if (!_attached) {
      _attached = true;
      await onAttached(controller);
    }

    await _retireOutside(controller, ring);
    await _warmBand(controller, index);

    for (final id in ring) {
      if (id == frameId) continue;
      await _mount(controller, id, 0);
      _ring.add(id);
    }
    await _evictOverflow(controller, keep: ring);
  }

  /// Mounts [id] if cold, then draws it at [value]. Always leaves it `visible`,
  /// so MapLibre keeps its tiles loaded.
  ///
  /// Ring membership is the caller's call: a settle mounts its neighbours *into*
  /// the ring, a mid-drag reveal deliberately does not, so the ring stays the
  /// size [ringRadius] says and a long drag doesn't accumulate live sources.
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
    await controller.addSource(
      _sourceId(id),
      RasterSourceProperties(tiles: [source.tileUrl(id)], tileSize: 256),
    );
    await controller.addRasterLayer(
      _sourceId(id),
      _layerId(id),
      _mountPaint(value),
      belowLayerId: rasterBelowLayerId,
    );
    _resident.add(id);
  }

  /// Hides every ring member that fell outside [keep] and abandons their tile
  /// HTTP — the scrub swept past them and those bytes will never be drawn.
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
  /// than the band kept mounted. The mirror's LRU evicts the frames the scrub
  /// left behind (a fill warm reads without bumping recency, so old frames
  /// lose to new ones), which keeps the memory budget full of *nearby* tiles.
  Future<void> _warmBand(MapLibreMapController controller, int centre) async {
    if (_orderedIds.isEmpty) return;
    // Adopt the new centre before the first await: concurrent scrub reveals
    // that cross the old band edge coalesce onto this one re-warm instead of
    // each firing its own visible-region round-trip.
    _warmCentre = centre;
    final frames = _spreadFrames(centre);
    if (frames.length <= 1) return;
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
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id band warm');
    }
  }

  /// Frame ids ordered nearest-the-finger first: the centre, then ±1, ±2, …
  /// out to [maxWarmRadius] (or the series edge). Fill warm injects in this
  /// order and stops at the mirror cap, so when memory is tight the most
  /// distant frames are exactly the ones that stay cold.
  List<String> _spreadFrames(int centre) {
    final n = _orderedIds.length;
    final result = <String>[];
    void add(int i) {
      if (i >= 0 && i < n) result.add(_orderedIds[i]);
    }

    add(centre);
    for (var r = 1; r <= maxWarmRadius; r++) {
      add(centre + r);
      add(centre - r);
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
      await _removeFrame(controller, evict);
    }
  }

  void _touch(String id) {
    _lru.remove(id);
    _lru.addLast(id);
  }

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    final centre = _shownIndex;
    if (centre == null) return;
    // The viewport moved, so the warmed tiles are the wrong ones — re-warm for
    // where the camera actually is.
    unawaited(_warmBand(controller, centre));
  }

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {
    final centre = _shownIndex;
    if (centre == null) return;
    await _warmBand(controller, centre);
  }

  int? get _shownIndex {
    final id = _shownFrameId;
    return id == null ? null : _indexById[id];
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await source.releaseTiles();
    for (final id in List<String>.of(_resident)) {
      await _removeFrame(controller, id);
    }
    if (_attached) await onDetached(controller);
    _reset();
  }

  Future<void> _removeFrame(MapLibreMapController controller, String id) async {
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
    _resident.clear();
    _ring.clear();
    _lru.clear();
    _orderedIds = const [];
    _indexById = const {};
    _shownFrameId = null;
    _warmCentre = null;
    _attached = false;
  }
}

/// Decodes a frame id into its instant.
///
/// Ids are Unix seconds (or milliseconds — both are in use across endpoints);
/// an ISO-8601 string is accepted as a fallback.
@visibleForTesting
DateTime parseFrameTime(String id) {
  final epoch = int.tryParse(id);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(id)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
