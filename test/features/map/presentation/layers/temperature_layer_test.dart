/// [TemperatureMapLayer]: the plainest station layer — no chart clamp (unlike
/// humidity's fixed 0-100), no discrete buckets (unlike wind), just a value
/// reader and a seven-stop colour ramp. This pins which field it reads, that
/// the chart axis is left to auto-scale, and that the ramp is a true
/// interpolation, computed from the ramp itself rather than hand-guessed.
///
/// Never asserts on `decorate()` or any MapLibre call beyond the GeoJSON the
/// base class ends up publishing — this layer has no `decorate()` override at
/// all, so there is nothing of its own to pin there.
library;

import 'package:dpip/features/map/presentation/layers/temperature_layer.dart';
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
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
    expect(layer.id, 'temperature');
    expect(layer.icon, Icons.thermostat_outlined);
    expect(layer.unit, '°C');
    expect(layer.decimals, 1);
    // Unlike humidity's fixed 0-100, temperature leaves the chart to
    // auto-scale to whatever range the trend actually spans.
    expect(layer.chartMinY, isNull);
    expect(layer.chartMaxY, isNull);
  });

  testWidgets('label reads the localized temperature string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
    expect(
      layer.label(context),
      AppLocalizations.of(context).mapLayerTemperature,
    );
  });

  test('valueOf reads the temperature, null without one', () {
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
    expect(layer.valueOf(fullObservation), 27.8);
    expect(layer.valueOf(emptyObservation), isNull);
  });

  test('trendOf is the trend\'s temperature series unchanged', () {
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
    expect(layer.trendOf(fixtureTrend), fixtureTrend.temperature);
  });

  test('colorStops mirror the seven-stop CWA temperature scale exactly', () {
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
    expect(layer.colorStops, const [
      (-20.0, '#4d4e51'),
      (-10.0, '#0000ff'),
      (0.0, '#308fff'),
      (10.0, '#6fc1b2'),
      (20.0, '#f6e78f'),
      (30.0, '#ff4500'),
      (40.0, '#81249D'),
    ]);
  });

  group('rendered station data', () {
    test('reading and valueColor read the fully observed station', () async {
      final layer = TemperatureMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());

      expect(layer.reading(stationFullId), '27.8 °C');
      // Genuinely interpolated (27.8 sits strictly between the 20 and 30
      // stops), computed from the ramp directly rather than re-guessed by hand.
      final expected = rampColor(const [
        (20, '#f6e78f'),
        (30, '#ff4500'),
      ], 27.8);
      expect(layer.valueColor(stationFullId), expected);
    });

    test(
      'reading and valueColor are null without a temperature reading',
      () async {
        final layer = TemperatureMapLayer(FakeStationWeatherRepository());
        await layer.render(RecordingMapController());

        for (final id in [stationEmptyId, stationSpeedOnlyId]) {
          expect(layer.reading(id), isNull, reason: id);
          expect(layer.valueColor(id), isNull, reason: id);
        }
      },
    );

    test(
      'only the station with a temperature reading reaches the source',
      () async {
        final layer = TemperatureMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        final geoJson = controller.sourceData['wx-temperature-src']!;
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
        final layer = TemperatureMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        expect(controller.calls, [
          'removeLayer:wx-temperature-circle',
          'removeLayer:wx-temperature-label',
          'removeSource:wx-temperature-src',
          'addSource:wx-temperature-src',
          'addCircleLayer:wx-temperature-circle',
          'addSymbolLayer:wx-temperature-label',
        ]);
      },
    );
  });

  test(
    'readingIcon has nothing to draw — temperature is a text-only reading',
    () async {
      final layer = TemperatureMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());
      expect(layer.readingIcon(stationFullId), isNull);
    },
  );

  test(
    'trend decodes through the base seriesOf, with no direction channel',
    () async {
      final repository = FakeStationWeatherRepository();
      final layer = TemperatureMapLayer(repository);

      final result = await layer.trend(stationFullId, '7d');

      expect(repository.trendRequests, [stationFullId]);
      expect(repository.trendRanges, ['7d']);
      final series = result.valueOrNull!;
      expect(series.times, fixtureTrend.times);
      expect(series.values, fixtureTrend.temperature);
      expect(series.directions, isNull);
    },
  );

  testWidgets('buildLegend shows the ungraded colour scale for the unit', (
    tester,
  ) async {
    final layer = TemperatureMapLayer(FakeStationWeatherRepository());
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
    expect(legend.unit, '°C');
    expect(legend.banded, isFalse);
  });
}
