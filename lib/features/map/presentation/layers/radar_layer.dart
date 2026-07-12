import 'package:dpip/shared/map/radar_repository.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster layer on the base map.
///
/// Encapsulates the radar source/layer lifecycle so map surfaces can add or
/// drop it without touching MapLibre ids directly — the seed of a pluggable
/// map-layer pattern. v1 shows the single latest frame; timeline animation can
/// build on this later.
class RadarLayer {
  RadarLayer(this._controller, this._repository);

  static const String _sourceId = 'radar';
  static const String _layerId = 'radar';

  final MapLibreMapController _controller;
  final RadarRepository _repository;
  bool _added = false;

  /// Adds the latest radar frame to the map. No-op if already shown, if the
  /// frame fetch fails, or if no frames are available — radar is a decorative
  /// overlay, so its absence degrades gracefully rather than blocking the map.
  /// Anchor the raster above [belowLayerId] when the base style has labels/
  /// outlines that should stay on top.
  Future<void> showLatest({String? belowLayerId}) async {
    if (_added) return;
    final frames = (await _repository.frames()).valueOrNull;
    if (frames == null || frames.isEmpty) return;
    await _controller.addSource(
      _sourceId,
      RasterSourceProperties(
        tiles: [_repository.tileUrl(frames.first)],
        tileSize: 256,
      ),
    );
    await _controller.addRasterLayer(
      _sourceId,
      _layerId,
      const RasterLayerProperties(rasterOpacity: 0.85),
      belowLayerId: belowLayerId,
    );
    _added = true;
  }

  /// Removes the radar layer and its source.
  Future<void> remove() async {
    if (!_added) return;
    await _controller.removeLayer(_layerId);
    await _controller.removeSource(_sourceId);
    _added = false;
  }
}
