/// The rainfall layer's legend, rendered the way [MapScaffold] shows it —
/// inside the collapsed chip, whose `AnimatedSize` lays out with unbounded
/// width.
///
/// Guards two regressions that together made the 雨量 legend useless:
///
/// 1. The banded label column (`_BandBoundaryLabels`) was a bare `Stack` in a
///    Row, and a Stack refuses unbounded width — expanding the legend threw a
///    layout assertion every frame and it never appeared. The column now
///    measures the widest boundary label and carries its own width.
/// 2. The band strip's `ColoredBox` cells have no intrinsic width, so under
///    the default `Column` cross axis they collapsed to zero and the strip
///    was invisible — the boundary numbers had no colours beside them. The
///    band column now stretches across the swatch width.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/rain_layer.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
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

void main() {
  testWidgets(
    'the banded legend expands inside the chip without layout exceptions',
    (tester) async {
      final layer = RainMapLayer(_StubRainRepository());
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
                          key: ValueKey(layer.id),
                          legend: layer.buildLegend(context),
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

      // The chip should be visible.
      expect(find.byIcon(Icons.legend_toggle), findsOneWidget);

      // The map's legend chip lays out in an unbounded-width context
      // (AnimatedSize) — the banded label column must carry its own width.
      // Semantics on, like the running app under VoiceOver: the broken layout
      // also wedged the semantics flush, so cover that path too.
      final semantics = tester.ensureSemantics();
      await tester.pump();

      // Expand it.
      await tester.tap(find.byIcon(Icons.legend_toggle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      final errors = tester.takeException();
      expect(errors, isNull, reason: 'no exception while rendering legend');
      expect(find.byType(ColorScaleLegend), findsOneWidget);
      expect(find.byType(MapLegendCard), findsOneWidget);

      // Every one of the 17 CWA bands must actually paint: the band cells are
      // plain ColoredBoxes (no intrinsic width), so a non-stretched column
      // collapses them to zero width and the strip vanishes while the numbers
      // stay. Assert the opaque cells inside the card are 17, each 8 px wide.
      final swatchFinder = find.descendant(
        of: find.byType(MapLegendCard),
        matching: find.byType(ColoredBox),
      );
      final opaque = tester
          .widgetList<ColoredBox>(swatchFinder)
          .where((cb) => cb.color.a == 1.0)
          .toList();
      expect(opaque, hasLength(17));
      final firstSwatch = tester.renderObject<RenderBox>(swatchFinder.at(1));
      expect(firstSwatch.size.width, 8);
      semantics.dispose();
    },
  );
}
