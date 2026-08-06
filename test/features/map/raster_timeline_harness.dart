/// Shared fakes for the raster timeline layers (radar, satellite).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A [RasterFrameSource] that records the tile-memory calls a layer makes.
///
/// Those calls are the contract that keeps a scrub cheap — which frames were
/// warmed, and which were abandoned — so they are asserted directly rather than
/// inferred from controller traffic.
abstract class FakeRasterFrameSource implements RasterFrameSource {
  FakeRasterFrameSource(this._frames);

  final List<String> _frames;

  /// One entry per [warmFrameTiles] call: the frames it was asked to warm.
  final List<List<String>> warmed = [];

  /// Every frame id passed to [abandonFrames], flattened.
  final List<String> abandoned = [];

  /// How many times [releaseTiles] was called.
  int released = 0;

  @override
  Future<Result<List<String>>> frames() async => Ok(_frames);

  @override
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async => warmed.add(List<String>.of(frames));

  @override
  Future<void> abandonFrames(List<String> frames) async =>
      abandoned.addAll(frames);

  @override
  Future<void> releaseTiles() async => released++;
}

/// Records the MapLibre calls a layer makes, and the last state of each layer.
class RecordingMapController implements MapLibreMapController {
  final List<String> calls = [];

  /// Property keys of each `setLayerProperties` call, in order — what actually
  /// went over the platform channel.
  final List<Set<String>> sentKeys = [];

  final Map<String, ({String? visibility, String? opacity})> _state = {};

  String? visibilityOf(String layerId) => _state[layerId]?.visibility;
  String? opacityOf(String layerId) => _state[layerId]?.opacity;

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async =>
      calls.add('addSource:$sourceId');

  /// `raster-opacity-transition` each layer was mounted with, by layer id.
  final Map<String, Object?> mountTransitions = {};

  @override
  Future<void> addRasterLayer(
    String sourceId,
    String layerId,
    RasterLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async {
    calls.add('addRasterLayer:$layerId');
    mountTransitions[layerId] = properties
        .toJson()['raster-opacity-transition'];
    _record(layerId, properties);
  }

  @override
  Future<void> addLineLayer(
    String sourceId,
    String layerId,
    LineLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async => calls.add('addLineLayer:$layerId');

  @override
  Future<void> removeLayer(String layerId) async =>
      calls.add('removeLayer:$layerId');

  @override
  Future<void> removeSource(String sourceId) async =>
      calls.add('removeSource:$sourceId');

  @override
  Future<void> setLayerProperties(
    String layerId,
    LayerProperties properties, {
    bool skipNulls = false,
  }) async {
    final json = properties.toJson();
    calls.add('set:$layerId:${json['raster-opacity']}');
    sentKeys.add(json.keys.toSet());
    _record(layerId, properties);
  }

  /// Merges into the layer's state: the layer keeps whatever a call omits,
  /// which is exactly what `skipNulls` means on the wire.
  void _record(String layerId, LayerProperties properties) {
    final json = properties.toJson();
    final previous = _state[layerId];
    _state[layerId] = (
      visibility: json['visibility']?.toString() ?? previous?.visibility,
      opacity: json['raster-opacity']?.toString() ?? previous?.opacity,
    );
  }

  @override
  Future<LatLngBounds> getVisibleRegion() async => LatLngBounds(
    southwest: const LatLng(22, 120),
    northeast: const LatLng(25, 122),
  );

  @override
  CameraPosition? get cameraPosition =>
      const CameraPosition(target: LatLng(23.5, 121), zoom: 7);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
