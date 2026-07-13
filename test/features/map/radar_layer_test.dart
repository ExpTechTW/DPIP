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

  test(
    'preloads all frames hidden, then windows a drawn frame + neighbours',
    () async {
      // Four frames, chronological ids f0..f3.
      final layer = RadarMapLayer(
        _FakeRadarRepository([
          '1700001800000', // f3 (newest, API is newest-first)
          '1700001200000', // f2
          '1700000600000', // f1
          '1700000000000', // f0
        ]),
      );
      final frames = (await layer.frames()).valueOrNull!; // [f0, f1, f2, f3]
      final controller = _RecordingController();

      await layer.prepare(controller, frames);
      // Every frame added as a hidden raster source + layer.
      expect(
        controller.calls.where((c) => c.startsWith('addSource')).length,
        4,
      );
      expect(
        controller.calls.where((c) => c.startsWith('addRasterLayer')).length,
        4,
      );

      // Preparing again is idempotent (no duplicate adds).
      controller.calls.clear();
      await layer.prepare(controller, frames);
      expect(controller.calls, isEmpty);

      // Show newest (f3) → window {f2, f3}: f2 prefetches, f3 is drawn.
      controller.calls.clear();
      await layer.show(controller, frames[3]);
      expect(controller.calls, [
        'set:radar-lyr-1700001200000:visible:0', // f2 prefetch
        'set:radar-lyr-1700001800000:visible:0.85', // f3 drawn
      ]);

      // Scrub to the oldest (f0) → window {f0, f1}: hide the frames that left,
      // draw f0, prefetch f1.
      controller.calls.clear();
      await layer.show(controller, frames[0]);
      expect(controller.calls, [
        'set:radar-lyr-1700001200000:none:0', // f2 left the window
        'set:radar-lyr-1700001800000:none:0', // f3 left the window
        'set:radar-lyr-1700000000000:visible:0.85', // f0 drawn
        'set:radar-lyr-1700000600000:visible:0', // f1 prefetch
      ]);

      // Same frame again → no-op.
      controller.calls.clear();
      await layer.show(controller, frames[0]);
      expect(controller.calls, isEmpty);

      // After a base-style reload wiped the map, prepare must re-add everything.
      controller.calls.clear();
      layer.onStyleReset();
      await layer.prepare(controller, frames);
      expect(
        controller.calls.where((c) => c.startsWith('addSource')).length,
        4,
      );
    },
  );
}
