/// [RainMapLayer] reads one accumulation window, follows that window with a
/// suggested colour scale, and publishes both through the legend and the
/// interval menu. A repeat of the current choice does not change state.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/rain_color_scale.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/features/map/presentation/layers/rain_layer.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _RainRepo implements MeteorRainRepository {
  @override
  Future<Result<RainSnapshot>> at(int second) async =>
      const Err(NetworkFailure('unused'));

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<RainSnapshot>> latest() async =>
      const Ok(RainSnapshot(time: 0, stations: []));

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async => const Ok({});

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) async =>
      Ok(RainTrend(id: id, range: range, times: const [1], rain: const [4.5]));
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const observation = RainObservation(
    id: 'C0A001',
    now: 0.2,
    min10: 1,
    hour1: 12,
    hour3: 20,
    hour6: 30,
    hour12: 40,
    hour24: 50,
    day2: 60,
    day3: 70,
  );

  test(
    'each window reads its own column and the scale follows the window',
    () async {
      final layer = RainMapLayer(_RainRepo());
      expect(layer.id, 'rain');
      expect(layer.unit, 'mm');
      expect(layer.decimals, 1);
      expect(layer.chartMinY, 0);
      expect(layer.chartBars, isTrue);
      expect(layer.bandedColors, isTrue);
      expect(layer.legendBanded, isFalse);
      expect(layer.interval.value, RainInterval.hour1);
      expect(layer.colorScale.value, RainColorScale.fine);

      for (final interval in RainInterval.values) {
        await layer.setInterval(interval);
        expect(layer.valueOf(observation), interval.valueOf(observation));
        expect(layer.colorScale.value, RainColorScale.defaultFor(interval));
      }
      await layer.setInterval(RainInterval.day3);
      expect(layer.colorScale.value, RainColorScale.coarse);

      await layer.setColorScale(RainColorScale.fine);
      expect(layer.colorScale.value, RainColorScale.fine);
      expect(layer.colorStops, isNotEmpty);
      await layer.setColorScale(RainColorScale.fine);

      final trend = RainTrend(
        id: 'C0A001',
        range: '24h',
        times: const [1, 2],
        rain: const [1.0, null],
      );
      expect(layer.trendOf(trend), [1.0, null]);
    },
  );

  testWidgets('the legend names the window and the menu switches it', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = RainMapLayer(_RainRepo());
    final labels = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Column(
            children: [
              layer.buildLegend(context),
              layer.buildTopTrailingChrome(
                context,
                showTownLabels: labels,
                onShowTownLabelsChanged: (value) => labels.value = value,
                showTerrain: terrain,
                onShowTerrainChanged: (value) => terrain.value = value,
                onReloadActive: () async {},
              ),
              layer.title(context).isEmpty
                  ? const SizedBox.shrink()
                  : Text(layer.title(context)),
            ],
          ),
        ),
      ),
    );
    expect(find.text(l10n.rainInterval1h), findsWidgets);
    expect(find.textContaining(l10n.mapLayerRain), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.rainIntervalMenu));
    await tester.pumpAndSettle();
    final threeDay = find.text(l10n.rainInterval3d);
    await tester.ensureVisible(threeDay.last);
    await tester.tap(threeDay.last);
    await tester.pump();
    expect(layer.interval.value, RainInterval.day3);
    expect(layer.colorScale.value, RainColorScale.coarse);

    final fine = find.text(l10n.rainScaleFine);
    await tester.ensureVisible(fine.last);
    await tester.tap(fine.last);
    await tester.pump();
    expect(layer.colorScale.value, RainColorScale.fine);

    for (final interval in RainInterval.values) {
      expect(interval.label(l10n), isNotEmpty);
    }
    expect(RainColorScale.coarse.label(l10n), l10n.rainScaleCoarse);
  });

  test('a dry station is ignored until the map is close enough', () async {
    final layer = RainMapLayer(_WetRainRepo());
    final map = RecordingMapController();
    await layer.render(map);
    await layer.setInterval(RainInterval.now);

    await layer.onMapTap(const LatLng(25.04, 121.51), map);
    expect(layer.selection.value, isNull);

    map.reportCamera(lat: 25.04, lng: 121.51, zoom: 9);
    await layer.onMapTap(const LatLng(25.04, 121.51), map);
    expect(layer.selection.value, 'C0A001');
    expect(layer.readingIcon('C0A001'), isNull);
  });
}

class _WetRainRepo implements MeteorRainRepository {
  static const _station = WeatherStation(
    name: '測站',
    county: '臺北市',
    town: '中正區',
    altitude: 6,
    latitude: 25.04,
    longitude: 121.51,
  );

  @override
  Future<Result<RainSnapshot>> at(int second) async =>
      const Err(NetworkFailure('unused'));

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<RainSnapshot>> latest() async => const Ok(
    RainSnapshot(
      time: 0,
      stations: [
        RainObservation(
          id: 'C0A001',
          now: 0,
          min10: 0,
          hour1: 12,
          hour3: 0,
          hour6: 0,
          hour12: 0,
          hour24: 0,
          day2: 0,
          day3: 0,
        ),
      ],
    ),
  );

  @override
  Future<Result<Map<String, WeatherStation>>> stations() async =>
      const Ok({'C0A001': _station});

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) async =>
      Ok(RainTrend(id: id, range: range, times: const [1], rain: const [0]));
}
