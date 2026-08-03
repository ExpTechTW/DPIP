/// AED (automated external defibrillator) disaster-prevention map layer —
/// MapLibre vector tiles from `/api/v2/tiles/dpm/aed/…`, tap → detail sheet.
library;

import 'dart:math' show Point;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/map/presentation/widgets/aed_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Sheet-driven [MapLayer] for AED points (MVT + cluster circles).
///
/// Tiles are loaded by MapLibre from [DisasterMapRepository.tileUrl]; detail is
/// fetched on tap via [DisasterMapRepository.aedDetail]. Future DPM layers
/// (shelters, …) can copy this class with a different [id] / source-layer.
class AedMapLayer implements MapLayer {
  AedMapLayer(this._repository);

  final DisasterMapRepository _repository;

  static const String _layerKey = 'aed';
  static const String _sourceLayer = 'aed';

  final ValueNotifier<int?> _selectedId = ValueNotifier<int?>(null);
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  final ValueNotifier<AedDetail?> _detail = ValueNotifier<AedDetail?>(null);
  final ValueNotifier<String?> _previewName = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _previewPlace = ValueNotifier<String?>(null);

  bool _onMap = false;

  String get _src => 'dpm-$_layerKey-src';
  String get _clustersId => 'dpm-$_layerKey-clusters';
  String get _clusterCountId => 'dpm-$_layerKey-cluster-count';
  String get _pointsId => 'dpm-$_layerKey-points';

  @override
  String get id => 'dpm-aed';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerAed;

  @override
  IconData get icon => Icons.medical_services_outlined;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => AedSheet.peekExtent;

  @override
  double get mapMinZoom => 4;

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(MapLibreMapController c, MapFrame frame) async {}

  @override
  Future<void> render(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    await controller.addSource(
      _src,
      VectorSourceProperties(
        tiles: [_repository.tileUrl(_layerKey)],
        minzoom: 0,
        maxzoom: 16,
      ),
    );
    await controller.addCircleLayer(
      _src,
      _clustersId,
      const CircleLayerProperties(
        circleColor: '#c0392b',
        circleOpacity: 0.75,
        circleRadius: [
          'step',
          ['get', 'point_count'],
          12,
          10,
          16,
          50,
          22,
          200,
          28,
        ],
      ),
      sourceLayer: _sourceLayer,
      filter: const ['has', 'point_count'],
      enableInteraction: false,
    );
    await controller.addSymbolLayer(
      _src,
      _clusterCountId,
      const SymbolLayerProperties(
        textField: [
          'to-string',
          ['get', 'point_count'],
        ],
        textSize: 11,
        textColor: '#FFFFFF',
        textAllowOverlap: true,
      ),
      sourceLayer: _sourceLayer,
      filter: const ['has', 'point_count'],
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _src,
      _pointsId,
      const CircleLayerProperties(
        circleColor: '#e74c3c',
        circleRadius: 5,
        circleStrokeWidth: 1.5,
        circleStrokeColor: '#FFFFFF',
      ),
      sourceLayer: _sourceLayer,
      filter: const [
        '!',
        ['has', 'point_count'],
      ],
      enableInteraction: false,
    );
    _onMap = true;
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    if (!_onMap) return;
    final screen = await controller.toScreenLocation(latLng);
    // Prefer a single AED point; otherwise zoom into a cluster.
    final hit = Point<double>(screen.x.toDouble(), screen.y.toDouble());
    final points = await controller.queryRenderedFeatures(
      hit,
      [_pointsId],
      null,
    );
    if (points.isNotEmpty) {
      await _selectFeature(points.first);
      return;
    }
    final clusters = await controller.queryRenderedFeatures(
      hit,
      [_clustersId],
      null,
    );
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
      const SizedBox.shrink();

  @override
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  @override
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    close();
  }

  @override
  void onStyleReset() {
    _onMap = false;
  }

  void close() {
    _selectedId.value = null;
    _detail.value = null;
    _previewName.value = null;
    _previewPlace.value = null;
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    for (final layerId in [_clusterCountId, _clustersId, _pointsId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Already gone.
      }
    }
    try {
      await controller.removeSource(_src);
    } catch (_) {
      // Already gone.
    }
    _onMap = false;
  }
}
