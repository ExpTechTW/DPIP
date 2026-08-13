import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeSatelliteRepository extends FakeRasterFrameSource
    implements SatelliteRepository {
  _FakeSatelliteRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/satellite/$frame/{z}/{x}/{y}.webp';

  @override
  void setStyle(String? style) {}
}

void main() {
  test('frames chronological', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(['1700000600', '1700000000']),
      channel: SatelliteChannel.irClean,
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000', '1700000600']);
  });

  test('the shown frame is fully opaque', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(_ids(5)),
      channel: SatelliteChannel.irClean,
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);

    expect(controller.opacityOf('satellite-lyr-${frames[2].id}'), '1.0');
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final layer = SatelliteMapLayer(
        _FakeSatelliteRepository(_ids(9)),
        channel: SatelliteChannel.irClean,
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
      controller.calls.clear();
      controller.sentKeys.clear();

      await layer.show(controller, frames[3], scrubbing: true);

      expect(controller.calls, [
        'set:satellite-lyr-${frames[4].id}:0.0',
        'set:satellite-lyr-${frames[3].id}:1.0',
      ]);
      expect(
        controller.sentKeys,
        everyElement(equals({'raster-opacity', 'raster-opacity-transition'})),
        reason:
            'the scrub path must not re-send visibility or the seven other '
            'raster properties the layer type has — only the opacity and the '
            'zero cross-fade that keeps a scrub a loop instead of a smear',
      );
    },
  );

  test('bright yellow county and town outlines are added once and removed on clear', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(_ids(5)),
      channel: SatelliteChannel.irClean,
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.show(controller, frames[0]);

    expect(
      controller.calls
          .where((c) => c == 'addLineLayer:$satelliteCountyOutlineLayerId')
          .length,
      1,
      reason: 'a second settle must not re-add the outlines',
    );
    expect(
      controller.calls,
      contains('addLineLayer:$satelliteGlobalOutlineLayerId'),
      reason: 'the 國界 border ships on by default',
    );

    controller.calls.clear();
    await layer.clear(controller);
    expect(
      controller.calls,
      containsAll([
        'removeLayer:$satelliteTownOutlineLayerId',
        'removeLayer:$satelliteCountyOutlineLayerId',
        'removeLayer:$satelliteGlobalOutlineLayerId',
      ]),
    );
  });

  test('the 國界 border toggles on and off', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(_ids(5)),
      channel: SatelliteChannel.irClean,
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    controller.calls.clear();

    layer.setShowGlobalOutline(false);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      controller.calls,
      contains('removeLayer:$satelliteGlobalOutlineLayerId'),
    );

    controller.calls.clear();
    layer.setShowGlobalOutline(true);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      controller.calls,
      contains('addLineLayer:$satelliteGlobalOutlineLayerId'),
    );
  });

  test('clear releases tiles', () async {
    final source = _FakeSatelliteRepository(_ids(5));
    final layer = SatelliteMapLayer(source, channel: SatelliteChannel.irClean);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.clear(controller);

    expect(source.released, 1);
  });
}

/// [count] frame ids, newest first (the wire order).
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1700000000 + i * 600}',
];
