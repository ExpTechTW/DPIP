import 'package:dpip/features/map/presentation/layers/qpesums_layer.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeQpesumsRepository extends FakeRasterFrameSource
    implements QpesumsRepository {
  _FakeQpesumsRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/qpesums/$frame/{z}/{x}/{y}.webp';
}

void main() {
  test('frames chronological', () async {
    final layer = QpesumsMapLayer(
      _FakeQpesumsRepository(['1786209600000', '1786208400000']),
      testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1786208400000', '1786209600000']);
  });

  test('a settle mounts the preload ring at forecast opacity', () async {
    final layer = QpesumsMapLayer(
      _FakeQpesumsRepository(_ids(5)),
      testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);

    expect(controller.opacityOf('qpesums-lyr-${frames[2].id}'), '0.85');
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final layer = QpesumsMapLayer(
        _FakeQpesumsRepository(_ids(9)),
        testReferenceOutline(),
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
      // The attach's admin-chrome sync drains after `show` returns; this test
      // pins the scrub's write set exactly, so flush it before clearing.
      await pumpEventQueue();
      controller.calls.clear();
      controller.sentKeys.clear();

      await layer.show(controller, frames[5], scrubbing: true);

      expect(controller.calls, [
        'set:qpesums-lyr-${frames[4].id}:0.0',
        'set:qpesums-lyr-${frames[5].id}:0.85',
      ]);
      expect(
        controller.sentKeys,
        everyElement(equals({'raster-opacity', 'raster-opacity-transition'})),
      );
    },
  );

  test('clear releases tiles', () async {
    final source = _FakeQpesumsRepository(_ids(5));
    final layer = QpesumsMapLayer(source, testReferenceOutline());
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.clear(controller);

    expect(source.released, 1);
  });

  testWidgets('timeline caption says forecast, not observed', (tester) async {
    final layer = QpesumsMapLayer(
      _FakeQpesumsRepository(const []),
      testReferenceOutline(),
    );
    String? caption;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            caption = layer.timelineCaption(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(caption, 'Forecast');
  });

  testWidgets('legend renders the QPESUMS mm/h scale', (tester) async {
    final layer = QpesumsMapLayer(
      _FakeQpesumsRepository(const []),
      testReferenceOutline(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (context) => layer.buildLegend(context)),
        ),
      ),
    );

    // Strongest (300) at the top of the scale, weakest (1) at the bottom.
    expect(find.textContaining('mm/h'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  group('overlays', () {
    /// A layer attached to a live map, ready for the toggles.
    Future<(QpesumsMapLayer, RecordingMapController)> attached() async {
      final layer = QpesumsMapLayer(
        _FakeQpesumsRepository(_ids(3)),
        testReferenceOutline(),
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();
      await layer.prepare(controller, frames);
      await layer.show(controller, frames[1]);
      // Drain the mutation queue past the settle's attach: the admin chrome
      // sync runs inside it, so a cold frame's reveal can still be in flight
      // when `show` returns.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return (layer, controller);
    }

    test('all three overlays are on by default and drawn on attach', () async {
      final (layer, controller) = await attached();

      expect(layer.showScanRange, isTrue);
      expect(layer.showCountyOutline, isTrue);
      expect(layer.showTownOutline, isTrue);
      // Its own ids, so radar and QPESUMS can both be on the map at once.
      expect(controller.calls, contains('addSource:qpesums-scan-range'));
      expect(
        controller.calls,
        contains('addLineLayer:qpesums-scan-range-outline'),
      );
      expect(
        controller.calls,
        contains('addLineLayer:admin-county-outline-casing'),
      );
      expect(controller.calls, contains('addLineLayer:admin-county-outline'));
      expect(controller.calls, contains('addLineLayer:admin-town-outline'));
    });

    test('the outline is the forecast rectangle, not radar coverage', () async {
      final (_, controller) = await attached();

      final geo = controller.sourceData['qpesums-scan-range'];
      expect(geo, isNotNull, reason: 'the outline source must carry geometry');
      final feature = (geo!['features'] as List).single as Map;
      final geometry = feature['geometry'] as Map;
      expect(geometry['type'], 'Polygon');
      expect(
        (geometry['coordinates'] as List).single,
        // 118.0–123.5125°E, 20.0–27.0125°N: the grid the forecast is published
        // on, which is not the union of range circles the radars observe.
        [
          [123.5125, 20.0],
          [123.5125, 27.0125],
          [118.0, 27.0125],
          [118.0, 20.0],
          [123.5125, 20.0],
        ],
      );
    });

    test(
      'turning the coverage outline off removes the qpesums ids only',
      () async {
        final (layer, controller) = await attached();
        controller.calls.clear();

        layer.setShowScanRange(false);
        await pumpEventQueue();

        expect(
          controller.calls,
          contains('removeLayer:qpesums-scan-range-outline'),
        );
        expect(controller.calls, contains('removeSource:qpesums-scan-range'));
        expect(
          controller.calls.where((c) => c.contains('radar-scan-range')),
          isEmpty,
          reason: 'radar\'s outline, if shown, must not be touched',
        );
      },
    );

    test('the toggles are independent', () async {
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
      expect(layer.showCountyOutline, isTrue);
    });

    test('clear tears the chrome down with the layer', () async {
      final (layer, controller) = await attached();
      controller.calls.clear();

      await layer.clear(controller);

      expect(controller.calls, contains('removeSource:qpesums-scan-range'));
      expect(controller.calls, contains('removeLayer:admin-county-outline'));
    });

    test('a style reset re-adds the chrome on the next attach', () async {
      final (layer, _) = await attached();

      layer.onStyleReset();
      final frames = (await layer.frames()).valueOrNull!;
      final fresh = RecordingMapController();
      await layer.prepare(fresh, frames);
      await layer.show(fresh, frames[1]);

      expect(fresh.calls, contains('addSource:qpesums-scan-range'));
      expect(fresh.calls, contains('addLineLayer:admin-county-outline'));
    });
  });
}

/// [count] forecast frame ids, newest first (the wire order), 10-min steps.
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1786208400000 + i * 600000}',
];
