/// Disaster-prevention map layer — MVT overlays (AED today) baked into the
/// base style while active, with a typhoon-style tune menu; tap → detail sheet.
library;

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
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Sheet-driven [MapLayer] for the disaster-prevention map (DPM).
///
/// Switcher entry is 「防災地圖」; [DisasterMapOverlayMenu] toggles sub-layers
/// (AED for now). AED MVT is **baked into the style JSON** via
/// [bakedAedTileUrl] (same path as the ExpTech basemap) — runtime
/// `VectorSource` addSource was not painting on device. Detail on tap via
/// [DisasterMapRepository.aedDetail].
class DisasterMapLayer implements MapLayer {
  DisasterMapLayer(this._repository);

  final DisasterMapRepository _repository;

  MapLibreMapController? _controller;
  bool _styleHasAed = false;
  Future<void> _ops = Future<void>.value();

  /// AED points / clusters — on by default.
  final ValueNotifier<bool> showAed = ValueNotifier(true);

  final ValueNotifier<int?> _selectedId = ValueNotifier<int?>(null);
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  final ValueNotifier<AedDetail?> _detail = ValueNotifier<AedDetail?>(null);
  final ValueNotifier<String?> _previewName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _previewPlace = ValueNotifier<String?>(null);

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

  @override
  String? get bakedAedTileUrl => _repository.tileUrl('aed');

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(MapLibreMapController c, MapFrame frame) async {}

  /// Toggle AED overlay; clears selection when turned off.
  void setShowAed(bool value) {
    if (showAed.value == value) return;
    showAed.value = value;
    if (!value) close();
    _applyOverlayVisibility();
  }

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    _styleHasAed = true;
    Log.info('DPM AED style tiles: $bakedAedTileUrl');
    await _applyOverlayVisibilityAsync(controller);
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (!_styleHasAed || !showAed.value) return;
    final screen = await controller.toScreenLocation(latLng);
    final hit = Point<double>(screen.x.toDouble(), screen.y.toDouble());
    final points = await controller.queryRenderedFeatures(hit, [
      dpmAedPointsLayerId,
    ], null);
    if (points.isNotEmpty) {
      await _selectFeature(points.first);
      return;
    }
    final clusters = await controller.queryRenderedFeatures(hit, [
      dpmAedClustersLayerId,
    ], null);
    if (clusters.isEmpty) return;
    final zoom = controller.cameraPosition?.zoom ?? 10;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, (zoom + 2).clamp(4, 16).toDouble()),
    );
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
    for (final layerId in [
      dpmAedClustersLayerId,
      dpmAedClusterCountLayerId,
      dpmAedPointsLayerId,
    ]) {
      try {
        await controller.setLayerVisibility(layerId, visible);
      } catch (_) {
        // Style may not have finished applying yet.
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
  Widget buildLegend(BuildContext context) => const SizedBox.shrink();

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
  Future<void> clear(MapLibreMapController controller) async {
    // AED lives in the style JSON; leaving this layer drops [bakedAedTileUrl]
    // so MapScaffold rebuilds the style without it.
    _controller = null;
    _styleHasAed = false;
    close();
  }

  @override
  void onStyleReset() {
    // Style reload drops baked layers; [render] re-marks when we are active.
    _styleHasAed = false;
  }

  void close() {
    _selectedId.value = null;
    _detail.value = null;
    _previewName.value = null;
    _previewPlace.value = null;
  }
}
