import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
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
}

void main() {
  test('frames chronological', () async {
    final layer = SatelliteMapLayer(
      _FakeSatelliteRepository(['1700000600', '1700000000']),
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000', '1700000600']);
  });

  test('the shown frame is fully opaque', () async {
    final layer = SatelliteMapLayer(_FakeSatelliteRepository(_ids(5)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);

    expect(controller.opacityOf('satellite-lyr-${frames[2].id}'), '1.0');
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final layer = SatelliteMapLayer(_FakeSatelliteRepository(_ids(9)));
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
      controller.calls.clear();

      await layer.show(controller, frames[3], scrubbing: true);

      expect(controller.calls, [
        'set:satellite-lyr-${frames[4].id}:visible:0.0',
        'set:satellite-lyr-${frames[3].id}:visible:1.0',
      ]);
    },
  );

  test('dark boundary outlines are added once and removed on clear', () async {
    final layer = SatelliteMapLayer(_FakeSatelliteRepository(_ids(5)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.show(controller, frames[0]);

    expect(
      controller.calls
          .where((c) => c == 'addLineLayer:$satelliteGlobalOutlineLayerId')
          .length,
      1,
      reason: 'a second settle must not re-add the outlines',
    );

    controller.calls.clear();
    await layer.clear(controller);
    expect(
      controller.calls,
      containsAll([
        'removeLayer:$satelliteCountyOutlineLayerId',
        'removeLayer:$satelliteGlobalOutlineLayerId',
      ]),
    );
  });

  test('clear releases tiles', () async {
    final source = _FakeSatelliteRepository(_ids(5));
    final layer = SatelliteMapLayer(source);
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
