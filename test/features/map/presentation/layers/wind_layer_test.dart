/// [WindMapLayer]: legacy speed-coloured arrows over the shared station
/// scaffold — arrows and colour come from [WindArrowOverlay] (covered on its
/// own), so this pins only what the layer itself contributes: which value it
/// plots, the `blow_to` bearing it derives, the tap reading/colour/icon, and
/// the trend series wind adds a direction axis to.
///
/// Never asserts on `decorate()`'s own MapLibre calls (the arrow image/filter
/// wiring) — only on the GeoJSON the base class ends up publishing, which is
/// this layer's own [WindMapLayer.extraProperties] flowing through.
library;

import 'package:dpip/features/map/presentation/layers/wind_layer.dart';
import 'package:dpip/features/map/presentation/wind_speed.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';
import 'weather_station_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('identity, unit and chart bounds', () {
    final layer = WindMapLayer(FakeStationWeatherRepository());
    expect(layer.id, 'wind');
    expect(layer.icon, Icons.air);
    expect(layer.unit, 'm/s');
    expect(layer.chartMinY, 0);
    expect(layer.decimals, 1);
    // Arrows replace the dot, so the base circle layer must stay off.
    expect(layer.drawCircle, isFalse);
    expect(layer.extraLayerIds, ['wx-wind-arrow']);
  });

  testWidgets('label reads the localized wind string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final layer = WindMapLayer(FakeStationWeatherRepository());
    expect(layer.label(context), AppLocalizations.of(context).mapLayerWind);
  });

  test('valueOf reads wind speed, null without one', () {
    final layer = WindMapLayer(FakeStationWeatherRepository());
    expect(layer.valueOf(fullObservation), 7.4);
    expect(layer.valueOf(emptyObservation), isNull);
  });

  test('trendOf is the trend\'s speed series', () {
    final layer = WindMapLayer(FakeStationWeatherRepository());
    expect(layer.trendOf(fixtureTrend), fixtureTrend.windSpeed);
  });

  test(
    'seriesOf carries the parallel direction series for the wind-barb chart',
    () {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      final series = layer.seriesOf(fixtureTrend);
      expect(series.times, fixtureTrend.times);
      expect(series.values, fixtureTrend.windSpeed);
      expect(series.directions, fixtureTrend.windDirection);
    },
  );

  test(
    'extraProperties carries a blow-to bearing only with a known direction',
    () {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      // Meteorological "from" 90° (easterly) blows toward 270°.
      expect(layer.extraProperties(fullObservation), {'blow_to': 270});
      expect(layer.extraProperties(emptyObservation), isEmpty);
      expect(layer.extraProperties(speedOnlyObservation), isEmpty);
    },
  );

  test(
    'colorStops mirror the wind speed buckets as hex, weakest to strongest',
    () {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      expect(layer.colorStops, const [
        (0.0, '#ffffff'),
        (3.4, '#00fff0'),
        (8.0, '#0085ff'),
        (13.9, '#8000ff'),
        (32.7, '#ff006b'),
      ]);
    },
  );

  group('rendered station data', () {
    test('reading and valueColor read the fully observed station', () async {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());

      expect(layer.reading(stationFullId), '7.4 m/s  90°');
      expect(layer.valueColor(stationFullId), const Color(0xFF00FFF0));
    });

    test(
      'reading and valueColor drop the degree suffix without a direction',
      () async {
        final layer = WindMapLayer(FakeStationWeatherRepository());
        await layer.render(RecordingMapController());

        expect(layer.reading(stationSpeedOnlyId), '3.1 m/s');
        expect(layer.valueColor(stationSpeedOnlyId), const Color(0xFFFFFFFF));
      },
    );

    test('reading and valueColor are null without a speed', () async {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());

      expect(layer.reading(stationEmptyId), isNull);
      expect(layer.valueColor(stationEmptyId), isNull);
    });

    test('only stations with a speed reach the arrow source, carrying blow_to exactly when known', () async {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      final controller = RecordingMapController();
      await layer.render(controller);

      final geoJson = controller.sourceData['wx-wind-src']!;
      final features = List<Map<String, dynamic>>.from(
        geoJson['features'] as List,
      );
      expect(features, hasLength(2));

      final byId = {
        for (final feature in features)
          (feature['properties'] as Map)['id']: feature['properties'] as Map,
      };
      expect(byId.keys, containsAll([stationFullId, stationSpeedOnlyId]));
      expect(byId[stationFullId]!['blow_to'], 270);
      expect(byId[stationSpeedOnlyId]!.containsKey('blow_to'), isFalse);
    });
  });

  testWidgets(
    'readingIcon draws a speed-tinted arrow only with a known direction',
    (tester) async {
      final layer = WindMapLayer(FakeStationWeatherRepository());
      // decorate() bakes the map's arrow PNGs through real dart:ui rasterisation
      // (PictureRecorder.toImage), which never completes inside testWidgets'
      // fake-async zone — runAsync steps outside it for this one await, exactly
      // as the plain (non-widget) tests in the group above get for free.
      await tester.runAsync(() => layer.render(RecordingMapController()));

      expect(layer.readingIcon(stationSpeedOnlyId), isNull);
      expect(layer.readingIcon(stationEmptyId), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: layer.readingIcon(stationFullId))),
        ),
      );
      final icon = tester.widget<WindArrowIcon>(find.byType(WindArrowIcon));
      expect(icon.color, const Color(0xFF00FFF0));
    },
  );

  test(
    'trend decodes through seriesOf, forwarding the id and range asked for',
    () async {
      final repository = FakeStationWeatherRepository();
      final layer = WindMapLayer(repository);

      final result = await layer.trend(stationFullId, '24h');

      expect(repository.trendRequests, [stationFullId]);
      expect(repository.trendRanges, ['24h']);
      final series = result.valueOrNull!;
      expect(series.values, fixtureTrend.windSpeed);
      expect(series.directions, fixtureTrend.windDirection);
    },
  );

  testWidgets('buildLegend renders one arrow per speed bucket, with the unit', (
    tester,
  ) async {
    final layer = WindMapLayer(FakeStationWeatherRepository());
    // SymbolLegend reads AppLocalizations unconditionally (for the unit row),
    // so it needs a real delegate even though this card has no other l10n text.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(builder: (context) => layer.buildLegend(context)),
        ),
      ),
    );

    expect(find.byType(WindArrowIcon), findsNWidgets(windBuckets.length));
    expect(find.textContaining('m/s'), findsOneWidget);
  });
}
