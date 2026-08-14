/// Bottom-nav "資料" hub — links into catalogue pages (earthquake reports,
/// weather observation rankings, …).
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Catalogue of in-app data surfaces. The shell's 4th tab; entries push nested
/// routes under `/data/…` so the bottom nav stays visible.
///
/// Laid out as a catalogue rather than a plain list: the seismic entry is a
/// full-width featured card (the primary hazard surface), and the weather
/// rankings fill a two-column grid so every metric reads at a glance.
class DataPage extends StatelessWidget {
  const DataPage({super.key});

  /// This page's branch index in the shell.
  static const int tabIndex = 3;

  /// Every sortable weather/rain metric — keep in sync with
  /// `WeatherRankingTab` (`?tab=` query values).
  static const _weatherRankingEntries = <(String tab, IconData icon)>[
    ('rain', Icons.umbrella_outlined),
    ('temperature', Icons.thermostat_outlined),
    ('tempExtremes', Icons.thermostat_auto_outlined),
    ('wind', Icons.air_outlined),
    ('gust', Icons.storm_outlined),
    ('humidity', Icons.water_drop_outlined),
    ('pressure', Icons.speed_outlined),
  ];

  static String _weatherRankingLabel(AppLocalizations l10n, String tab) =>
      switch (tab) {
        'temperature' => l10n.mapLayerTemperature,
        'tempExtremes' => l10n.weatherRankingTempExtremes,
        'wind' => l10n.weatherRankingWind,
        'gust' => l10n.weatherRankingGust,
        'humidity' => l10n.mapLayerHumidity,
        'pressure' => l10n.mapLayerPressure,
        _ => l10n.mapLayerRain,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navData)),
      body: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(l10n.dataSectionSeismic),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _SeismicCard(
              icon: Icons.monitor_heart_outlined,
              title: l10n.navEarthquake,
              subtitle: l10n.dataEarthquakeSubtitle,
              onTap: () => context.pushNamed(AppRoutes.earthquake),
            ),
          ),
          SectionHeader(l10n.dataSectionWeather),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.45,
            children: [
              for (final (tab, icon) in _weatherRankingEntries)
                _RankingGridTile(
                  icon: icon,
                  title: _weatherRankingLabel(l10n, tab),
                  accent: switch (tab) {
                    'rain' => colors.primary,
                    'temperature' => colors.tertiary,
                    _ => colors.secondary,
                  },
                  onTap: () => context.pushNamed(
                    AppRoutes.weatherRanking,
                    queryParameters: {'tab': tab},
                  ),
                ),
            ],
          ),
          SectionHeader(l10n.dataSectionAstronomy),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.45,
            children: [
              for (final (route, icon, label, accent)
                  in <(String, IconData, String, Color)>[
                    (
                      AppRoutes.moon,
                      Icons.nightlight_outlined,
                      l10n.moonTitle,
                      colors.tertiary,
                    ),
                    (
                      AppRoutes.sun,
                      Icons.wb_sunny_outlined,
                      l10n.sunTitle,
                      colors.primary,
                    ),
                    (
                      AppRoutes.planets,
                      Icons.blur_circular_outlined,
                      l10n.planetsTitle,
                      colors.secondary,
                    ),
                  ])
                _RankingGridTile(
                  icon: icon,
                  title: label,
                  accent: accent,
                  onTap: () => context.pushNamed(route),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The seismic entry — a full-width highlighted card so the primary hazard
/// surface stands out from the ranking grid below it.
class _SeismicCard extends StatelessWidget {
  const _SeismicCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: colors.onSecondaryContainer),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// A metric card in the weather-ranking grid — tonal surface, icon badge, and
/// the ranking label with a forward affordance.
class _RankingGridTile extends StatelessWidget {
  const _RankingGridTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(icon, size: 22, color: accent),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
