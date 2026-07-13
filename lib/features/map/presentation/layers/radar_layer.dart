import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster [MapLayer] — the first concrete layer on the
/// shared map.
///
/// The whole history the API serves (~a week of 10-min frames) is scrubbable,
/// but only a small window is ever on the map: each frame's raster layer is
/// added the first time it enters the window around the current frame — the
/// current one drawn, its neighbours prefetching (visible but transparent) so a
/// scrub onto them is instant — and frames that leave the window are removed. So
/// the map holds ~3 layers regardless of how many frames exist. Adding another
/// weather layer later means writing a sibling of this class.
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

  /// Opacity of the drawn frame.
  static const double _opacity = 0.85;

  /// Frames kept loaded on each side of the current one (prev/next), so a scrub
  /// onto a neighbour is instant while far frames stay unloaded and undrawn.
  static const int _prefetchRadius = 1;

  static const RasterLayerProperties _prefetching = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: 0,
  );
  static const RasterLayerProperties _shown = RasterLayerProperties(
    visibility: 'visible',
    rasterOpacity: _opacity,
  );

  String _sourceId(String frameId) => 'radar-src-$frameId';
  String _layerId(String frameId) => 'radar-lyr-$frameId';

  /// Every frame's id in chronological order, plus its index — for neighbour
  /// lookup. The full week of frames lives here (cheap — just strings); only the
  /// window is ever on the map.
  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};

  /// Frame ids currently on the map — the live window. Frames that leave it are
  /// removed, so the map holds ~3 layers no matter how many frames there are.
  final Set<String> _onMap = <String>{};

  String? _shownFrameId;

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await _repository.frames();
    // The whole list (the API serves ~a week of 10-min frames); the map only
    // ever holds the window, so all of it is scrubbable without the layer cost.
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
    // Only record the set — frames are added lazily by [show] as they enter the
    // window, so opening the map never pays to add every frame up front.
    _orderedIds = [for (final frame in frames) frame.id];
    _indexById = {for (var i = 0; i < frames.length; i++) frames[i].id: i};
  }

  @override
  Future<void> show(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    final index = _indexById[frame.id];
    if (index == null) return; // not part of this layer's frames

    final lo = (index - _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final window = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    // Drop frames that left the window so the map keeps only ~3 layers; their
    // tiles stay in MapLibre's cache, so returning re-adds them cheaply.
    final leaving = _onMap.difference(window);
    for (final id in leaving) {
      await controller.removeLayer(_layerId(id));
      await controller.removeSource(_sourceId(id));
    }
    _onMap.removeAll(leaving);

    // The current frame is drawn; its neighbours prefetch (visible, transparent)
    // so a scrub onto them is instant. Add on first entry, else just retarget.
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
        await controller.addRasterLayer(
          _sourceId(id),
          _layerId(id),
          properties,
          belowLayerId: outlineLayerId,
        );
        _onMap.add(id);
      }
    }
    _shownFrameId = frame.id;
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    for (final id in _onMap) {
      await controller.removeLayer(_layerId(id));
      await controller.removeSource(_sourceId(id));
    }
    _reset();
  }

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _onMap.clear();
    _orderedIds = const [];
    _indexById = const {};
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
