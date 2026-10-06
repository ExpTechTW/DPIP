/// Empty history, a frame the layer was never prepared with, and the trace
/// lines a real show emits when tile tracing is on.
library;

import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _Radar extends FakeRasterFrameSource implements RadarRepository {
  _Radar(super.frames);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an empty history and an unknown frame show nothing', () async {
    final empty = testRadarLayer(_Radar(const []));
    expect((await empty.frames()).valueOrNull, isEmpty);
    expect(empty.modelRunTime, isNull);
    expect(empty.framePeriod, isNull);
    final map = RecordingMapController();
    await empty.prepare(map, const []);
    await empty.show(map, MapFrame(id: 'missing', time: DateTime.utc(2026)));
    expect(map.calls.where((c) => c.startsWith('addRasterLayer')), isEmpty);
  });

  testWidgets('showing a frame with tracing on records the reveal', (
    tester,
  ) async {
    MapTileCache.traceEnabled = true;
    addTearDown(() => MapTileCache.traceEnabled = false);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = testRadarLayer(_Radar(const ['1700000000', '1700000600']));
    final frames = (await layer.frames()).valueOrNull!;
    final map = RecordingMapController();
    await layer.prepare(map, frames);
    await layer.show(map, frames.first);
    layer.onSurfaceVisibility(false);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => Text(layer.timelineCaption(context)),
          ),
        ),
      ),
    );
    expect(find.text(l10n.mapTimelineObserved), findsOneWidget);
    expect(layer.isShowingFrame(frames.first.id), isTrue);
  });
}
