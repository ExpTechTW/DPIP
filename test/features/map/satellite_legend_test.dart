import 'package:dpip/features/map/presentation/widgets/satellite_legend.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: Center(child: child)),
);

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets(
    'thermal band grayscale carries the K scale and the yellow border key',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          SatelliteLegend(
            channel: SatelliteChannel.irClean,
            style: ValueNotifier(SatelliteStyle.gray),
          ),
        ),
      );

      final l10n = await _l10n();
      // JMA convention: 190 K cold (white) → 320 K warm (black); the unit
      // sits below the scale, not after every value.
      expect(find.text('190'), findsOneWidget);
      expect(find.text('320'), findsOneWidget);
      expect(find.text(l10n.mapLegendUnit('K')), findsOneWidget);
      // Every channel shares the bright-yellow country/county and dark-yellow
      // township frame key.
      expect(find.text(l10n.mapLayerSatelliteGlobalOutline), findsOneWidget);
      expect(find.text(l10n.radarCountyOutline), findsOneWidget);
      expect(find.text(l10n.radarTownOutline), findsOneWidget);
    },
  );

  testWidgets('switching the style swaps the thermal scale', (tester) async {
    final style = ValueNotifier(SatelliteStyle.gray);
    await tester.pumpWidget(
      _wrap(SatelliteLegend(channel: SatelliteChannel.irClean, style: style)),
    );
    expect(find.text('190'), findsOneWidget);

    style.value = SatelliteStyle.jma;
    await tester.pumpAndSettle();

    // The cloud-top enhancement colours only the coldest tops (below −40 °C).
    expect(find.text('190'), findsNothing);
    expect(find.text('-45'), findsOneWidget);
    expect(find.text('-92'), findsOneWidget);
  });

  testWidgets('cloud mask legend lists the four categories', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SatelliteLegend(
          channel: SatelliteChannel.cloudmask,
          style: ValueNotifier(SatelliteStyle.gray),
        ),
      ),
    );

    final l10n = await _l10n();
    expect(find.text(l10n.mapLayerSatelliteCloudClear), findsOneWidget);
    expect(find.text(l10n.mapLayerSatelliteCloudProbablyClear), findsOneWidget);
    expect(
      find.text(l10n.mapLayerSatelliteCloudProbablyCloudy),
      findsOneWidget,
    );
    expect(find.text(l10n.mapLayerSatelliteCloudCloudy), findsOneWidget);
  });

  testWidgets('RGB products carry a compositing note instead of a scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SatelliteLegend(
          channel: SatelliteChannel.truecolor,
          style: ValueNotifier(SatelliteStyle.gray),
        ),
      ),
    );

    final l10n = await _l10n();
    expect(find.text(l10n.mapLayerSatelliteRgbComposite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every channel renders a legend without throwing', (
    tester,
  ) async {
    for (final channel in SatelliteChannel.values) {
      await tester.pumpWidget(
        _wrap(
          SatelliteLegend(
            channel: channel,
            style: ValueNotifier(SatelliteStyle.gray),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'channel ${channel.key} must build a legend',
      );
    }
  });

  testWidgets('each transparency case explains itself', (tester) async {
    final l10n = await _l10n();
    final cases = <(SatelliteChannel, String)>[
      // Reflective bands: low reflectance / night.
      (
        SatelliteChannel.visibleRed,
        l10n.mapLayerSatelliteTransparentReflectance,
      ),
      // Thermal bands: the warm clear-sky end.
      (SatelliteChannel.irClean, l10n.mapLayerSatelliteTransparentWarm),
      // Daytime RGBs fade out at night.
      (SatelliteChannel.truecolor, l10n.mapLayerSatelliteTransparentNight),
      // Difference layers: zero = no absorber.
      (SatelliteChannel.btdSplit, l10n.mapLayerSatelliteTransparentZero),
      // Cloud mask: clear sky.
      (SatelliteChannel.cloudmask, l10n.mapLayerSatelliteTransparentClear),
      // SST has no land value.
      (SatelliteChannel.sst, l10n.mapLayerSatelliteTransparentNoData),
      // NDVI below bare soil.
      (SatelliteChannel.ndvi, l10n.mapLayerSatelliteTransparentNoVegetation),
      // NDWI/MNDWI at or below zero.
      (SatelliteChannel.ndwi, l10n.mapLayerSatelliteTransparentNoWater),
    ];
    for (final (channel, note) in cases) {
      await tester.pumpWidget(
        _wrap(
          SatelliteLegend(
            channel: channel,
            style: ValueNotifier(SatelliteStyle.gray),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(note),
        findsOneWidget,
        reason: 'channel ${channel.key} must explain its transparency',
      );
    }
  });

  testWidgets('always-opaque thermal RGBs carry no transparency note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SatelliteLegend(
          channel: SatelliteChannel.ash,
          style: ValueNotifier(SatelliteStyle.gray),
        ),
      ),
    );
    final l10n = await _l10n();
    expect(
      find.text(l10n.mapLayerSatelliteTransparentWarm),
      findsNothing,
      reason: 'thermal RGB recipes cover the whole scene',
    );
  });
}
