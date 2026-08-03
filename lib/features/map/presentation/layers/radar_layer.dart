import 'dart:async';

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
/// Scrub strategy (GIF without tile storms):
/// - **Settle** mounts a small window (current ±[_settleRadius]) as MapLibre
///   sources — neighbours sit at opacity 0 so a scrub onto them is instant.
/// - **During scrub**, only opacity-switch among already-resident frames; a
///   cold frame is ignored until the next settle (label still moves). That
///   way a fast drag never addSources abandoned viewports into URLSession.
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

  /// Neighbours mounted on settle so scrubbing across them is an opacity flip.
  /// Wider = smoother GIF; each frame is one MapLibre source (~viewport tiles).
  static const int _settleRadius = 8;

  static const RasterLayerProperties _hidden = RasterLayerProperties(
    visibility: 'visible',
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
  String? _shownFrameId;

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

    // Already on the map → GIF via opacity only (no HTTP).
    if (_resident.contains(frame.id)) {
      await _reveal(controller, frame.id);
      return;
    }

    // Cold frame while dragging — keep the last resident painted. Settle loads.
    if (scrubbing) return;

    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();

    final lo = (index - _settleRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _settleRadius).clamp(0, _orderedIds.length - 1);
    final window = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    for (final id in _resident.difference(window)) {
      await _removeFrame(controller, id);
      _resident.remove(id);
    }

    for (final id in window) {
      final properties = id == frame.id ? _shown : _hidden;
      if (_resident.contains(id)) {
        await controller.setLayerProperties(_layerId(id), properties);
      } else {
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
      }
    }
    _shownFrameId = frame.id;
  }

  Future<void> _reveal(MapLibreMapController controller, String frameId) async {
    final prev = _shownFrameId;
    // Flip immediately so a superseded scrub tick can early-return on the new id.
    _shownFrameId = frameId;
    // Only touch the two layers that change — N awaits over the whole resident
    // set was the scrub stutter (each setLayerProperties is a platform hop).
    if (prev != null && prev != frameId && _resident.contains(prev)) {
      await controller.setLayerProperties(_layerId(prev), _hidden);
    }
    if (_shownFrameId != frameId) return; // superseded mid-await
    await controller.setLayerProperties(_layerId(frameId), _shown);
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();
    for (final id in _resident) {
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
    _orderedIds = const [];
    _indexById = const {};
    _shownFrameId = null;
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
