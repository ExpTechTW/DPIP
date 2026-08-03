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

/// The radar echo (雷達回波) raster [MapLayer] — the first concrete layer on the
/// shared map.
///
/// The whole history the API serves (~a week of 10-min frames) is scrubbable.
/// The map holds **one** raster source: each [show] cancels in-flight tile HTTP,
/// swaps that source's URL, then remounts. Scrub therefore animates like a GIF
/// (scaffold coalesces to the latest frame while a swap runs) without stacking
/// thousands of LocalDataTasks from abandoned frames.
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

  // The scaffold owns the timeline panel and measures its real height, so this
  // layer declares nothing of its own.
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

  /// CWA radar reflectivity (dBZ) — same stops as legacy's radar ColorLegend.
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

  /// Fixed ids — one source on the map; frame changes rewrite its tile URL.
  static const String _sourceId = 'radar-src';
  static const String _layerId = 'radar-lyr';

  static const RasterLayerProperties _shown = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: _opacity,
  );

  Map<String, int> _indexById = const {};

  String? _shownFrameId;
  bool _mounted = false;

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
    _indexById = {for (var i = 0; i < frames.length; i++) frames[i].id: i};
  }

  @override
  Future<void> show(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    if (_indexById[frame.id] == null) return;

    // Drop abandoned-frame HTTP before remount — removeSource alone does not.
    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();

    if (_mounted) {
      await _removeMounted(controller);
      _mounted = false;
    }

    await controller.addSource(
      _sourceId,
      RasterSourceProperties(
        tiles: [_repository.tileUrl(frame.id)],
        tileSize: 256,
      ),
    );
    await controller.addRasterLayer(
      _sourceId,
      _layerId,
      _shown,
      belowLayerId: outlineLayerId,
    );
    _mounted = true;
    _shownFrameId = frame.id;
    // Warm only after camera settles — scrub show is already the network path.
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();
    if (_mounted) {
      await _removeMounted(controller);
    }
    _reset();
  }

  Future<void> _removeMounted(MapLibreMapController controller) async {
    try {
      await controller.removeLayer(_layerId);
    } catch (_) {}
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {}
  }

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _indexById = const {};
    _shownFrameId = null;
    _mounted = false;
  }
}

/// Decodes a radar frame id — an ExpTech Unix timestamp — into a wall-clock time
/// for the timeline label. Accepts milliseconds (13-digit) or seconds (10-digit)
/// by magnitude, and falls back to an ISO string; an unparseable id maps to the
/// epoch — the frame still renders, only its label is off.
DateTime _parseFrameTime(String id) {
  final epoch = int.tryParse(id);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(id)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
