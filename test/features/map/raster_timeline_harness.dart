/// Shared fakes for the raster timeline layers (radar, satellite).
library;

import 'dart:math' show Point;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/map/map_style.dart'
    show landLayerId, outlineLayerId, townLabelLayerId;
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
    bool fill = false,
  }) async => warmed.add(List<String>.of(frames));

  @override
  Future<void> abandonFrames(List<String> frames) async =>
      abandoned.addAll(frames);

  @override
  Future<void> releaseTiles() async => released++;
}

/// Records the MapLibre calls a layer makes, and the last state of each layer.
class RecordingMapController implements MapLibreMapController {
  RecordingMapController({CameraPosition? camera})
    : _camera =
          camera ?? const CameraPosition(target: LatLng(23.5, 121), zoom: 7);

  final List<String> calls = [];

  /// Property keys of each `setLayerProperties` call, in order — what actually
  /// went over the platform channel.
  final List<Set<String>> sentKeys = [];

  final Map<String, ({String? visibility, String? opacity})> _state = {};

  String? visibilityOf(String layerId) => _state[layerId]?.visibility;
  String? opacityOf(String layerId) => _state[layerId]?.opacity;

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    // The iOS plugin feeds `data` straight to NSJSONSerialization, which
    // *throws* — aborting the process, not returning an error — on anything
    // that is not a JSON object. Reproduce that here so a source built from an
    // encoded string fails in a test instead of on a device.
    final data = properties.toJson()['data'];
    if (data != null && data is! Map) {
      throw ArgumentError.value(
        data,
        'data',
        'GeoJSON source data must be a Map, not ${data.runtimeType} — '
            'a top-level string crashes NSJSONSerialization on iOS',
      );
    }
    calls.add('addSource:$sourceId');
  }

  /// `raster-opacity-transition` each layer was mounted with, by layer id.
  final Map<String, Object?> mountTransitions = {};

  @override
  Future<void> addHillshadeLayer(
    String sourceId,
    String layerId,
    HillshadeLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async {
    calls.add('addHillshadeLayer:$layerId');
    _insert(layerId, belowLayerId);
    below[layerId] = belowLayerId;
  }

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
    _insert(layerId, belowLayerId);
    below[layerId] = belowLayerId;
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
  }) async {
    below[layerId] = belowLayerId;
    lineColor[layerId] = properties.toJson()['line-color']?.toString();
    calls.add('addLineLayer:$layerId');
    _insert(layerId, belowLayerId);
  }

  /// What each line/fill layer was anchored below — null means "on top", which
  /// is the difference between a border that survives a raster and one that
  /// disappears under it.
  final Map<String, String?> below = {};

  /// The style's layer order, bottom-most first — what actually decides what
  /// covers what.
  ///
  /// Recording the `belowLayerId` alone is not enough to catch a stacking bug:
  /// the frames and the borders can quote the *same* anchor and still end up in
  /// either order, because MapLibre inserts a layer **immediately below** its
  /// anchor and so the most recently added one ends up highest. That is exactly
  /// how a timeline scrub used to bury the county borders under the echo. So
  /// this models the real insertion, seeded with the base style's own layers.
  final List<String> order = [landLayerId, outlineLayerId, townLabelLayerId];

  void _insert(String layerId, String? belowLayerId) {
    order.remove(layerId);
    final anchor = belowLayerId == null ? -1 : order.indexOf(belowLayerId);
    if (anchor < 0) {
      order.add(layerId); // no anchor (or unknown) — on top
    } else {
      order.insert(anchor, layerId);
    }
  }

  /// Whether [above] is drawn over [below_] — the question every ordering test
  /// is really asking. Fails loudly on a layer that was never added, so a typo
  /// cannot read as a pass.
  bool isAbove(String above, String below_) {
    final a = order.indexOf(above);
    final b = order.indexOf(below_);
    if (a < 0) throw StateError('$above was never added');
    if (b < 0) throw StateError('$below_ was never added');
    return a > b;
  }

  /// The anchor recorded for [layerId]; also null when never added, so pair it
  /// with a `calls` assertion.
  String? belowOf(String layerId) => below[layerId];

  /// The `line-color` each line layer was drawn with — lets a test pin the
  /// white radar border vs the yellow satellite one.
  final Map<String, String?> lineColor = {};

  /// The colour recorded for [layerId], or null when never added.
  String? lineColorOf(String layerId) => lineColor[layerId];

  @override
  Future<void> addFillLayer(
    String sourceId,
    String layerId,
    FillLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    below[layerId] = belowLayerId;
    calls.add('addFillLayer:$layerId');
    _insert(layerId, belowLayerId);
  }

  @override
  Future<void> addSymbolLayer(
    String sourceId,
    String layerId,
    SymbolLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    below[layerId] = belowLayerId;
    calls.add('addSymbolLayer:$layerId');
    _insert(layerId, belowLayerId);
  }

  @override
  Future<void> addCircleLayer(
    String sourceId,
    String layerId,
    CircleLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    below[layerId] = belowLayerId;
    calls.add('addCircleLayer:$layerId');
    _insert(layerId, belowLayerId);
  }

  @override
  Future<void> removeLayer(String layerId) async {
    calls.add('removeLayer:$layerId');
    order.remove(layerId);
  }

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
  Future<void> setLayerVisibility(String layerId, bool visible) async {
    calls.add('setLayerVisibility:$layerId:$visible');
    final previous = _state[layerId];
    _state[layerId] = (
      visibility: visible ? 'visible' : 'none',
      opacity: previous?.opacity,
    );
  }

  @override
  Future<LatLngBounds> getVisibleRegion() async => LatLngBounds(
    southwest: const LatLng(22, 120),
    northeast: const LatLng(25, 122),
  );

  @override
  Future<List<Point<num>>> toScreenLocationBatch(
    Iterable<LatLng> coords,
  ) async => [for (final c in coords) Point(c.longitude, c.latitude)];

  /// Camera the [cameraPosition] getter reports — a wind-overlay test can
  /// zoom out to put more of the field in view (the default z7 viewport holds
  /// only a handful of particles, too few to assert anything about).
  final CameraPosition _camera;

  @override
  CameraPosition? get cameraPosition => _camera;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
