import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The satellite IR cloud (衛星雲圖) raster [MapLayer] — same scrub/prefetch
/// window as [RadarMapLayer], backed by the v2 Himawari XYZ WebP tiles.
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

  static const int _prefetchRadius = 1;

  static const RasterLayerProperties _prefetching = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: 0,
  );
  static const RasterLayerProperties _shown = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: _opacity,
  );

  String _sourceId(String frameId) => 'satellite-src-$frameId';
  String _layerId(String frameId) => 'satellite-lyr-$frameId';

  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};
  final Set<String> _onMap = <String>{};
  String? _shownFrameId;
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
    _orderedIds = [for (final frame in frames) frame.id];
    _indexById = {for (var i = 0; i < frames.length; i++) frames[i].id: i};
  }

  @override
  Future<void> show(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    final index = _indexById[frame.id];
    if (index == null) return;

    final lo = (index - _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final window = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    final leaving = _onMap.difference(window);
    for (final id in leaving) {
      await _removeFrame(controller, id);
      _onMap.remove(id);
    }

    for (final id in window) {
      final properties = id == frame.id ? _shown : _prefetching;
      if (_onMap.contains(id)) {
        await controller.setLayerProperties(_layerId(id), properties);
      } else {
        await controller.addSource(
          _sourceId(id),
          RasterSourceProperties(
            tiles: [_repository.tileUrl(id)],
            tileSize: 256,
          ),
        );
        // Below the themed county outline; the black IR outline sits on top
        // of both (see [_ensureBlackOutline]).
        await controller.addRasterLayer(
          _sourceId(id),
          _layerId(id),
          properties,
          belowLayerId: outlineLayerId,
        );
        _onMap.add(id);
      }
    }
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
    for (final id in _onMap) {
      await _removeFrame(controller, id);
    }
    await _removeBlackOutline(controller);
    _reset();
  }

  Future<void> _removeFrame(MapLibreMapController controller, String id) async {
    try {
      await controller.removeLayer(_layerId(id));
    } catch (_) {
      // Already gone — fine.
    }
    try {
      await controller.removeSource(_sourceId(id));
    } catch (_) {
      // Already gone — fine.
    }
  }

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _onMap.clear();
    _orderedIds = const [];
    _indexById = const {};
    _shownFrameId = null;
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
