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
/// Every frame gets its own raster layer, but they sit hidden (`visibility:none`,
/// so unfetched and undrawn) until they enter a small window around the current
/// frame: the current one is drawn, its immediate neighbours prefetch (visible
/// but transparent) so scrubbing onto them is instant, and far frames stay
/// unloaded. That keeps at most ~3 layers active — the timeline animates without
/// a per-frame fetch, and the map doesn't choke on a whole loop at once. Adding
/// another weather layer later means writing a sibling of this class.
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

  static const RasterLayerProperties _hidden = RasterLayerProperties(
    visibility: 'none',
    rasterOpacity: 0,
  );
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

  /// Every frame's id in chronological order — for neighbour lookup.
  List<String> _orderedIds = const [];

  /// Frame ids currently added to the map (each a hidden raster layer).
  final Set<String> _prepared = <String>{};

  /// Frame ids currently in the live window (visible: the current one drawn,
  /// its neighbours prefetching at opacity 0).
  Set<String> _windowed = <String>{};

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
    for (final frame in frames) {
      if (_prepared.contains(frame.id)) continue;
      await controller.addSource(
        _sourceId(frame.id),
        RasterSourceProperties(
          tiles: [_repository.tileUrl(frame.id)],
          tileSize: 256,
        ),
      );
      // Added hidden: no tiles fetched, nothing drawn, until it enters a window.
      await controller.addRasterLayer(
        _sourceId(frame.id),
        _layerId(frame.id),
        _hidden,
        belowLayerId: outlineLayerId,
      );
      _prepared.add(frame.id);
    }
  }

  @override
  Future<void> show(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    final index = _orderedIds.indexOf(frame.id);
    if (index < 0) return; // not prepared

    final lo = (index - _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final window = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    // Frames leaving the window → hidden (stop fetching + drawing).
    for (final id in _windowed.difference(window)) {
      await controller.setLayerProperties(_layerId(id), _hidden);
    }
    // Frames in the window → the current one drawn, neighbours prefetching.
    for (final id in window) {
      await controller.setLayerProperties(
        _layerId(id),
        id == frame.id ? _shown : _prefetching,
      );
    }
    _windowed = window;
    _shownFrameId = frame.id;
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    for (final id in _prepared) {
      await controller.removeLayer(_layerId(id));
      await controller.removeSource(_sourceId(id));
    }
    _reset();
  }

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _prepared.clear();
    _windowed = <String>{};
    _orderedIds = const [];
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
