import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
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
      controller.calls
          .where((c) => c.startsWith('addSource:radar-src-'))
          .length,
      5,
      reason: 'the ring is current ±2; the overlays add sources of their own',
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
        everyElement(equals({'raster-opacity', 'raster-opacity-transition'})),
        reason:
            'the scrub path must not re-send visibility or the seven other '
            'raster properties the layer type has — only the opacity and the '
            'zero cross-fade that keeps a scrub a loop instead of a smear',
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

  test('flipping back over a mid-drag-revealed frame hides it', () async {
    final layer = RadarMapLayer(_FakeRadarRepository(_ids(9)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    // Drag past the ring, then bounce back into it — a fast fling's shape.
    await layer.show(controller, frames[0], scrubbing: true);
    await layer.show(controller, frames[5], scrubbing: true);

    expect(
      controller.visibilityOf('radar-lyr-${frames[0].id}'),
      'none',
      reason:
          'the cold frame was never part of the ring, so the flip back into '
          'it must hide it outright — an opacity-0 fade leaves it at full '
          'strength ghosting behind the ring while the drag bounces around',
    );
    expect(controller.opacityOf('radar-lyr-${frames[5].id}'), '0.85');
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

  test('a settle warms outward from the frame, far beyond the ring', () async {
    // 25 frames so the ±4 ring is a strict subset of the warm spread.
    final source = _FakeRadarRepository(_ids(25));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[12]);

    final warmed = source.warmed.last;
    expect(warmed, hasLength(25), reason: 'the fill warm spreads to the edge');
    expect(warmed.first, frames[12].id, reason: 'nearest-the-finger first');
    expect(
      [warmed[1], warmed[2]],
      unorderedEquals([frames[13].id, frames[11].id]),
      reason:
          'the spread walks outward ±1, ±2, … so fill warm injects the '
          'nearest frames first and only the most distant stay cold',
    );
  });

  test('a scrub reveal past the warm band re-warms around the finger', () async {
    final source = _FakeRadarRepository(_ids(25));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[12]); // settle → warm 12, ±1, ±2 …
    source.warmed.clear();

    // Still inside the ±4 guaranteed band: revealing must not re-warm (or
    // re-fetch the visible region) — the band already covers this mount.
    await layer.show(controller, frames[16], scrubbing: true);
    await pumpEventQueue();
    expect(
      source.warmed,
      isEmpty,
      reason:
          'every scrub frame inside the warmed band costs one mount and no '
          'store re-read, so the warm does not chase the finger frame by frame',
    );

    // Crossed the guaranteed band edge: the warm re-centres on the finger and
    // spreads outward again, so the rest of a long drag stays on memory hits
    // instead of store reads.
    await layer.show(controller, frames[20], scrubbing: true);
    await pumpEventQueue();
    final reWarmed = source.warmed.last;
    expect(reWarmed.first, frames[20].id, reason: 're-warms around the finger');
    expect(
      [reWarmed[1], reWarmed[2]],
      unorderedEquals([frames[21].id, frames[19].id]),
      reason:
          'revealing a frame the last-warmed band did not cover re-warms '
          'around it, so a drag never lands past a warmed mount',
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
      controller.calls
          .where((c) => c.startsWith('removeSource:radar-src-'))
          .length,
      5,
      reason: 'the frame sources; the overlays tear down separately',
    );
  });

  test('history length uncapped', () async {
    final ids = [for (var i = 0; i < 500; i++) '${1700000000 + i * 600}'];
    final layer = RadarMapLayer(_FakeRadarRepository(ids.reversed.toList()));
    expect((await layer.frames()).valueOrNull!.length, 500);
  });

  group('overlays', () {
    /// A layer attached to a live map, ready for the toggles.
    Future<(RadarMapLayer, RecordingMapController)> attached() async {
      final layer = RadarMapLayer(_FakeRadarRepository(_ids(3)));
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();
      await layer.prepare(controller, frames);
      await layer.show(controller, frames[1]);
      return (layer, controller);
    }

    test('both overlays are on by default and drawn on attach', () async {
      final (layer, controller) = await attached();

      // Blank outside the coverage means "not observed", and a county you
      // cannot identify is a county you cannot act on. Neither should have to
      // be found in a menu first.
      expect(layer.showScanRange.value, isTrue);
      expect(layer.showCountyOutline.value, isTrue);
      expect(layer.showTownOutline.value, isTrue);
      expect(controller.calls, contains('addSource:radar-scan-range'));
      expect(
        controller.calls,
        contains('addLineLayer:radar-scan-range-outline'),
      );
      expect(
        controller.calls,
        contains('addLineLayer:admin-county-outline-casing'),
      );
      expect(controller.calls, contains('addLineLayer:admin-county-outline'));
      expect(
        controller.calls,
        contains('addLineLayer:admin-town-outline-casing'),
      );
      expect(controller.calls, contains('addLineLayer:admin-town-outline'));
    });

    test('the echo is mounted above the base style borders', () async {
      final (_, controller) = await attached();
      // The base style draws its own borders under the raster. Leaving the echo
      // beneath them meant they always showed through, so the switchable copies
      // on top would have been a second set at a second weight — and switching
      // them off would still not have given a clean raster.
      for (final call in controller.calls.where(
        (c) => c.startsWith('addRasterLayer:'),
      )) {
        expect(controller.belowOf(call.split(':').last), isNull, reason: call);
      }
    });

    test('the county and township toggles are independent', () async {
      final (layer, controller) = await attached();
      controller.calls.clear();

      layer.setShowTownOutline(false);
      await pumpEventQueue();

      expect(controller.calls, contains('removeLayer:admin-town-outline'));
      expect(
        controller.calls.where((c) => c.contains('admin-county-outline')),
        isEmpty,
        reason: 'dropping the fine mesh must not take the coarse frame with it',
      );
      expect(layer.showCountyOutline.value, isTrue);
    });

    test('the township mesh is drawn lighter than the county frame', () {
      // 368 townships at the county stroke turns the island into a net and
      // buries the echo the borders are meant to sit over.
      expect(
        AdminBoundary.town.lineWidth,
        lessThan(AdminBoundary.county.lineWidth),
      );
      expect(
        AdminBoundary.town.lineOpacity,
        lessThan(AdminBoundary.county.lineOpacity),
      );
    });

    test('the coverage outline has no fill', () async {
      final (_, controller) = await attached();
      // A wash over the covered area would tint every dBZ colour under it.
      expect(
        controller.calls.where((c) => c.startsWith('addFillLayer:')),
        isEmpty,
      );
    });

    test('the county border is drawn above the raster', () async {
      final (_, controller) = await attached();
      // The base style already outlines counties *below* the echo, where they
      // disappear. These redraw over the raster, but still under the township
      // labels — a border line must never cross a place name.
      expect(controller.belowOf('admin-county-outline'), townLabelLayerId);
      expect(
        controller.belowOf('admin-county-outline-casing'),
        townLabelLayerId,
      );
    });

    test('turning the coverage outline off removes what it added', () async {
      final (layer, controller) = await attached();
      controller.calls.clear();

      layer.setShowScanRange(false);
      await pumpEventQueue();

      expect(
        controller.calls,
        contains('removeLayer:radar-scan-range-outline'),
      );
      expect(controller.calls, contains('removeSource:radar-scan-range'));
    });

    test('turning the county border off removes both strokes', () async {
      final (layer, controller) = await attached();
      controller.calls.clear();

      layer
        ..setShowCountyOutline(false)
        ..setShowTownOutline(false);
      await pumpEventQueue();

      expect(controller.calls, contains('removeLayer:admin-county-outline'));
      expect(
        controller.calls,
        contains('removeLayer:admin-county-outline-casing'),
      );
      expect(controller.calls, contains('removeLayer:admin-town-outline'));
      // The vector source is the base style's; removing it would wipe the map.
      expect(
        controller.calls.where((c) => c == 'removeSource:exptech'),
        isEmpty,
      );
    });

    test('the toggles are independent', () async {
      final (layer, controller) = await attached();
      layer.setShowScanRange(false);
      await pumpEventQueue();
      controller.calls.clear();

      layer.setShowCountyOutline(false);
      await pumpEventQueue();

      expect(
        controller.calls.where((c) => c.contains('radar-scan-range')),
        isEmpty,
      );
    });

    test('setting the same value twice touches the map once', () async {
      final (layer, controller) = await attached();
      layer.setShowScanRange(false);
      await pumpEventQueue();
      controller.calls.clear();

      layer.setShowScanRange(false);
      await pumpEventQueue();

      expect(controller.calls, isEmpty);
    });

    test('clear tears both overlays down with the layer', () async {
      final (layer, controller) = await attached();
      controller.calls.clear();

      await layer.clear(controller);

      expect(controller.calls, contains('removeSource:radar-scan-range'));
      expect(controller.calls, contains('removeLayer:admin-county-outline'));
    });

    test('clear with an overlay off issues no removals for it', () async {
      final (layer, controller) = await attached();
      layer.setShowScanRange(false);
      await pumpEventQueue();
      controller.calls.clear();

      await layer.clear(controller);

      expect(
        controller.calls.where((c) => c.contains('radar-scan-range')),
        isEmpty,
        reason:
            'tearing down an overlay that was never added is a no-op the map '
            'should never be asked to perform',
      );
    });

    test('a style reset re-adds both on the next attach', () async {
      final (layer, _) = await attached();

      // The style reload wiped every runtime source/layer under the layer's
      // feet; nothing may be removed, only forgotten.
      layer.onStyleReset();
      final frames = (await layer.frames()).valueOrNull!;
      final fresh = RecordingMapController();
      await layer.prepare(fresh, frames);
      await layer.show(fresh, frames[1]);

      expect(
        fresh.calls,
        contains('addSource:radar-scan-range'),
        reason:
            'without forgetting the old state the overlays would never '
            'come back, because the layer still thought they were drawn',
      );
      expect(fresh.calls, contains('addLineLayer:admin-county-outline'));
    });
  });
}

/// [count] frame ids, newest first (the wire order).
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1700000000 + i * 600}',
];
