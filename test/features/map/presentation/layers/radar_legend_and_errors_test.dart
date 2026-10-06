/// Radar's legend follows the data toggles, and a failed strike or wind
/// history leaves the overlay on so the next frame can try again.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/lightning_strike_overlay.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../raster_timeline_harness.dart';

class _Radar extends FakeRasterFrameSource implements RadarRepository {
  _Radar() : super(const ['1700000000']);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';
}

class _HistoryLightning implements MeteorLightningRepository {
  _HistoryLightning(this.seconds);

  final List<int> seconds;

  @override
  Future<Result<LightningSnapshot>> at(int second) async =>
      Ok(LightningSnapshot(time: second, strikes: const []));

  @override
  Future<Result<List<int>>> history() async => Ok(seconds);

  @override
  Future<Result<LightningSnapshot>> latest() async => at(seconds.last);
}

class _BrokenLightning implements MeteorLightningRepository {
  @override
  Future<Result<LightningSnapshot>> at(int second) async =>
      const Err(NetworkFailure('down'));

  @override
  Future<Result<List<int>>> history() async =>
      const Err(NetworkFailure('history'));

  @override
  Future<Result<LightningSnapshot>> latest() async =>
      const Err(NetworkFailure('down'));
}

class _BrokenWeather extends EmptyWeatherRepository {
  @override
  Future<Result<List<int>>> history() async =>
      const Err(NetworkFailure('history'));
}

class _ThrowingMap extends RecordingMapController {
  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    calls.add('addSource:$sourceId');
    if (sourceId.contains('lightning')) {
      throw StateError('style gone');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legend names dBZ and the overlay that is actually on', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = testRadarLayer(_Radar());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              expect(layer.label(context), l10n.mapLayerRadar);
              expect(layer.icon, Icons.radar_outlined);
              expect(layer.rasterBelowLayerId, townLabelLayerId);
              expect(
                layer.buildTopTrailingChrome(
                  context,
                  showTownLabels: ValueNotifier(true),
                  onShowTownLabelsChanged: (_) {},
                  showTerrain: ValueNotifier(true),
                  onShowTerrainChanged: (_) {},
                  onReloadActive: () async {},
                ),
                isA<RadarOverlayMenu>(),
              );
              return ListenableBuilder(
                listenable: layer.chromeListenable,
                builder: (context, _) => layer.buildLegend(context),
              );
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('dBZ'), findsOneWidget);

    layer.setShowLightning(true);
    await tester.pump();
    expect(find.text(l10n.lightningLegendCg(5)), findsOneWidget);

    layer.setShowWind(true);
    await tester.pump();
    expect(find.text(l10n.lightningLegendCg(5)), findsNothing);
    expect(find.textContaining('m/s'), findsWidgets);
  });

  test('a failed overlay history does not turn the toggle off', () async {
    final lightning = testRadarLayer(_Radar(), lightning: _BrokenLightning());
    lightning.setShowLightning(true);
    final frames = (await lightning.frames()).valueOrNull!;
    final map = RecordingMapController();
    await lightning.prepare(map, frames);
    await lightning.show(map, frames.single);
    await lightning.overlaySettled;
    expect(lightning.showLightning.value, isTrue);

    final wind = testRadarLayer(_Radar(), weather: _BrokenWeather());
    wind.setShowWind(true);
    await wind.prepare(map, frames);
    await wind.show(map, frames.single);
    await wind.overlaySettled;
    expect(wind.showWind.value, isTrue);
  });

  test('an overlay mount that throws is absorbed by the chain', () async {
    final layer = testRadarLayer(
      _Radar(),
      lightning: _HistoryLightning(const [1700000000]),
    );
    layer.setShowLightning(true);
    final frames = (await layer.frames()).valueOrNull!;
    final map = _ThrowingMap();
    await layer.prepare(map, frames);
    await layer.show(
      map,
      MapFrame(id: frames.single.id, time: frames.single.time),
    );
    await layer.overlaySettled;
    expect(map.calls, contains('addSource:radar-lightning-src'));
    expect(LightningStrikeOverlay.legendItems, isNotNull);
  });
}
