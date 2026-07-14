import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The header at the top of the home sheet: the selected area name and its
/// current weather — condition icon + temperature on the left (2/3),
/// precipitation + humidity stacked on the right (1/3).
///
/// Weather follows the selected area via [HomeWeatherController]; a dash shows
/// while the first fetch is in flight. [reveal] (0→1) shifts the text to light
/// as the weather backdrop takes over, so it stays legible.
class HomeSheetHeader extends StatelessWidget {
  const HomeSheetHeader({super.key, this.reveal = 0});

  final double reveal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = lightenOnReveal(colors.onSurface, reveal);
    final secondary = lightenOnReveal(
      colors.onSurfaceVariant,
      reveal,
      toAlpha: 0.75,
    );

    final directory = context.read<TownDirectory>();
    final area = context.watch<RegionStore>().selected;
    final areaName = switch (area) {
      NationwideArea() => l10n.regionNationwide,
      CurrentArea(:final code) =>
        directory.byCode(code)?.fullName ?? l10n.regionCurrent,
      SavedArea(:final code) => directory.byCode(code)?.fullName ?? '',
    };

    final data = context.watch<HomeWeatherController>().weather?.data;
    final temp = data?.temperature;
    final humidity = data?.humidity;
    final rain = data?.rain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          areaName,
          style: theme.textTheme.headlineSmall?.copyWith(color: foreground),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left 2/3 — condition icon + temperature.
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.cloud_outlined, size: 48, color: secondary),
                  const SizedBox(width: AppSpacing.md),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: temp?.toStringAsFixed(1) ?? '—',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: foreground,
                          ),
                        ),
                        TextSpan(
                          text: '°C',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right 1/3 — precipitation over humidity.
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Metric(
                    label: l10n.weatherPrecipitation,
                    value: '${rain?.toStringAsFixed(1) ?? '0.0'} mm',
                    foreground: foreground,
                    secondary: secondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Metric(
                    label: l10n.weatherHumidity,
                    value: humidity == null ? '—' : '$humidity%',
                    foreground: foreground,
                    secondary: secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small label over a prominent value (e.g. "Precipitation" / "0.0 mm").
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.foreground,
    required this.secondary,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: secondary),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(color: foreground),
        ),
      ],
    );
  }
}
