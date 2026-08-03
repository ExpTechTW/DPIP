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

/// Records the source/layer mutations a [MapLayer] makes; everything else on the
/// controller is unused, so [noSuchMethod] absorbs it.
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
  test(
    'frames come back chronological (oldest first), ids preserved',
    () async {
      // Given newest-first (as the API returns) and unordered input.
      final layer = RadarMapLayer(
        _FakeRadarRepository(['1700000600000', '1700000000000']),
      );

      final result = await layer.frames();
      final frames = result.valueOrNull!;

      expect(frames.map((f) => f.id), ['1700000000000', '1700000600000']);
      expect(frames.first.time.isBefore(frames.last.time), isTrue);
    },
  );

  test(
    'parses second- and millisecond-epoch ids to the same instant',
    () async {
      final layer = RadarMapLayer(
        _FakeRadarRepository(['1700000000', '1700000000000']),
      );

      final frames = (await layer.frames()).valueOrNull!;

      // Both ids denote the same moment; ordering is stable, times identical.
      expect(frames.first.time, frames.last.time);
      expect(
        frames.first.time,
        DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        ).toLocal(),
      );
    },
  );

  test('settle mounts ±radius window; scrub opacity-flips residents', () async {
    final layer = RadarMapLayer(
      _FakeRadarRepository([
        '1700001800000', // f3
        '1700001200000', // f2
        '1700000600000', // f1
        '1700000000000', // f0
      ]),
    );
    final frames = (await layer.frames()).valueOrNull!; // [f0, f1, f2, f3]
    final controller = _RecordingController();

    await layer.prepare(controller, frames);
    expect(controller.calls, isEmpty);

    // Settle on newest — radius 8 covers the whole 4-frame list.
    await layer.show(controller, frames[3]);
    expect(
      controller.calls.where((c) => c.startsWith('addSource:')),
      hasLength(4),
    );

    // Scrub to resident neighbour → only prev hide + curr show.
    controller.calls.clear();
    await layer.show(controller, frames[2], scrubbing: true);
    expect(controller.calls, [
      'set:radar-lyr-1700001800000:visible:0',
      'set:radar-lyr-1700001200000:visible:0.85',
    ]);

    // Same frame again → no-op.
    controller.calls.clear();
    await layer.show(controller, frames[2], scrubbing: true);
    expect(controller.calls, isEmpty);
  });

  test('keeps the whole history scrubbable (no frame cap)', () async {
    final ids = [for (var i = 0; i < 500; i++) '${1700000000000 + i * 600000}'];
    final layer = RadarMapLayer(_FakeRadarRepository(ids.reversed.toList()));

    final frames = (await layer.frames()).valueOrNull!;

    expect(frames.length, 500); // all of them, not a recent slice
    expect(frames.first.id, ids.first);
    expect(frames.last.id, ids.last);
  });
}
