/// The tile-pyramid cap reaches the MapLibre source, not just the warmer.
///
/// `RasterFrameSource.sourceMaxZoom` exists so a pinch past the data's last
/// real zoom level overzooms the top band instead of issuing doomed requests
/// — on Android every one of those is a platform-thread round trip the
/// gesture has to wait behind. This pins the pass-through: whatever the
/// source declares is what the mounted raster source carries as `maxzoom`.
library;

import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

/// Frame ids newest first, 10 minutes apart — the shape radar's list returns.
List<String> _ids(int count) => [
  for (var i = 0; i < count; i++) (1700000000 + (count - i) * 600).toString(),
];

class _CappedRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _CappedRadarRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://tiles.example.dev/radar/$frame/{z}/{x}/{y}.webp';
}

void main() {
  test('mounted radar sources carry both pyramid bounds', () async {
    final source = _CappedRadarRepository(_ids(9))
      ..sourceMinZoom = 3
      ..sourceMaxZoom = 8;
    final layer = RadarMapLayer(source, testReferenceOutline());
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    // Index 4 with ringRadius 2 mounts frames 2..6.
    await layer.show(controller, frames[4]);

    final mounted = Map.fromEntries(
      controller.sourceProperties.entries.where(
        (entry) => entry.key.startsWith('radar-src-'),
      ),
    );
    expect(mounted, isNotEmpty, reason: 'the ring must have mounted sources');
    for (final entry in mounted.entries) {
      expect(
        entry.value['minzoom'],
        3.0,
        reason:
            '${entry.key} must not request placeholder tiles below the '
            'published pyramid',
      );
      expect(
        entry.value['maxzoom'],
        8.0,
        reason:
            '${entry.key} must cap at the source pyramid instead of '
            'requesting placeholder tiles above it',
      );
      expect(entry.value['tileSize'], 256);
    }
  });

  test('an unconfigured fake keeps the MapLibre raster defaults', () async {
    // Guards against the cap accidentally leaking into sources whose data
    // really does extend to the camera ceiling: the default stays 22, which
    // means "no cap" for the fake rather than leaking another source's range.
    final source = _CappedRadarRepository(_ids(9));
    expect(source.sourceMaxZoom, 22);
  });
}
