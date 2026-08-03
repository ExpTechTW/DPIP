import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The satellite IR cloud (衛星雲圖) raster [MapLayer] — same single-source scrub
/// as [RadarMapLayer], backed by the v2 Himawari XYZ WebP tiles.
///
/// IR tiles already encode clear-sky as transparent (alpha = coldness), so the
/// drawn opacity is 1.0 — unlike the opaque radar palette.
class SatelliteMapLayer implements MapLayer {
  SatelliteMapLayer(this._repository);

  final SatelliteRepository _repository;

  @override
  String get id => 'satellite';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerSatellite;

  @override
  IconData get icon => Icons.satellite_alt_outlined;

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
      Log.handle(error, stackTrace, 'satellite viewport prefetch');
    }
  }

  /// Himawari Band-13 brightness temperature — cold white / warm black
  /// (180–300 K), matching the tile renderer.
  @override
  Widget buildLegend(BuildContext context) => const MapLegendCard(
    child: ColorScaleLegend(
      unit: 'K',
      stops: [
        (180, '#FFFFFF'),
        (210, '#CCCCCC'),
        (240, '#888888'),
        (270, '#444444'),
        (300, '#000000'),
      ],
    ),
  );

  static const double _opacity = 1;

  static const String _sourceId = 'satellite-src';
  static const String _layerId = 'satellite-lyr';

  static const RasterLayerProperties _shown = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: _opacity,
  );

  Map<String, int> _indexById = const {};
  String? _shownFrameId;
  bool _mounted = false;
  bool _blackOutlineOnMap = false;

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
    // Below the themed county outline; the black IR outline sits on top
    // of both (see [_ensureBlackOutline]).
    await controller.addRasterLayer(
      _sourceId,
      _layerId,
      _shown,
      belowLayerId: outlineLayerId,
    );
    _mounted = true;
    await _ensureBlackOutline(controller);
    _shownFrameId = frame.id;
  }

  /// Black land borders above the IR stack — `global` for every country, then
  /// `city` for Taiwan counties. Greyscale tiles wash out the themed outline.
  Future<void> _ensureBlackOutline(MapLibreMapController controller) async {
    if (_blackOutlineOnMap) return;
    try {
      await controller.addLineLayer(
        'exptech',
        satelliteGlobalOutlineLayerId,
        const LineLayerProperties(
          lineColor: satelliteOutlineColor,
          lineWidth: 1.0,
        ),
        sourceLayer: 'global',
        enableInteraction: false,
      );
      await controller.addLineLayer(
        'exptech',
        satelliteCountyOutlineLayerId,
        const LineLayerProperties(
          lineColor: satelliteOutlineColor,
          lineWidth: 1.0,
        ),
        sourceLayer: 'city',
        enableInteraction: false,
      );
      _blackOutlineOnMap = true;
    } catch (_) {
      // Style mid-reload — next show() retries. Drop a partial add.
      await _removeBlackOutline(controller);
    }
  }

  Future<void> _removeBlackOutline(MapLibreMapController controller) async {
    for (final id in [
      satelliteCountyOutlineLayerId,
      satelliteGlobalOutlineLayerId,
    ]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {
        // Already gone with the style.
      }
    }
    _blackOutlineOnMap = false;
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    await cancelMapLibreTileFetches();
    if (_mounted) {
      await _removeMounted(controller);
    }
    await _removeBlackOutline(controller);
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
    _blackOutlineOnMap = false;
  }
}

/// Decodes a satellite frame id — an ExpTech Unix timestamp — into wall-clock
/// time. Accepts milliseconds (13-digit) or seconds (10-digit) by magnitude.
DateTime _parseFrameTime(String id) {
  final epoch = int.tryParse(id);
  if (epoch != null) {
    final ms = epoch >= 1000000000000 ? epoch : epoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
  return DateTime.tryParse(id)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
