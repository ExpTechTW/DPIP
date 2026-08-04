/// Disaster-prevention map layer — MVT overlays (AED today) added at runtime,
/// with a typhoon-style tune menu; tap → detail sheet.
library;

import 'dart:async';
import 'dart:math' show Point;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/map/presentation/widgets/aed_sheet.dart';
import 'package:dpip/features/map/presentation/widgets/disaster_map_overlay_menu.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Sheet-driven [MapLayer] for the disaster-prevention map (DPM).
///
/// Switcher entry is 「防災地圖」; [DisasterMapOverlayMenu] toggles sub-layers
/// (AED for now). AED MVT is added with [addSource] / [addCircleLayer] on
/// [render] (baking into the base style JSON was a silent no-op / race on
/// style reload). Detail on tap via [DisasterMapRepository.aedDetail].
class DisasterMapLayer implements MapLayer {
  DisasterMapLayer(this._repository);

  final DisasterMapRepository _repository;

  MapLibreMapController? _controller;
  bool _styleHasAed = false;
  Future<void> _ops = Future<void>.value();

  /// AED points — on by default.
  final ValueNotifier<bool> showAed = ValueNotifier(true);

  final ValueNotifier<int?> _selectedId = ValueNotifier<int?>(null);
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  final ValueNotifier<AedDetail?> _detail = ValueNotifier<AedDetail?>(null);
  final ValueNotifier<String?> _previewName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _previewPlace = ValueNotifier<String?>(null);

  static const _pointColor = '#e74c3c';

  @override
  String get id => 'dpm';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerDisasterMap;

  @override
  IconData get icon => Icons.health_and_safety_outlined;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => AedSheet.peekExtent;

  @override
  double get mapMinZoom => 4;

  @override
  double get mapMaxZoom => 16;

  /// AED is added at runtime — never bake into the base style JSON.

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(
    MapLibreMapController c,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {}

  /// Toggle AED overlay; clears selection when turned off.
  void setShowAed(bool value) {
    if (showAed.value == value) return;
    showAed.value = value;
    if (!value) {
      _repository.cancelTilePrefetch();
      close();
    } else {
      final c = _controller;
      if (c != null) unawaited(_prefetchViewport(c));
    }
    _applyOverlayVisibility();
  }

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _ensureAedLayers(controller);
    _styleHasAed = true;
    Log.info('DPM AED runtime tiles: ${_repository.tileUrl('aed')}');
    await _applyOverlayVisibilityAsync(controller);
    unawaited(_prefetchViewport(controller));
  }

  Future<void> _ensureAedLayers(MapLibreMapController controller) async {
    final ids = await controller.getLayerIds();
    final idSet = {for (final id in ids) id.toString()};
    if (idSet.contains(dpmAedPointsLayerId)) return;

    final tileUrl = _repository.tileUrl('aed');
    try {
      await controller.removeSource(dpmAedSourceId);
    } catch (_) {
      // Source absent — fine.
    }

    await controller.addSource(
      dpmAedSourceId,
      VectorSourceProperties(tiles: [tileUrl], minzoom: 0, maxzoom: 16),
    );

    // One layer, no filter: the tileset is downsampled server-side, so every
    // feature is a real AED and they are all drawn the same way.
    await controller.addCircleLayer(
      dpmAedSourceId,
      dpmAedPointsLayerId,
      const CircleLayerProperties(
        circleColor: _pointColor,
        circleRadius: 6,
        circleStrokeWidth: 1.5,
        circleStrokeColor: '#ffffff',
      ),
      sourceLayer: 'aed',
      enableInteraction: true,
    );
  }

  Future<void> _removeAedLayers(MapLibreMapController controller) async {
    for (final layerId in [dpmAedPointsLayerId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {}
    }
    try {
      await controller.removeSource(dpmAedSourceId);
    } catch (_) {}
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (!_styleHasAed || !showAed.value) return;
    final screen = await controller.toScreenLocation(latLng);
    final hit = Point<double>(screen.x.toDouble(), screen.y.toDouble());
    final points = await controller.queryRenderedFeatures(hit, [
      dpmAedPointsLayerId,
    ], null);
    if (points.isNotEmpty) await _selectFeature(points.first);
  }

  Future<void> _selectFeature(dynamic feature) async {
    final props = _props(feature);
    final id = _asInt(props['id']);
    if (id == null) return;
    _selectedId.value = id;
    _previewName.value = props['name']?.toString();
    _previewPlace.value = props['place']?.toString();
    _detail.value = null;
    _selectionRevision.value++;
    final result = await _repository.aedDetail(id);
    if (_selectedId.value != id) return;
    result.when(ok: (detail) => _detail.value = detail, err: (_) {});
  }

  static Map<String, dynamic> _props(dynamic feature) {
    if (feature is Map) {
      final p = feature['properties'];
      if (p is Map) return Map<String, dynamic>.from(p);
    }
    return const {};
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _applyOverlayVisibility() {
    final controller = _controller;
    if (controller == null || !_styleHasAed) return;
    _queue(() => _applyOverlayVisibilityAsync(controller));
  }

  Future<void> _applyOverlayVisibilityAsync(
    MapLibreMapController controller,
  ) async {
    final visible = showAed.value;
    for (final layerId in [dpmAedPointsLayerId]) {
      try {
        await controller.setLayerVisibility(layerId, visible);
      } catch (error, stackTrace) {
        Log.handle(
          error,
          stackTrace,
          'DPM setLayerVisibility($layerId → $visible)',
        );
      }
    }
  }

  void _queue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((_) {});
  }

  @override
  Widget buildSheet(BuildContext context) => AedSheet(
    selectionId: _selectedId,
    selectionRevision: _selectionRevision,
    detail: _detail,
    previewName: _previewName,
    previewPlace: _previewPlace,
    onClose: close,
  );

  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: const _AedSwatch(color: Color(0xFFE74C3C), size: 10),
            label: l10n.mapLayerAed,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildTopTrailingChrome(BuildContext context) =>
      DisasterMapOverlayMenu(layer: this);

  @override
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  @override
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) =>
      _prefetchViewport(controller);

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) =>
      _prefetchViewport(controller);

  Future<void> _prefetchViewport(MapLibreMapController controller) async {
    if (!_styleHasAed || !showAed.value) return;
    try {
      final bounds = await controller.getVisibleRegion();
      final zoom = controller.cameraPosition?.zoom ?? 10;
      await _repository.prefetchAedTiles(
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'DPM viewport prefetch');
    }
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _repository.cancelTilePrefetch();
    await _removeAedLayers(controller);
    _controller = null;
    _styleHasAed = false;
    close();
  }

  @override
  void selectFeature(String id) {}

  @override
  void onStyleReset() {
    // Style reload drops runtime layers; [render] re-adds when active.
    _styleHasAed = false;
  }

  void close() {
    _selectedId.value = null;
    _detail.value = null;
    _previewName.value = null;
    _previewPlace.value = null;
  }
}

class _AedSwatch extends StatelessWidget {
  const _AedSwatch({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
