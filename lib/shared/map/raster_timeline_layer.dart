/// Shared machinery for scrubbable raster overlays (radar echo, satellite IR).
library;

import 'dart:async';
import 'dart:collection';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
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
/// ## The preload ring
/// The frames within [ringRadius] of the current one are all mounted
/// **visible**, with only the current one at full [opacity] and its neighbours
/// at zero. Their tiles are therefore already loaded and resident on the GPU,
/// and scrubbing across the ring is a pure opacity flip — two property sets,
/// **zero** tile requests, no `addSource`, no cancels. That is the only thing
/// that keeps up with a finger.
///
/// Outside the ring, residents drop to `visibility: none`, which stops them
/// both drawing and loading. A cold frame reached mid-drag is simply not shown
/// (the painted frame stays, the timeline label still moves); the next settle
/// re-centres the ring on wherever the finger stopped.
///
/// ## Settling
/// A settle reveals the target first (it is what the user is waiting for), then
/// retires everything outside the new ring — abandoning those frames' in-flight
/// HTTP through [RasterFrameSource.abandonFrames], scoped so the basemap and the
/// target keep loading. Only then does it warm the new neighbours out of the
/// app's tile store into MapLibre's memory and mount them transparent, so the
/// next scrub across them touches neither disk nor network.
abstract class RasterTimelineLayer implements MapLayer {
  RasterTimelineLayer(this.source);

  /// Frames, tile URLs, and tile-memory control for this overlay.
  @protected
  final RasterFrameSource source;

  /// Opacity of the frame currently under the scrubber.
  @protected
  double get opacity;

  /// How many frames either side of the current one are kept preloaded.
  ///
  /// Wider = more of a scrub is a free opacity flip, at one raster draw call and
  /// one viewport of tiles per extra frame.
  @protected
  int get ringRadius => 2;

  /// Mounted-source ceiling. Beyond this the least-recently-shown frame is
  /// removed outright — `visibility: none` keeps GPU textures for a fast
  /// reveal, so `removeSource` is the actual memory release.
  @protected
  int get maxResident => 16;

  /// Hook for extra style work once this layer's first frame is on the map
  /// (e.g. an outline layer that only makes sense over this overlay).
  @protected
  Future<void> onAttached(MapLibreMapController controller) async {}

  /// Undoes [onAttached]. Called from [clear].
  @protected
  Future<void> onDetached(MapLibreMapController controller) async {}

  // --- MapLayer surface a raster timeline never varies -----------------------

  @override
  bool get usesTimeline => true;

  @override
  double get bottomChromeFraction => 0;

  @override
  double get mapMinZoom => 4;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  String? get bakedAedTileUrl => null;

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
  Widget buildTopTrailingChrome(BuildContext context) =>
      const SizedBox.shrink();

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

  /// Guards the scrub hot path: a flip that lost the race must not repaint.
  int _flipGeneration = 0;

  String _sourceId(String frameId) => '$id-src-$frameId';
  String _layerId(String frameId) => '$id-lyr-$frameId';

  RasterLayerProperties _visibleAt(double value) =>
      RasterLayerProperties(visibility: 'visible', rasterOpacity: value);

  static const RasterLayerProperties _hidden = RasterLayerProperties(
    visibility: 'none',
    rasterOpacity: 0,
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
    // Cold mid-drag — keep the painted frame rather than starting a tile load
    // the finger is about to abandon. The settle below picks it up.
    if (scrubbing) return;
    await _settle(controller, index, frame.id);
  }

  /// Scrub hot path — never mounts, never cancels, never touches `visibility`.
  Future<void> _flip(MapLibreMapController controller, String frameId) async {
    final generation = ++_flipGeneration;
    final previous = _shownFrameId;
    _shownFrameId = frameId;
    _touch(frameId);

    if (previous != null && previous != frameId && _ring.contains(previous)) {
      // Stays `visible` at zero opacity: dropping it to `none` would evict its
      // tiles and make scrubbing back a reload.
      await controller.setLayerProperties(_layerId(previous), _visibleAt(0));
    }
    if (generation != _flipGeneration) return;
    await controller.setLayerProperties(_layerId(frameId), _visibleAt(opacity));
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
    _shownFrameId = frameId;
    _flipGeneration++;
    if (!_attached) {
      _attached = true;
      await onAttached(controller);
    }

    await _retireOutside(controller, ring);
    await _warmRing(controller, ring);

    for (final id in ring) {
      if (id == frameId) continue;
      await _mount(controller, id, 0);
    }
    await _evictOverflow(controller, keep: ring);
  }

  /// Mounts [id] if cold, then sets its opacity. Always leaves it `visible`, so
  /// MapLibre keeps its tiles loaded.
  Future<void> _mount(
    MapLibreMapController controller,
    String id,
    double value,
  ) async {
    _touch(id);
    _ring.add(id);
    if (_resident.contains(id)) {
      await controller.setLayerProperties(_layerId(id), _visibleAt(value));
      return;
    }
    await controller.addSource(
      _sourceId(id),
      RasterSourceProperties(tiles: [source.tileUrl(id)], tileSize: 256),
    );
    await controller.addRasterLayer(
      _sourceId(id),
      _layerId(id),
      _visibleAt(value),
      belowLayerId: outlineLayerId,
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
        controller.setLayerProperties(_layerId(id), _hidden),
    ]);
    await source.abandonFrames(retired);
  }

  /// Reads the ring's viewport tiles out of the app's store and injects them
  /// into MapLibre's memory, so mounting them next is I/O-free.
  Future<void> _warmRing(
    MapLibreMapController controller,
    Set<String> ring,
  ) async {
    try {
      final bounds = await controller.getVisibleRegion();
      await source.warmFrameTiles(
        frames: ring.toList(growable: false),
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: controller.cameraPosition?.zoom ?? 8,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, '$id ring warm');
    }
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
    if (_ring.isEmpty) return;
    // The viewport moved, so the ring's warmed tiles are the wrong ones —
    // re-warm for where the camera actually is.
    unawaited(_warmRing(controller, Set<String>.of(_ring)));
  }

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {
    if (_ring.isEmpty) return;
    await _warmRing(controller, Set<String>.of(_ring));
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
  void onStyleReset() => _reset();

  void _reset() {
    _resident.clear();
    _ring.clear();
    _lru.clear();
    _orderedIds = const [];
    _indexById = const {};
    _shownFrameId = null;
    _flipGeneration = 0;
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
