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
/// Only the recent loop is used ([maxFrames]), and each frame's raster layer is
/// added lazily, the first time it enters a small window around the current
/// frame: the current one is drawn, its immediate neighbours prefetch (visible
/// but transparent) so scrubbing onto them is instant, and frames outside the
/// window are hidden. So opening the map adds ~2 layers, not a thousand, and at
/// most ~3 are ever active. Adding another weather layer later means writing a
/// sibling of this class.
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

  /// How many recent frames to keep. The API serves ~a week of 10-min frames
  /// (~1000); the timeline shows just the recent loop, like the reference — and
  /// bounding it keeps the map from ever adding a thousand layers.
  static const int maxFrames = 24; // ~last 4 hours at 10-min cadence

  String _sourceId(String frameId) => 'radar-src-$frameId';
  String _layerId(String frameId) => 'radar-lyr-$frameId';

  /// Every frame's id in chronological order — for neighbour lookup.
  List<String> _orderedIds = const [];

  /// Frame ids added to the map so far (added lazily as they enter a window).
  final Set<String> _added = <String>{};

  /// Frame ids currently in the live window (visible: the current one drawn,
  /// its neighbours prefetching at opacity 0).
  Set<String> _windowed = <String>{};

  String? _shownFrameId;

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await _repository.frames();
    return result.map((raw) {
      final all = [
        for (final id in raw) MapFrame(id: id, time: _parseFrameTime(id)),
      ]..sort((a, b) => a.time.compareTo(b.time));
      // Keep only the most recent [maxFrames] — the recent radar loop.
      return all.length <= maxFrames
          ? all
          : all.sublist(all.length - maxFrames);
    });
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {
    // Only record the set — frames are added lazily by [show] as they enter the
    // window, so opening the map never pays to add every frame up front.
    _orderedIds = [for (final frame in frames) frame.id];
  }

  @override
  Future<void> show(MapLibreMapController controller, MapFrame frame) async {
    if (_shownFrameId == frame.id) return;
    final index = _orderedIds.indexOf(frame.id);
    if (index < 0) return; // not part of this layer's frames

    final lo = (index - _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final hi = (index + _prefetchRadius).clamp(0, _orderedIds.length - 1);
    final window = <String>{for (var j = lo; j <= hi; j++) _orderedIds[j]};

    // Frames leaving the window → hidden (stop drawing + fetching).
    for (final id in _windowed.difference(window)) {
      if (_added.contains(id)) {
        await controller.setLayerProperties(_layerId(id), _hidden);
      }
    }
    // Frames in the window → the current one drawn, neighbours prefetching;
    // add on first entry so only what's needed is ever on the map.
    for (final id in window) {
      await _apply(controller, id, id == frame.id ? _shown : _prefetching);
    }
    _windowed = window;
    _shownFrameId = frame.id;
  }

  /// Sets [id]'s layer to [properties], adding its source/layer the first time.
  Future<void> _apply(
    MapLibreMapController controller,
    String id,
    RasterLayerProperties properties,
  ) async {
    if (_added.contains(id)) {
      await controller.setLayerProperties(_layerId(id), properties);
      return;
    }
    await controller.addSource(
      _sourceId(id),
      RasterSourceProperties(tiles: [_repository.tileUrl(id)], tileSize: 256),
    );
    await controller.addRasterLayer(
      _sourceId(id),
      _layerId(id),
      properties,
      belowLayerId: outlineLayerId,
    );
    _added.add(id);
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    for (final id in _added) {
      await controller.removeLayer(_layerId(id));
      await controller.removeSource(_sourceId(id));
    }
    _reset();
  }

  @override
  void onStyleReset() => _reset();

  void _reset() {
    _added.clear();
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
