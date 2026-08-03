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

  test('swaps a single raster source per frame (GIF scrub)', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository([
        '1700001800000',
        '1700001200000',
        '1700000600000',
        '1700000000000',
      ]),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = _RecordingController();

    await layer.prepare(controller, frames);
    expect(controller.calls, isEmpty);

    await layer.show(controller, frames[3]);
    expect(controller.calls, [
      'addSource:satellite-src',
      'addRasterLayer:satellite-lyr',
      'addLineLayer:satellite-global-outline',
      'addLineLayer:satellite-county-outline',
    ]);

    controller.calls.clear();
    await layer.show(controller, frames[0]);
    expect(controller.calls, [
      'removeLayer:satellite-lyr',
      'removeSource:satellite-src',
      'addSource:satellite-src',
      'addRasterLayer:satellite-lyr',
    ]);
  });
}
