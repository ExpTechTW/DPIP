import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class _FakeSatelliteRepository implements SatelliteRepository {
  _FakeSatelliteRepository(this._frames);
  final List<String> _frames;

  @override
  Future<Result<List<String>>> frames() async => Ok(_frames);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.webp';

  @override
  Future<void> prefetchFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {}

  @override
  void cancelTilePrefetch() {}
}

class _RecordingController implements MapLibreMapController {
  final List<String> calls = [];

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async =>
      calls.add('addSource:$sourceId');

  @override
  Future<void> addRasterLayer(
    String sourceId,
    String layerId,
    RasterLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
  }) async => calls.add('addRasterLayer:$layerId');

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
  Future<LatLngBounds> getVisibleRegion() async => LatLngBounds(
    southwest: const LatLng(22, 120),
    northeast: const LatLng(25, 122),
  );

  @override
  CameraPosition? get cameraPosition =>
      const CameraPosition(target: LatLng(23.5, 121), zoom: 7);

  @override
  Future<void> removeLayer(String layerId) async =>
      calls.add('removeLayer:$layerId');

  @override
  Future<void> removeSource(String sourceId) async =>
      calls.add('removeSource:$sourceId');

  @override
  Future<void> setLayerProperties(
    String layerId,
    LayerProperties properties,
  ) async {
    final json = properties.toJson();
    calls.add('set:$layerId:${json['visibility']}:${json['raster-opacity']}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test(
    'frames come back chronological (oldest first), ids preserved',
    () async {
      final layer = SatelliteMapLayer(
        _FakeSatelliteRepository(['1700000600000', '1700000000000']),
      );

      final result = await layer.frames();
      final frames = result.valueOrNull!;

      expect(frames.map((f) => f.id), ['1700000000000', '1700000600000']);
      expect(frames.first.time.isBefore(frames.last.time), isTrue);
    },
  );

  test('settle mounts window; scrub skips cold frames outside it', () async {
    // 20 frames so settle radius 8 leaves older ones cold.
    final ids = [
      for (var i = 19; i >= 0; i--) '${1700000000000 + i * 600000}',
    ];
    final layer = SatelliteMapLayer(_FakeSatelliteRepository(ids));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = _RecordingController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames.last); // newest
    expect(
      controller.calls.where((c) => c.startsWith('addSource:')),
      hasLength(9), // index 19 → [11..19]
    );

    controller.calls.clear();
    await layer.show(controller, frames.first, scrubbing: true);
    expect(controller.calls, isEmpty);

    controller.calls.clear();
    await layer.show(controller, frames[18], scrubbing: true);
    expect(controller.calls, [
      'set:satellite-lyr-${frames.last.id}:visible:0',
      'set:satellite-lyr-${frames[18].id}:visible:1.0',
    ]);
  });
}
