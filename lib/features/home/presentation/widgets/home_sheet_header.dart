import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The header at the top of the home sheet: the selected area name and, for a
/// township, its current weather — condition icon + temperature on the left
/// (2/3), precipitation + humidity stacked on the right (1/3). 全國 shows the
/// name only (no point weather).
///
/// When [expanded] (sheet flush full-screen), typography and layout step up to
/// fill the hero band — same pattern as the station/typhoon chart sheets — so a
/// full-height sheet doesn't look like a short card on a void. Weather follows
/// the selected area via [HomeWeatherController]; a dash shows while the first
/// fetch is in flight. Ink tracks the weather sky via [inkOverWeather] — dark
/// theme [ColorScheme.onSurface] is white and vanishes on a clear daylight
/// backdrop without that shift.
class HomeSheetHeader extends StatelessWidget {
  const HomeSheetHeader({
    super.key,
    this.reveal = 0,
    this.expanded = false,
    this.weatherMode = WeatherMode.auto,
  });

  /// Weather-backdrop reveal (0→1) — drives sky-aware ink.
  final double reveal;

  /// Sheet is at (or past) the full-screen detent — drive larger type + layout.
  final bool expanded;

  /// Which sky the backdrop is rendering — picks dark vs white ink.
  final WeatherMode weatherMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final skyIsLight = weatherSkyIsLight(weatherMode);
    // Directly on the weather sky — not inside a glass card. Dark theme's
    // onSurface is white; on clear/fog daylight that must go dark with reveal.
    final foreground = inkOverWeather(colors, reveal, skyIsLight: skyIsLight);
    final secondary = inkOverWeatherVariant(
      colors,
      reveal,
      skyIsLight: skyIsLight,
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

    // 全國 has no township weather — name only. 所在地 without GPS: say so
    // instead of a dashed reading row.
    final nationwide = area is NationwideArea;
    final currentUnavailable = area is CurrentArea && area.code == null;

    // Name is the hero — larger when full-bleed (below typhoon's display*).
    final nameStyle =
        (expanded
                ? theme.textTheme.headlineLarge
                : theme.textTheme.headlineSmall)
            ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              height: 1.05,
              letterSpacing: -0.5,
            );
    final tempStyle =
        (expanded ? theme.textTheme.displayLarge : theme.textTheme.displaySmall)
            ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              height: 1,
            );
    final unitStyle =
        (expanded ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium)
            ?.copyWith(color: secondary);
    final iconSize = expanded ? 80.0 : 48.0;

    return Padding(
      // Extra band when flush so the hero isn't jammed under the status inset.
      padding: EdgeInsets.only(top: expanded ? AppSpacing.md : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            curve: Curves.easeOutCubic,
            style: nameStyle ?? const TextStyle(),
            child: Text(areaName),
          ),
          if (!nationwide) ...[
            SizedBox(height: expanded ? AppSpacing.xl : AppSpacing.lg),
            if (currentUnavailable)
              Row(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: expanded ? 24 : 20,
                    color: secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.regionCurrentUnavailable,
                      style:
                          (expanded
                                  ? theme.textTheme.bodyLarge
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(color: secondary),
                    ),
                  ),
                ],
              )
            else if (expanded)
              // Full-screen: temp as a full-width hero, metrics in a row below —
              // fills the band the way [_StationHero] grows the reading.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        size: iconSize,
                        color: secondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: temp?.toStringAsFixed(1) ?? '—',
                              style: tempStyle,
                            ),
                            TextSpan(text: '°C', style: unitStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: l10n.weatherPrecipitation,
                          value: rain == null
                              ? '—'
                              : '${rain.toStringAsFixed(1)} mm',
                          foreground: foreground,
                          secondary: secondary,
                          expanded: true,
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: l10n.weatherHumidity,
                          value: humidity == null ? '—' : '$humidity%',
                          foreground: foreground,
                          secondary: secondary,
                          expanded: true,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left 2/3 — condition icon + temperature.
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_outlined,
                          size: iconSize,
                          color: secondary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: temp?.toStringAsFixed(1) ?? '—',
                                style: tempStyle,
                              ),
                              TextSpan(text: '°C', style: unitStyle),
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
                          // A missing reading is a dash, never a fabricated 0.0 —
                          // "no rain" and "no data" must not look the same.
                          value: rain == null
                              ? '—'
                              : '${rain.toStringAsFixed(1)} mm',
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
        ],
      ),
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
    this.expanded = false,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color secondary;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              (expanded
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.labelMedium)
                  ?.copyWith(color: secondary),
        ),
        Text(
          value,
          style:
              (expanded
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
