import 'dart:async';
import 'dart:collection';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster [MapLayer].
///
/// ## Hot path (scrub GIF)
/// Resident frame already on the map → **two** `setLayerProperties` calls
/// (`prev` → `visibility: none`, `curr` → visible). No `cancelPendingFetches`,
/// no remove/addSource, no tile reload. That is the only path that can keep up
/// with the timeline finger.
///
/// ## Why remount felt "cached but stuttery"
/// removeLayer + removeSource + addSource + addRasterLayer is ≥4 MethodChannel
/// round-trips, then MapLibre re-enters the full tile pipeline for the viewport
/// (URLProtocol → get/mem → decode → upload) even when bytes are cached. That
/// dominates; SQLite/mem hits do not make remount free.
///
/// ## Cold / settle
/// Mount current ±[_settleRadius], then [_hideAllExcept] so LRU leftovers cannot
/// stay composited. Evict past [_maxResident]. `visibility: none` keeps GPU
/// textures for fast reveal (intentional); removeSource is the memory release.
class RadarMapLayer implements MapLayer {
  RadarMapLayer(this._repository);

  final RadarRepository _repository;

  @override
  String get id => 'radar';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRadar;

  @override
  IconData get icon => Icons.radar_outlined;

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

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    final id = _shownFrameId;
    if (id == null) return;
    unawaited(_warmFrames(controller, [id]));
  }

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {
    final id = _shownFrameId;
    if (id == null) return;
    await _warmFrames(controller, [id]);
  }

  Future<void> _warmFrames(
    MapLibreMapController controller,
    List<String> frames,
  ) async {
    try {
      final bounds = await controller.getVisibleRegion();
      final zoom = controller.cameraPosition?.zoom ?? 8;
      await _repository.prefetchFrameTiles(
        frames: frames,
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'radar viewport prefetch');
    }
  }

  @override
  Widget buildLegend(BuildContext context) => const MapLegendCard(
    child: ColorScaleLegend(
      unit: 'dBZ',
      stops: [
        (0, '#00FFFF'),
        (5, '#00A3FF'),
        (10, '#005BFF'),
        (15, '#0000FF'),
        (20, '#00D300'),
        (25, '#00A000'),
        (30, '#CCEA00'),
        (35, '#FFD300'),
        (40, '#FF8800'),
        (45, '#FF1800'),
        (50, '#D30000'),
        (55, '#A00000'),
        (60, '#EA00CC'),
        (65, '#9600FF'),
      ],
    ),
  );

  static const double _opacity = 0.85;
  static const int _settleRadius = 1;
  static const int _maxResident = 17;

  static const RasterLayerProperties _hidden = RasterLayerProperties(
    visibility: 'none',
    rasterOpacity: 0,
  );
  static const RasterLayerProperties _shown = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: _opacity,
  );

  String _sourceId(String frameId) => 'radar-src-$frameId';
  String _layerId(String frameId) => 'radar-lyr-$frameId';

  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};
  final Set<String> _resident = <String>{};
  final Queue<String> _lru = Queue<String>();
  String? _shownFrameId;
  int _revealGen = 0;

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await _repository.frames();
    return result.map(
      (raw) =>
          [for (final id in raw) MapFrame(id: id, time: _parseFrameTime(id))]
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

    // Hot path — already resident.
    if (_resident.contains(frame.id)) {
      await _reveal(controller, frame.id);
      return;
    }

    if (scrubbing) return; // cold mid-drag — wait for settle

    final lo = (index - _settleRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _settleRadius).clamp(0, _orderedIds.length - 1);
    final must = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    await _ensureMounted(controller, frame.id, visible: true);
    for (final id in must) {
      if (id == frame.id) continue;
      await _ensureMounted(controller, id, visible: false);
    }
    // One O(n) pass only on settle — clears any prior full-opacity leftovers.
    await _hideAllExcept(controller, frame.id);
    _shownFrameId = frame.id;
    await _evictOverflow(controller, keep: must);
  }

  /// Scrub hot path: ≤2 MethodChannel calls. Never cancel/remount.
  Future<void> _reveal(MapLibreMapController controller, String frameId) async {
    final gen = ++_revealGen;
    final prev = _shownFrameId;
    _shownFrameId = frameId;
    _touch(frameId);

    if (prev != null && prev != frameId && _resident.contains(prev)) {
      await controller.setLayerProperties(_layerId(prev), _hidden);
    }
    if (gen != _revealGen) return;
    await controller.setLayerProperties(_layerId(frameId), _shown);
  }

  Future<void> _ensureMounted(
    MapLibreMapController controller,
    String id, {
    required bool visible,
  }) async {
    final properties = visible ? _shown : _hidden;
    if (_resident.contains(id)) {
      await controller.setLayerProperties(_layerId(id), properties);
      _touch(id);
      return;
    }
    await controller.addSource(
      _sourceId(id),
      RasterSourceProperties(
        tiles: [_repository.tileUrl(id)],
        tileSize: 256,
      ),
    );
    await controller.addRasterLayer(
      _sourceId(id),
      _layerId(id),
      properties,
      belowLayerId: outlineLayerId,
    );
    _resident.add(id);
    _touch(id);
  }

  Future<void> _hideAllExcept(
    MapLibreMapController controller,
    String keepId,
  ) async {
    final ops = <Future<void>>[
      for (final id in _resident)
        if (id != keepId)
          controller.setLayerProperties(_layerId(id), _hidden),
    ];
    if (ops.isNotEmpty) await Future.wait(ops);
  }

  Future<void> _evictOverflow(
    MapLibreMapController controller, {
    required Set<String> keep,
  }) async {
    while (_lru.length > _maxResident) {
      final evict = _lru.firstWhere(
        (id) => !keep.contains(id),
        orElse: () => '',
      );
      if (evict.isEmpty) break;
      _lru.remove(evict);
      _resident.remove(evict);
      await _removeFrame(controller, evict);
    }
  }

  void _touch(String id) {
    _lru.remove(id);
    _lru.addLast(id);
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();
    for (final id in List<String>.of(_resident)) {
      await _removeFrame(controller, id);
    }
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
    _lru.clear();
    _orderedIds = const [];
    _indexById = const {};
    _shownFrameId = null;
    _revealGen = 0;
  }
}

DateTime _parseFrameTime(String id) {
  final epoch = int.tryParse(id);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(id)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
