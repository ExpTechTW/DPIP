import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster [MapLayer] — the first concrete layer on the
/// shared map.
///
/// Turns the [RadarRepository]'s frame timestamps into a scrubbable timeline and
/// renders the selected frame as a raster overlay anchored below the county
/// outlines. Adding another weather layer later means writing a sibling of this
/// class, not touching the map scaffold.
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

  static const String _sourceId = 'radar-source';
  static const String _layerId = 'radar-layer';

  /// The frame currently on the map, so a repeat [render] of it is a no-op.
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
  Future<void> render(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    // Raster source tiles can't be swapped in place — drop and re-add for the
    // new frame.
    await _removeIfPresent(controller);
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
      const RasterLayerProperties(rasterOpacity: 0.85),
      belowLayerId: outlineLayerId,
    );
    _shownFrameId = frame.id;
  }

  @override
  Future<void> clear(MapLibreMapController controller) =>
      _removeIfPresent(controller);

  @override
  void onStyleReset() => _shownFrameId = null;

  Future<void> _removeIfPresent(MapLibreMapController controller) async {
    if (_shownFrameId == null) return;
    await controller.removeLayer(_layerId);
    await controller.removeSource(_sourceId);
    _shownFrameId = null;
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
