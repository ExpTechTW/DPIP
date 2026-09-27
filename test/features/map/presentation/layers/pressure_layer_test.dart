/// [PressureMapLayer]: the station-pressure counterpart to temperature — same
/// shape (a value reader, an un-clamped chart, a five-stop colour ramp), just
/// a different field and scale. This pins which field it reads and that its
/// ramp is a true interpolation, computed from the ramp itself rather than
/// hand-guessed.
///
/// Never asserts on `decorate()` or any MapLibre call beyond the GeoJSON the
/// base class ends up publishing — this layer has no `decorate()` override at
/// all, so there is nothing of its own to pin there.
library;

import 'package:dpip/features/map/presentation/layers/pressure_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';
import 'weather_station_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('identity, unit and an un-clamped chart', () {
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    expect(layer.id, 'pressure');
    expect(layer.icon, Icons.compress);
    expect(layer.unit, 'hPa');
    expect(layer.decimals, 0);
    expect(layer.chartMinY, isNull);
    expect(layer.chartMaxY, isNull);
  });

  testWidgets('label reads the localized pressure string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    expect(layer.label(context), AppLocalizations.of(context).mapLayerPressure);
  });

  test('valueOf reads the station pressure, null without one', () {
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    expect(layer.valueOf(fullObservation), 1008.2);
    expect(layer.valueOf(emptyObservation), isNull);
  });

  test('trendOf is the trend\'s pressure series unchanged', () {
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    expect(layer.trendOf(fixtureTrend), fixtureTrend.pressure);
  });

  test('colorStops mirror the five-stop CWA pressure scale exactly', () {
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    expect(layer.colorStops, const [
      (640.0, '#4575B4'),
      (740.0, '#ABD9E9'),
      (840.0, '#FFFFBF'),
      (940.0, '#FDAE61'),
      (1040.0, '#D73027'),
    ]);
  });

  group('rendered station data', () {
    test('reading and valueColor read the fully observed station', () async {
      final layer = PressureMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());

      expect(layer.reading(stationFullId), '1008 hPa');
      // Genuinely interpolated (1008.2 sits strictly between the 940 and 1040
      // stops), computed from the ramp directly rather than re-guessed by hand.
      final expected = rampColor(const [
        (940, '#FDAE61'),
        (1040, '#D73027'),
      ], 1008.2);
      expect(layer.valueColor(stationFullId), expected);
    });

    test(
      'reading and valueColor are null without a pressure reading',
      () async {
        final layer = PressureMapLayer(FakeStationWeatherRepository());
        await layer.render(RecordingMapController());

        for (final id in [stationEmptyId, stationSpeedOnlyId]) {
          expect(layer.reading(id), isNull, reason: id);
          expect(layer.valueColor(id), isNull, reason: id);
        }
      },
    );

    test(
      'only the station with a pressure reading reaches the source',
      () async {
        final layer = PressureMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        final geoJson = controller.sourceData['wx-pressure-src']!;
        final features = List<Map<String, dynamic>>.from(
          geoJson['features'] as List,
        );
        expect(features, hasLength(1));
        expect((features.single['properties'] as Map)['id'], stationFullId);
      },
    );

    test(
      'render mounts only the shared dot + label layers, no overlay of its own',
      () async {
        final layer = PressureMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        expect(controller.calls, [
          'removeLayer:wx-pressure-circle',
          'removeLayer:wx-pressure-label',
          'removeSource:wx-pressure-src',
          'addSource:wx-pressure-src',
          'addCircleLayer:wx-pressure-circle',
          'addSymbolLayer:wx-pressure-label',
        ]);
      },
    );
  });

  test(
    'readingIcon has nothing to draw — pressure is a text-only reading',
    () async {
      final layer = PressureMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());
      expect(layer.readingIcon(stationFullId), isNull);
    },
  );

  test(
    'trend decodes through the base seriesOf, with no direction channel',
    () async {
      final repository = FakeStationWeatherRepository();
      final layer = PressureMapLayer(repository);

      final result = await layer.trend(stationFullId, '7d');

      expect(repository.trendRequests, [stationFullId]);
      expect(repository.trendRanges, ['7d']);
      final series = result.valueOrNull!;
      expect(series.times, fixtureTrend.times);
      expect(series.values, fixtureTrend.pressure);
      expect(series.directions, isNull);
    },
  );

  testWidgets('buildLegend shows the ungraded colour scale for the unit', (
    tester,
  ) async {
    final layer = PressureMapLayer(FakeStationWeatherRepository());
    // ColorScaleLegend reads AppLocalizations unconditionally (line 99 of
    // map_color_legend.dart builds l10n before it ever checks banded/unit),
    // so it needs a real delegate even though this card shows no localized text.
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

    final legend = tester.widget<ColorScaleLegend>(
      find.byType(ColorScaleLegend),
    );
    expect(legend.stops, layer.colorStops);
    expect(legend.unit, 'hPa');
    expect(legend.banded, isFalse);
  });
}
