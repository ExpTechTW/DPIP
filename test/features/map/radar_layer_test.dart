import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class _FakeRadarRepository implements RadarRepository {
  _FakeRadarRepository(this._frames);
  final List<String> _frames;

  @override
  Future<Result<List<String>>> frames() async => Ok(_frames);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.png';

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

void main() {
  test('frames chronological', () async {
    final layer = RadarMapLayer(
      _FakeRadarRepository(['1700000600000', '1700000000000']),
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000000', '1700000600000']);
  });

  test('scrub hot path is only prev-hide + curr-show', () async {
    final layer = RadarMapLayer(
      _FakeRadarRepository([
        '1700001800000',
        '1700001200000',
        '1700000600000',
        '1700000000000',
      ]),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = _RecordingController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[3]);
    expect(
      controller.calls.where((c) => c.startsWith('addSource:')),
      hasLength(2),
    );

    controller.calls.clear();
    await layer.show(controller, frames[2], scrubbing: true);
    // Exactly two property sets — no remove/add/cancel.
    expect(controller.calls, [
      'set:radar-lyr-1700001800000:none:0',
      'set:radar-lyr-1700001200000:visible:0.85',
    ]);

    controller.calls.clear();
    await layer.show(controller, frames[0], scrubbing: true);
    expect(controller.calls, isEmpty);
  });

  test('history length uncapped', () async {
    final ids = [for (var i = 0; i < 500; i++) '${1700000000000 + i * 600000}'];
    final layer = RadarMapLayer(_FakeRadarRepository(ids.reversed.toList()));
    expect((await layer.frames()).valueOrNull!.length, 500);
  });
}
