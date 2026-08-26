/// The rainfall layer's legend, rendered the way [MapScaffold] shows it —
/// inside the collapsed chip, whose `AnimatedSize` lays out with unbounded
/// width.
///
/// Two things guarded here:
///
/// 1. [RainMapLayer]'s legend draws as a gradient — like the QPESUMS forecast
///    legend — even though the dots and sheet reading underneath stay banded
///    (the CWA scale is genuinely categorical; only the legend's look
///    changed, via `WeatherStationLayer.legendBanded`).
/// 2. `ColorScaleLegend(banded: true)` — the hard-edged rendering rain no
///    longer uses for its own legend, but which the widget still supports for
///    a genuinely categorical scale — must keep working inside this same
///    unbounded-width chip. This guards two regressions that together once
///    made a banded legend useless: the boundary-label column is a `Stack` in
///    a `Row`, and a `Stack` refuses unbounded width, so expanding the legend
///    threw a layout assertion every frame and it never appeared; and the
///    band strip's `ColoredBox` cells have no intrinsic width, so under the
///    default `Column` cross axis they collapsed to zero and the strip was
///    invisible while the boundary numbers kept rendering with no colour
///    beside them.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/rain_layer.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/rain_trend.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/collapsible_map_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubRainRepository implements MeteorRainRepository {
  @override
  Future<Result<Map<String, WeatherStation>>> stations() async => const Ok({});

  @override
  Future<Result<RainSnapshot>> latest() async =>
      const Ok(RainSnapshot(time: 0, stations: []));

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<RainSnapshot>> at(int second) async =>
      const Ok(RainSnapshot(time: 0, stations: []));

  @override
  Future<Result<RainTrend>> trend(String id, {String range = '24h'}) async =>
      Ok(RainTrend(id: id, range: range, times: const [], rain: const []));
}

/// Pumps the legend built by [legendBuilder] inside the same collapsed-chip /
/// `AnimatedSize` context the map actually uses, then expands it.
Future<void> _pumpExpanded(
  WidgetTester tester,
  Widget Function(BuildContext) legendBuilder,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CollapsibleMapLegend(
                      key: const ValueKey('legend-under-test'),
                      legend: legendBuilder(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  final semantics = tester.ensureSemantics();
  await tester.pump();
  await tester.tap(find.byIcon(Icons.legend_toggle));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  semantics.dispose();
}

void main() {
  testWidgets('the rain legend draws a gradient, not hard bands', (
    tester,
  ) async {
    final layer = RainMapLayer(_StubRainRepository());
    await _pumpExpanded(tester, layer.buildLegend);

    expect(tester.takeException(), isNull);
    expect(find.byType(ColorScaleLegend), findsOneWidget);
    expect(find.byType(MapLegendCard), findsOneWidget);

    // No banded swatch cells — the gradient path paints the scale as a single
    // `Container` with a `LinearGradient`, not a column of opaque
    // `ColoredBox`es. (An incidental translucent `ColoredBox` from the
    // surrounding chip chrome is not one of those.)
    final opaqueBandCells = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(MapLegendCard),
            matching: find.byType(ColoredBox),
          ),
        )
        .where((cb) => cb.color.a == 1.0);
    expect(opaqueBandCells, isEmpty);

    final gradientContainers = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(MapLegendCard),
            matching: find.byType(Container),
          ),
        )
        .where((c) => (c.decoration as BoxDecoration?)?.gradient != null)
        .toList();
    expect(gradientContainers, hasLength(1));
    final gradient = gradientContainers.single.decoration as BoxDecoration;
    expect((gradient.gradient as LinearGradient).colors, hasLength(17));
  });

  testWidgets(
    "the legend's header follows a later interval change, not just its "
    'first build',
    (tester) async {
      final layer = RainMapLayer(_StubRainRepository());
      await _pumpExpanded(tester, layer.buildLegend);

      // Default window is 1 時 (see RainMapLayer.interval's doc).
      expect(find.text('1 時'), findsOneWidget);
      expect(find.text('今日'), findsNothing);

      // buildLegend wraps its header + scale in a ListenableBuilder driven by
      // chromeListenable (interval + colorScale). Building that header and
      // scale *before* handing them to the builder — rather than inside its
      // callback — would freeze the legend at whatever was selected when it
      // first appeared, silently ignoring every later interval change.
      await layer.setInterval(RainInterval.now);
      await tester.pump();

      expect(find.text('今日'), findsOneWidget);
      expect(find.text('1 時'), findsNothing);
    },
  );

  testWidgets(
    'ColorScaleLegend(banded: true) still expands inside the chip without '
    'layout exceptions',
    (tester) async {
      await _pumpExpanded(
        tester,
        (_) => const MapLegendCard(
          child: ColorScaleLegend(
            unit: 'mm',
            banded: true,
            stops: [
              (0, '#c2c2c2'),
              (1, '#a0fffa'),
              (2, '#00cdff'),
              (6, '#0096ff'),
            ],
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'no exception while rendering legend',
      );
      expect(find.byType(ColorScaleLegend), findsOneWidget);

      // Every band must actually paint: the band cells are plain
      // `ColoredBox`es (no intrinsic width), so a non-stretched column
      // collapses them to zero width and the strip vanishes while the
      // numbers stay. Assert the opaque cells inside the card are all 4,
      // each 8 px wide.
      final swatchFinder = find.descendant(
        of: find.byType(MapLegendCard),
        matching: find.byType(ColoredBox),
      );
      final opaque = tester
          .widgetList<ColoredBox>(swatchFinder)
          .where((cb) => cb.color.a == 1.0)
          .toList();
      expect(opaque, hasLength(4));
      final firstSwatch = tester.renderObject<RenderBox>(swatchFinder.at(1));
      expect(firstSwatch.size.width, 8);
    },
  );
}
