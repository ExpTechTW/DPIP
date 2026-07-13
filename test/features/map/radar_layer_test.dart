import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class _FakeRadarRepository implements RadarRepository {
  _FakeRadarRepository(this._frames);
  final List<String> _frames;

  @override
  Future<Result<List<String>>> frames() async => Ok(_frames);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.png';
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

  test('re-renders the same frame after a style reset', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(['1700000000000']));
    final frame = (await layer.frames()).valueOrNull!.single;
    final controller = _RecordingController();

    await layer.render(controller, frame);
    expect(controller.calls, [
      'addSource:radar-source',
      'addRasterLayer:radar-layer',
    ]);

    // Same frame again → idempotent, no controller churn.
    controller.calls.clear();
    await layer.render(controller, frame);
    expect(controller.calls, isEmpty);

    // After a base-style reload wiped the map, the same frame must re-add.
    controller.calls.clear();
    layer.onStyleReset();
    await layer.render(controller, frame);
    expect(controller.calls, contains('addSource:radar-source'));
  });
}
