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
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1786208400000', '1786209600000']);
  });

  test('a settle mounts the preload ring at forecast opacity', () async {
    final layer = QpesumsMapLayer(_FakeQpesumsRepository(_ids(5)));
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);

    expect(controller.opacityOf('qpesums-lyr-${frames[2].id}'), '0.85');
  });

  test(
    'scrubbing inside the ring is two opacity writes, nothing else',
    () async {
      final layer = QpesumsMapLayer(_FakeQpesumsRepository(_ids(9)));
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[4]);
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
    final layer = QpesumsMapLayer(source);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.clear(controller);

    expect(source.released, 1);
  });

  testWidgets('timeline caption says forecast, not observed', (tester) async {
    final layer = QpesumsMapLayer(_FakeQpesumsRepository(const []));
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
    final layer = QpesumsMapLayer(_FakeQpesumsRepository(const []));
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
}

/// [count] forecast frame ids, newest first (the wire order), 10-min steps.
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1786208400000 + i * 600000}',
];
