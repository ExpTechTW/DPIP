/// The experimental page is two independent axes. A check that stays on the
/// previous mode, or a weather tap that also moves the sky, would make the
/// home backdrop lie about which override is in force.
library;

import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

Future<ExperimentalSettings> _pump(WidgetTester tester) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final settings = ExperimentalSettings(SettingsStore.inMemory());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExperimentalPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

Future<AppLocalizations> _en() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets('every weather and sky mode is offered, auto checked', (
    tester,
  ) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    expect(settings.weatherMode, WeatherMode.auto);
    expect(settings.skyTimeMode, SkyTimeMode.auto);
    expect(find.text(l10n.experimentalFeatures), findsOneWidget);
    for (final label in [
      l10n.weatherModeAuto,
      l10n.weatherModeClear,
      l10n.weatherModeCloudy,
      l10n.weatherModeOvercast,
      l10n.weatherModeRain,
      l10n.weatherModeSnow,
      l10n.weatherModeSand,
      l10n.weatherModeFog,
      l10n.weatherModeThunderstorm,
      l10n.skyTimeAuto,
      l10n.skyTimeDawn,
      l10n.skyTimeSunrise,
      l10n.skyTimeMorning,
      l10n.skyTimeNoon,
      l10n.skyTimeAfternoon,
      l10n.skyTimeGolden,
      l10n.skyTimeSunset,
      l10n.skyTimeDusk,
      l10n.skyTimeNight,
    ]) {
      expect(find.text(label), findsWidgets, reason: 'missing "$label"');
    }
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets('tapping rain then noon moves only that axis', (tester) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    await tester.tap(find.text(l10n.weatherModeRain));
    await tester.pumpAndSettle();
    expect(settings.weatherMode, WeatherMode.rain);
    expect(settings.skyTimeMode, SkyTimeMode.auto);

    await tester.tap(find.text(l10n.skyTimeNoon));
    await tester.pumpAndSettle();
    expect(settings.weatherMode, WeatherMode.rain);
    expect(settings.skyTimeMode, SkyTimeMode.noon);

    await tester.tap(find.text(l10n.weatherModeRain));
    await tester.pumpAndSettle();
    expect(settings.weatherMode, WeatherMode.rain);
  });
}
