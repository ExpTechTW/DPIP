import 'dart:async';

import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_style.dart'
    show outlineLayerId, townLabelLayerId;
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/shared/map/raster_frame_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _FakeRadarRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/radar/$frame/{z}/{x}/{y}.webp';
}

class _BlockingWarmRadarRepository extends _FakeRadarRepository {
  _BlockingWarmRadarRepository(super.frames);

  final Completer<void> warmGate = Completer<void>();

  @override
  Future<void> warmFrameTiles({
    required List<String> frames,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool fill = false,
    bool immediate = false,
  }) {
    warmed.add(List<String>.of(frames));
    return warmGate.future;
  }
}

class _ControlledReadinessRadarRepository extends _FakeRadarRepository {
  _ControlledReadinessRadarRepository(super.frames);

  bool ready = true;
  int probes = 0;

  @override
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  }) async {
    probes++;
    readinessProbes.add((frame: frame, warm: warm));
    return (ready: ready, resident: ready ? 6 : 2, required: 6);
  }
}

class _BlockedNeighbourRadarRepository extends _FakeRadarRepository {
  _BlockedNeighbourRadarRepository(super.frames);

  late String blockedFrame;
  final Completer<void> blockedProbe = Completer<void>();

  @override
  Future<FrameTileReadiness> frameTileReadiness({
    required String frame,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
    bool warm = false,
  }) async {
    readinessProbes.add((frame: frame, warm: warm));
    if (frame != blockedFrame) {
      return (ready: true, resident: 1, required: 1);
    }
    if (!blockedProbe.isCompleted) blockedProbe.complete();
    return (ready: false, resident: 0, required: 1);
  }
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
    expect(
      controller.calls.where((c) => c == 'addSource:radar-frame-seam-src'),
      hasLength(1),
      reason: 'parallel cold mounts must share one in-flight seam creation',
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

  test('a blocked warm cannot leave two timestamps at full opacity', () async {
    final source = _BlockingWarmRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[1]);
    await pumpEventQueue();
    expect(source.warmed, isNotEmpty);

    // Jump far enough to force a settle rather than an in-ring flip. The warm
    // future never completes during these assertions; display correctness must
    // therefore be independent of cache injection.
    await layer.show(controller, frames[7]);

    expect(controller.opacityOf('radar-lyr-${frames[7].id}'), '0.85');
    expect(controller.opacityOf('radar-lyr-${frames[1].id}'), '0');
    expect(
      controller.visibilityOf('radar-lyr-${frames[1].id}'),
      'none',
      reason: 'the old timestamp must stop drawing before warming finishes',
    );

    source.warmGate.complete();
    await pumpEventQueue();
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final source = _FakeRadarRepository(_ids(9));
      final layer = RadarMapLayer(source);
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
      expect(source.readinessProbes, [
        (frame: frames[5].id, warm: false),
      ], reason: 'scrubbing may probe L1 but must never read or inject L2');
    },
  );

  test('frames mount without opacity or per-tile fades', () async {
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
    expect(
      controller.mountTileFades.values,
      everyElement(0),
      reason:
          "raster-fade-duration's separate 300 ms default makes an L1 hit "
          'flash transparent whenever its source is mounted again',
    );
  });

  test('an idle-preloaded scrub target restores and flips from L1', () async {
    final source = _FakeRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    await pumpEventQueue();
    controller.calls.clear();
    source.warmed.clear();
    source.readinessProbes.clear();

    await layer.show(controller, frames[0], scrubbing: true);

    expect(controller.opacityOf('radar-lyr-${frames[4].id}'), '0.0');
    expect(controller.opacityOf('radar-lyr-${frames[0].id}'), '0.85');
    expect(controller.calls, [
      'set:radar-lyr-${frames[0].id}:0.0',
      'set:radar-lyr-${frames[4].id}:0.0',
      'set:radar-lyr-${frames[0].id}:0.85',
    ]);
    expect(
      source.readinessProbes,
      isEmpty,
      reason: 'the completed idle preload is already an L1 readiness proof',
    );
    expect(source.warmed, isEmpty);
    expect(source.warmCancels, 1);
  });

  test(
    'idle settle fills the resident ceiling without extra draw passes',
    () async {
      final source = _FakeRadarRepository(_ids(40));
      final layer = RadarMapLayer(source);
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[20]);
      await pumpEventQueue();

      expect(
        controller.calls.where(
          (call) => call.startsWith('addSource:radar-src-'),
        ),
        hasLength(32),
        reason: 'idle preload uses every source slot but never exceeds the cap',
      );
      final visible = [
        for (final frame in frames)
          if (controller.visibilityOf('radar-lyr-${frame.id}') == 'visible')
            frame.id,
      ];
      final hidden = [
        for (final frame in frames)
          if (controller.visibilityOf('radar-lyr-${frame.id}') == 'none')
            frame.id,
      ];
      expect(visible, frames.sublist(18, 23).map((frame) => frame.id));
      expect(
        hidden,
        hasLength(27),
        reason: 'prepared neighbours stay resident without raster draw passes',
      );
      expect(
        source.readinessProbes,
        hasLength(27),
        reason: 'one completion probe per neighbour, never parallel fan-out',
      );
      expect(
        source.readinessProbes,
        everyElement(
          isA<({String frame, bool warm})>().having(
            (probe) => probe.warm,
            'warm',
            isFalse,
          ),
        ),
      );
    },
  );

  test('a gesture stops idle expansion at its one in-flight frame', () async {
    final ids = _ids(40);
    final source = _BlockedNeighbourRadarRepository(ids);
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    source.blockedFrame = frames[23].id;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[20]);
    await source.blockedProbe.future.timeout(const Duration(seconds: 1));

    await layer.show(controller, frames[21], scrubbing: true);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(source.warmCancels, 1);
    expect(
      controller.calls.where((call) => call.startsWith('addSource:radar-src-')),
      hasLength(6),
      reason: 'the five-frame core plus only one cold neighbour may be active',
    );
    expect(
      source.readinessProbes.where((probe) => probe.frame == frames[17].id),
      isEmpty,
      reason: 'the next neighbour must not mount after the gesture starts',
    );
  });

  test(
    'one gesture cancels warm once and restarts it after settling',
    () async {
      final source = _FakeRadarRepository(_ids(12));
      final layer = RadarMapLayer(source);
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
      await pumpEventQueue();
      source.warmed.clear();

      await layer.show(controller, frames[0], scrubbing: true);
      await layer.show(controller, frames[11], scrubbing: true);
      await layer.show(controller, frames[4], scrubbing: true);

      expect(source.warmCancels, 1, reason: 'one gesture has one cancellation');
      expect(source.warmed, isEmpty);

      await layer.show(controller, frames[4]);
      await pumpEventQueue();

      expect(source.warmed, hasLength(1));
      expect(source.warmed.single.first, frames[4].id);
    },
  );

  test('a long cached scrub keeps the resident source set bounded', () async {
    final source = _FakeRadarRepository(_ids(40));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[20]);
    await pumpEventQueue();
    source.warmed.clear();
    source.readinessProbes.clear();

    for (final frame in frames) {
      await layer.show(controller, frame, scrubbing: true);
    }

    final added = controller.calls
        .where((call) => call.startsWith('addSource:radar-src-'))
        .length;
    final removed = controller.calls
        .where((call) => call.startsWith('removeSource:radar-src-'))
        .length;
    expect(added - removed, lessThanOrEqualTo(32));
    expect(
      source.warmed,
      isEmpty,
      reason: 'scrubbing must never launch an L2 warm',
    );
    expect(
      source.readinessProbes,
      everyElement(
        isA<({String frame, bool warm})>().having(
          (probe) => probe.warm,
          'warm',
          isFalse,
        ),
      ),
      reason: 'every off-ring decision is an L1-only probe',
    );
  });

  test('a cold fast scrub mounts only the final ring on finger-up', () async {
    final source = _ControlledReadinessRadarRepository(_ids(12));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    source.ready = false;
    await layer.show(controller, frames[0], scrubbing: true);
    await layer.show(controller, frames[11], scrubbing: true);
    controller.calls.clear();
    source.readinessProbes.clear();
    source.ready = true;

    await layer.show(controller, frames[11]);

    expect(
      controller.calls.where((call) => call.startsWith('addSource:radar-src-')),
      [
        'addSource:radar-src-${frames[9].id}',
        'addSource:radar-src-${frames[10].id}',
        'addSource:radar-src-${frames[11].id}',
      ],
      reason: 'no source from either intermediate scrub position may leak in',
    );
    expect(controller.opacityOf('radar-lyr-${frames[11].id}'), '0.85');
    expect(source.readinessProbes, [
      (frame: frames[11].id, warm: true),
    ], reason: 'only the settled target may reach L2');
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

  test('finger-up settles the cold frame held during scrubbing', () async {
    final source = _ControlledReadinessRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]); // ring 2..6
    source.ready = false;
    await layer.show(controller, frames[8], scrubbing: true); // held on frame 4

    expect(controller.opacityOf('radar-lyr-${frames[4].id}'), '0.85');
    // Finger-up is the only cold mount and moves the ring directly to 6..8.
    source.ready = true;
    await layer.show(controller, frames[8]); // ring 6..8

    for (final i in [2, 3, 4, 5]) {
      expect(controller.visibilityOf('radar-lyr-${frames[i].id}'), 'none');
    }
    expect(controller.opacityOf('radar-lyr-${frames[8].id}'), '0.85');
  });

  test('a settle warms outward from the frame, far beyond the ring', () async {
    // 25 frames so the ±4 ring is a strict subset of the warm spread.
    final source = _FakeRadarRepository(_ids(25));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[12]);
    await pumpEventQueue();

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

  test('a settled fill uses the full frame budget at a series edge', () async {
    final source = _FakeRadarRepository(_ids(700));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames.last);
    await pumpEventQueue();

    final warmed = source.warmed.single;
    expect(warmed, hasLength(512));
    expect(warmed.first, frames.last.id);
    expect(
      warmed.last,
      frames[frames.length - 512].id,
      reason: 'the missing future side is reassigned to older cached frames',
    );
  });

  test('scrubbing never launches a whole-history warm scan', () async {
    final source = _FakeRadarRepository(_ids(25));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[12]); // settle → warm 12, ±1, ±2 …
    await pumpEventQueue();
    source.warmed.clear();

    // Revealing an L1-complete frame may mount its source, but must not re-warm
    // or re-fetch it from the store — the previous fill already injected it.
    await layer.show(controller, frames[16], scrubbing: true);
    await pumpEventQueue();
    expect(
      source.warmed,
      isEmpty,
      reason:
          'a cached scrub frame costs one mount and no store re-read, so the '
          'warm does not chase the finger frame by frame',
    );

    // Even after crossing the old warm-band edge, scrubbing remains an L1-only
    // operation. The device trace showed the old scan probing 1,300–1,780 cold
    // SQLite keys every 120 ms with zero L2 hits while competing with the source
    // mounts that actually drive network loading.
    await layer.show(controller, frames[20], scrubbing: true);
    await pumpEventQueue();
    await layer.show(controller, frames[4], scrubbing: true);
    await pumpEventQueue();
    expect(source.warmed, isEmpty);
  });

  test('a cold scrub target cannot replace the complete frame', () async {
    final source = _ControlledReadinessRadarRepository(_ids(9));
    final layer = RadarMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[4]);
    source.ready = false;
    source.probes = 0;
    controller.calls.clear();

    await layer.show(controller, frames[0], scrubbing: true);

    expect(controller.opacityOf('radar-lyr-${frames[4].id}'), '0.85');
    expect(controller.calls, isEmpty);
    expect(
      source.probes,
      1,
      reason: 'a cold scrub target is checked in L1 without touching L2',
    );
    expect(source.readinessProbes, [(frame: frames[0].id, warm: false)]);

    source.ready = true;
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(controller.opacityOf('radar-lyr-${frames[4].id}'), '0.85');
    await layer.show(controller, frames[0]);
    expect(source.probes, 2);
    expect(source.readinessProbes.last, (frame: frames[0].id, warm: true));
    expect(controller.opacityOf('radar-lyr-${frames[0].id}'), '0.85');
  });

  test(
    'an older readiness completion cannot overwrite a newer target',
    () async {
      final source = _ControlledReadinessRadarRepository(_ids(12));
      final layer = RadarMapLayer(source);
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[5]);
      source.ready = false;
      await layer.show(controller, frames[0]);

      source.ready = true;
      await layer.show(controller, frames[10]);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(controller.opacityOf('radar-lyr-${frames[10].id}'), '0.85');
      expect(controller.opacityOf('radar-lyr-${frames[0].id}'), isNot('0.85'));
    },
  );

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
      // them off would still not have given a clean raster. The raster anchors
      // just under the township labels, so place names are never buried.
      // Asserted as the resulting order rather than as the anchor string:
      // the frames anchor to this layer's own seam now (so a scrub cannot
      // insert one above the borders — see `layer_stacking_test.dart`), and
      // only the order says whether that still puts them where they belong.
      for (final call in controller.calls.where(
        (c) => c.startsWith('addRasterLayer:'),
      )) {
        final frame = call.split(':').last;
        expect(
          controller.isAbove(frame, outlineLayerId),
          isTrue,
          reason: '$call is under the base style border',
        );
        expect(
          controller.isAbove(townLabelLayerId, frame),
          isTrue,
          reason: '$call buries the township labels',
        );
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
