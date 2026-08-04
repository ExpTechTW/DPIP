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
      controller.sentKeys.clear();

      await layer.show(controller, frames[5], scrubbing: true);

      expect(controller.calls, [
        'set:radar-lyr-${frames[4].id}:0.0',
        'set:radar-lyr-${frames[5].id}:0.85',
      ]);
      expect(
        controller.sentKeys,
        everyElement(equals({'raster-opacity'})),
        reason:
            'the scrub path must not re-send visibility or the seven other '
            'raster properties the layer type has',
      );
    },
  );

  test('frames mount with no opacity transition', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]);

    expect(controller.mountTransitions, isNotEmpty);
    expect(
      controller.mountTransitions.values,
      everyElement(equals({'duration': 0, 'delay': 0})),
      reason:
          "raster-opacity's style-spec default is a 300 ms cross-fade, which "
          'makes every scrub step lag the finger and blend two frames',
    );
  });

  test('dragging past the ring still reveals the frame', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    controller.calls.clear();

    await layer.show(controller, frames[0], scrubbing: true);

    expect(
      controller.opacityOf('radar-lyr-${frames[0].id}'),
      '0.85',
      reason:
          'skipping this froze the map on the old frame until the finger '
          'came up — the whole drag showed nothing',
    );
    expect(controller.calls, contains('addSource:radar-src-${frames[0].id}'));
  });

  test('a mid-drag reveal does not widen the ring', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    await layer.show(controller, frames[0], scrubbing: true);
    controller.calls.clear();

    await layer.show(controller, frames[8], scrubbing: true);

    // frames[0] joined nothing: it stops drawing and loading outright, so a
    // long drag can't leave a trail of live sources behind it.
    expect(controller.visibilityOf('radar-lyr-${frames[0].id}'), 'none');
    expect(
      controller.visibilityOf('radar-lyr-${frames[3].id}'),
      'visible',
      reason: 'a real ring member only fades out, keeping its tiles',
    );
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

  test('a settle warms well beyond the mounted ring', () async {
    // 25 frames so the ±4 warm band is a strict subset, not the whole list.
    final source = _FakeRadarRepository(_ids(25));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[12]);

    expect(
      source.warmed.last,
      unorderedEquals([for (var i = 8; i <= 16; i++) frames[i].id]),
      reason:
          'warming is a local read plus a memory push, so the band a drag '
          'can cross without touching disk is far cheaper to widen than the '
          'band kept mounted',
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
