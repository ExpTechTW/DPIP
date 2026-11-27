/// The two overrides that drive the home weather backdrop, as Experimental
/// features options.
///
/// They are separate axes on purpose: the look is the product of the weather
/// *and* where the keyframe ring sits, so testing needs both without squaring
/// the entries.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/core/weather/weather_icons.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Forces the weather the backdrop animates, or leaves it on Auto.
class WeatherModeOption extends StatelessWidget {
  const WeatherModeOption({super.key, required this.watchWeatherCode});

  /// Watches the live weather code — see `ExperimentalHost`.
  final int? Function(BuildContext context) watchWeatherCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = context.select<ExperimentalSettings, WeatherMode>(
      (s) => s.weatherMode,
    );
    // What Auto is showing right now, from the same input the backdrop uses.
    // It stays plain Auto until the station has reported a code.
    final autoWeather = weatherModeFor(watchWeatherCode(context) ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionTitle(l10n.weatherDynamicState),
        for (final mode in WeatherMode.values)
          _ChoiceTile(
            icon: _iconFor(mode),
            label: mode == WeatherMode.auto && autoWeather != WeatherMode.auto
                ? l10n.autoResolved(
                    l10n.weatherModeAuto,
                    _labelFor(autoWeather, l10n),
                  )
                : _labelFor(mode, l10n),
            selected: selected == mode,
            onTap: () =>
                context.read<ExperimentalSettings>().weatherMode = mode,
          ),
      ],
    );
  }

  // The same glyphs the weather surfaces use, so the mode picker previews
  // what it will actually draw.
  static IconData _iconFor(WeatherMode mode) => switch (mode) {
    WeatherMode.auto => Icons.auto_mode,
    WeatherMode.clear => clearDay,
    WeatherMode.cloudy => partlyCloudyDay,
    WeatherMode.overcast => cloudy,
    WeatherMode.rain => rainy,
    WeatherMode.snow => snowing,
    WeatherMode.sand => air,
    WeatherMode.fog => foggy,
    WeatherMode.thunderstorm => thunderstorm,
  };

  static String _labelFor(WeatherMode mode, AppLocalizations l10n) =>
      switch (mode) {
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
}

/// Forces the time of day the backdrop draws, or leaves it on Auto.
class SkyTimeOption extends StatelessWidget {
  const SkyTimeOption({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = context.select<ExperimentalSettings, SkyTimeMode>(
      (s) => s.skyTimeMode,
    );
    final local = AppTime.utc8;
    final autoSky = skyTimeModeForHour(local.hour + local.minute / 60.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OptionTitle(l10n.skyTime),
        for (final mode in SkyTimeMode.values)
          _ChoiceTile(
            icon: _iconFor(mode),
            label: mode == SkyTimeMode.auto
                ? l10n.autoResolved(l10n.skyTimeAuto, _labelFor(autoSky, l10n))
                : _labelFor(mode, l10n),
            selected: selected == mode,
            onTap: () =>
                context.read<ExperimentalSettings>().skyTimeMode = mode,
          ),
      ],
    );
  }

  static IconData _iconFor(SkyTimeMode mode) => switch (mode) {
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

  static String _labelFor(SkyTimeMode mode, AppLocalizations l10n) =>
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

/// The option's own name, under its category's `SectionHeader` — a step
/// quieter than that header, so the two never read as siblings.
class _OptionTitle extends StatelessWidget {
  const _OptionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One choice of a single-select option: a check marks the one in force.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: selected
        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
        : null,
    onTap: onTap,
  );
}
