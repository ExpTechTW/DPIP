/// [HumidityMapLayer]: a plain [WeatherStationLayer] instance with nothing of
/// its own to draw — no arrow overlay, no banded legend, just a value reader,
/// a colour ramp, and the chart's fixed 0-100 axis. So this pins exactly that:
/// which field it reads, that the axis is clamped (unlike temperature and
/// pressure, which let the chart auto-scale), and that its ramp is a true
/// interpolation (unlike wind's discrete speed buckets).
///
/// Never asserts on `decorate()` or any MapLibre call beyond the GeoJSON the
/// base class ends up publishing — this layer adds no `decorate()` override at
/// all, so there is nothing of its own to pin there.
library;

import 'package:dpip/features/map/presentation/layers/humidity_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';
import 'weather_station_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('identity, unit and chart bounds', () {
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
    expect(layer.id, 'humidity');
    expect(layer.icon, Icons.water_drop_outlined);
    expect(layer.unit, '%');
    expect(layer.decimals, 0);
    // A percentage chart is clamped to its own scale, not the sample range.
    expect(layer.chartMinY, 0);
    expect(layer.chartMaxY, 100);
  });

  testWidgets('label reads the localized humidity string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
    expect(layer.label(context), AppLocalizations.of(context).mapLayerHumidity);
  });

  test('valueOf reads relative humidity, null without one', () {
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
    expect(layer.valueOf(fullObservation), 65.0);
    expect(layer.valueOf(emptyObservation), isNull);
  });

  test('trendOf converts each sample to a double, preserving gaps', () {
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
    expect(layer.trendOf(fixtureTrend), [70.0, 65.0]);

    final withGap = fixtureTrend.copyWith(humidity: const [70, null]);
    expect(layer.trendOf(withGap), const [70.0, null]);
  });

  test('colorStops mirror the CWA relative-humidity scale exactly', () {
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
    expect(layer.colorStops, const [
      (0.0, '#B45309'),
      (30.0, '#FDAE61'),
      (50.0, '#FFFFBF'),
      (70.0, '#ABD9E9'),
      (90.0, '#74ADD1'),
      (100.0, '#4575B4'),
    ]);
  });

  group('rendered station data', () {
    test('reading and valueColor read the fully observed station', () async {
      final layer = HumidityMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());

      expect(layer.reading(stationFullId), '65 %');
      // Genuinely interpolated (65 sits strictly between the 50 and 70 stops),
      // computed from the ramp directly rather than re-guessed by hand.
      final expected = rampColor(const [(50, '#FFFFBF'), (70, '#ABD9E9')], 65);
      expect(layer.valueColor(stationFullId), expected);
    });

    test(
      'reading and valueColor are null without a humidity reading',
      () async {
        final layer = HumidityMapLayer(FakeStationWeatherRepository());
        await layer.render(RecordingMapController());

        for (final id in [stationEmptyId, stationSpeedOnlyId]) {
          expect(layer.reading(id), isNull, reason: id);
          expect(layer.valueColor(id), isNull, reason: id);
        }
      },
    );

    test(
      'only the station with a humidity reading reaches the source',
      () async {
        final layer = HumidityMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        final geoJson = controller.sourceData['wx-humidity-src']!;
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
        final layer = HumidityMapLayer(FakeStationWeatherRepository());
        final controller = RecordingMapController();
        await layer.render(controller);

        // A plain station layer draws its own circle dot (unlike wind, which
        // turns it off in favour of arrows) plus the shared name label, and
        // decorate() — not overridden here — adds nothing on top.
        expect(controller.calls, [
          'removeLayer:wx-humidity-circle',
          'removeLayer:wx-humidity-label',
          'removeSource:wx-humidity-src',
          'addSource:wx-humidity-src',
          'addCircleLayer:wx-humidity-circle',
          'addSymbolLayer:wx-humidity-label',
        ]);
      },
    );
  });

  test(
    'readingIcon has nothing to draw — humidity is a text-only reading',
    () async {
      final layer = HumidityMapLayer(FakeStationWeatherRepository());
      await layer.render(RecordingMapController());
      expect(layer.readingIcon(stationFullId), isNull);
    },
  );

  test(
    'trend decodes through the base seriesOf, with no direction channel',
    () async {
      final repository = FakeStationWeatherRepository();
      final layer = HumidityMapLayer(repository);

      final result = await layer.trend(stationFullId, '7d');

      expect(repository.trendRequests, [stationFullId]);
      expect(repository.trendRanges, ['7d']);
      final series = result.valueOrNull!;
      expect(series.times, fixtureTrend.times);
      expect(series.values, [70.0, 65.0]);
      expect(series.directions, isNull);
    },
  );

  testWidgets('buildLegend shows the ungraded colour scale for the unit', (
    tester,
  ) async {
    final layer = HumidityMapLayer(FakeStationWeatherRepository());
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
    expect(legend.unit, '%');
    expect(legend.banded, isFalse);
  });
}
