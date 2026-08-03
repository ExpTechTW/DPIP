import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _FakeRadarRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/radar/$frame/{z}/{x}/{y}.webp';
}

void main() {
  test('frames chronological', () async {
    final layer = RadarMapLayer(
      _FakeRadarRepository(['1700000600', '1700000000']),
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000', '1700000600']);
  });

  test('a settle mounts the preload ring around the target', () async {
    final source = _FakeRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    // Index 4 with ringRadius 2 → frames 2..6 mounted, 4 at full opacity.
    await layer.show(controller, frames[4]);

    expect(
      controller.calls.where((c) => c.startsWith('addSource:')).length,
      5,
      reason: 'the ring is current ±2',
    );
    expect(controller.opacityOf('radar-lyr-${frames[4].id}'), '0.85');
    for (final i in [2, 3, 5, 6]) {
      expect(
        controller.visibilityOf('radar-lyr-${frames[i].id}'),
        'visible',
        reason: 'neighbours stay visible so their tiles stay loaded',
      );
      expect(controller.opacityOf('radar-lyr-${frames[i].id}'), '0.0');
    }
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
      controller.calls.clear();

      await layer.show(controller, frames[5], scrubbing: true);

      expect(controller.calls, [
        'set:radar-lyr-${frames[4].id}:visible:0.0',
        'set:radar-lyr-${frames[5].id}:visible:0.85',
      ]);
    },
  );

  test('a cold frame mid-drag is skipped, not mounted', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]);
    controller.calls.clear();

    await layer.show(controller, frames[0], scrubbing: true);

    expect(controller.calls, isEmpty);
  });

  test('a settle abandons the frames the scrub swept past', () async {
    final source = _FakeRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[1]); // ring 0..3
    source.abandoned.clear();
    await layer.show(controller, frames[7]); // ring 5..8

    expect(
      source.abandoned,
      unorderedEquals([frames[0].id, frames[1].id, frames[2].id, frames[3].id]),
      reason: 'only the frames that left the ring, so the target keeps loading',
    );
  });

  test('a settle warms the new ring before mounting it', () async {
    final source = _FakeRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]);

    expect(
      source.warmed.last,
      unorderedEquals([
        for (final i in [2, 3, 4, 5, 6]) frames[i].id,
      ]),
    );
  });

  test('clear releases tiles and removes every mounted frame', () async {
    final source = _FakeRadarRepository(_ids(5));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    controller.calls.clear();

    await layer.clear(controller);

    expect(source.released, 1);
    expect(
      controller.calls.where((c) => c.startsWith('removeSource:')).length,
      5,
    );
  });

  test('history length uncapped', () async {
    final ids = [for (var i = 0; i < 500; i++) '${1700000000 + i * 600}'];
    final layer = RadarMapLayer(_FakeRadarRepository(ids.reversed.toList()));
    expect((await layer.frames()).valueOrNull!.length, 500);
  });
}

/// [count] frame ids, newest first (the wire order).
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1700000000 + i * 600}',
];
