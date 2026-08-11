import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/weather/weather_icons.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Experimental / in-progress features, reachable from the More tab.
///
/// Hosts the two overrides that drive the home backdrop. They are separate
/// axes on purpose: the look is the product of the weather *and* where the
/// keyframe ring sits, so testing needs both without squaring the entries.
class ExperimentalPage extends StatelessWidget {
  const ExperimentalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<ExperimentalSettings>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.experimentalFeatures)),
      body: ListView(
        children: [
          SectionHeader(l10n.weatherDynamicState),
          for (final mode in WeatherMode.values)
            ListTile(
              leading: Icon(_iconFor(mode)),
              title: Text(_labelFor(mode, l10n)),
              trailing: settings.weatherMode == mode
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () =>
                  context.read<ExperimentalSettings>().weatherMode = mode,
            ),
          SectionHeader(l10n.skyTime),
          for (final mode in SkyTimeMode.values)
            ListTile(
              leading: Icon(_timeIconFor(mode)),
              title: Text(_timeLabelFor(mode, l10n)),
              trailing: settings.skyTimeMode == mode
                  ? Icon(Icons.check, color: colors.primary)
                  : null,
              onTap: () =>
                  context.read<ExperimentalSettings>().skyTimeMode = mode,
            ),
        ],
      ),
    );
  }

  IconData _iconFor(WeatherMode mode) => switch (mode) {
    WeatherMode.auto => Icons.auto_mode,
    WeatherMode.clear => Icons.wb_sunny_outlined,
    WeatherMode.cloudy => Icons.filter_drama_outlined,
    WeatherMode.overcast => Icons.cloud_outlined,
    WeatherMode.rain => rainy,
    WeatherMode.snow => Icons.ac_unit_outlined,
    WeatherMode.sand => Icons.blur_on_outlined,
    WeatherMode.fog => Icons.foggy,
    WeatherMode.thunderstorm => Icons.thunderstorm_outlined,
  };

  String _labelFor(WeatherMode mode, AppLocalizations l10n) => switch (mode) {
    WeatherMode.auto => l10n.weatherModeAuto,
    WeatherMode.clear => l10n.weatherModeClear,
    WeatherMode.cloudy => l10n.weatherModeCloudy,
    WeatherMode.overcast => l10n.weatherModeOvercast,
    WeatherMode.rain => l10n.weatherModeRain,
    WeatherMode.snow => l10n.weatherModeSnow,
    WeatherMode.sand => l10n.weatherModeSand,
    WeatherMode.fog => l10n.weatherModeFog,
    WeatherMode.thunderstorm => l10n.weatherModeThunderstorm,
  };

  IconData _timeIconFor(SkyTimeMode mode) => switch (mode) {
    SkyTimeMode.auto => Icons.auto_mode,
    SkyTimeMode.dawn => Icons.nights_stay_outlined,
    SkyTimeMode.sunrise => Icons.wb_twilight_outlined,
    SkyTimeMode.morning => Icons.wb_sunny_outlined,
    SkyTimeMode.noon => Icons.light_mode_outlined,
    SkyTimeMode.afternoon => Icons.wb_sunny_outlined,
    SkyTimeMode.golden => Icons.wb_twilight_outlined,
    SkyTimeMode.sunset => Icons.wb_twilight_outlined,
    SkyTimeMode.dusk => Icons.nights_stay_outlined,
    SkyTimeMode.night => Icons.dark_mode_outlined,
  };

  String _timeLabelFor(SkyTimeMode mode, AppLocalizations l10n) =>
      switch (mode) {
        SkyTimeMode.auto => l10n.skyTimeAuto,
        SkyTimeMode.dawn => l10n.skyTimeDawn,
        SkyTimeMode.sunrise => l10n.skyTimeSunrise,
        SkyTimeMode.morning => l10n.skyTimeMorning,
        SkyTimeMode.noon => l10n.skyTimeNoon,
        SkyTimeMode.afternoon => l10n.skyTimeAfternoon,
        SkyTimeMode.golden => l10n.skyTimeGolden,
        SkyTimeMode.sunset => l10n.skyTimeSunset,
        SkyTimeMode.dusk => l10n.skyTimeDusk,
        SkyTimeMode.night => l10n.skyTimeNight,
      };
}
