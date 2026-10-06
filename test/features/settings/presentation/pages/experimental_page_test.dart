/// Each weather and sky row is its own override. A tap that leaves the store
/// on the previous mode would paint the home backdrop the user just rejected.
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
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: settings)],
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
  testWidgets('tapping every weather mode then every sky mode persists it', (
    tester,
  ) async {
    final settings = await _pump(tester);
    final l10n = await _en();

    final weather = <WeatherMode, String>{
      WeatherMode.auto: l10n.weatherModeAuto,
      WeatherMode.clear: l10n.weatherModeClear,
      WeatherMode.cloudy: l10n.weatherModeCloudy,
      WeatherMode.overcast: l10n.weatherModeOvercast,
      WeatherMode.rain: l10n.weatherModeRain,
      WeatherMode.snow: l10n.weatherModeSnow,
      WeatherMode.sand: l10n.weatherModeSand,
      WeatherMode.fog: l10n.weatherModeFog,
      WeatherMode.thunderstorm: l10n.weatherModeThunderstorm,
    };
    for (final entry in weather.entries) {
      await tester.tap(find.widgetWithText(ListTile, entry.value).first);
      await tester.pumpAndSettle();
      expect(settings.weatherMode, entry.key);
      expect(settings.skyTimeMode, SkyTimeMode.auto);
    }

    final sky = <SkyTimeMode, String>{
      SkyTimeMode.dawn: l10n.skyTimeDawn,
      SkyTimeMode.sunrise: l10n.skyTimeSunrise,
      SkyTimeMode.morning: l10n.skyTimeMorning,
      SkyTimeMode.noon: l10n.skyTimeNoon,
      SkyTimeMode.afternoon: l10n.skyTimeAfternoon,
      SkyTimeMode.golden: l10n.skyTimeGolden,
      SkyTimeMode.sunset: l10n.skyTimeSunset,
      SkyTimeMode.dusk: l10n.skyTimeDusk,
      SkyTimeMode.night: l10n.skyTimeNight,
      SkyTimeMode.auto: l10n.skyTimeAuto,
    };
    for (final entry in sky.entries) {
      await tester.tap(find.widgetWithText(ListTile, entry.value).last);
      await tester.pumpAndSettle();
      expect(settings.skyTimeMode, entry.key);
      expect(settings.weatherMode, WeatherMode.thunderstorm);
    }
  });
}
