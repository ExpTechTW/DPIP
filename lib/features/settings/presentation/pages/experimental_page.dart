import 'package:dpip/features/settings/domain/weather_mode.dart';
import 'package:dpip/features/settings/presentation/experimental_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Experimental / in-progress features, reachable from the More tab.
///
/// Currently hosts the weather-animation override that drives the home
/// backdrop.
class ExperimentalPage extends StatelessWidget {
  const ExperimentalPage({super.key});

  /// Route path.
  static const String path = '/experimental';

  /// Route name.
  static const String name = 'experimental';

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
        ],
      ),
    );
  }

  IconData _iconFor(WeatherMode mode) => switch (mode) {
    WeatherMode.auto => Icons.auto_mode,
    WeatherMode.clear => Icons.wb_sunny_outlined,
    WeatherMode.rain => Icons.water_drop_outlined,
    WeatherMode.fog => Icons.foggy,
    WeatherMode.thunderstorm => Icons.thunderstorm_outlined,
  };

  String _labelFor(WeatherMode mode, AppLocalizations l10n) => switch (mode) {
    WeatherMode.auto => l10n.weatherModeAuto,
    WeatherMode.clear => l10n.weatherModeClear,
    WeatherMode.rain => l10n.weatherModeRain,
    WeatherMode.fog => l10n.weatherModeFog,
    WeatherMode.thunderstorm => l10n.weatherModeThunderstorm,
  };
}
