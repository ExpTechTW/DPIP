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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navData)),
      body: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(l10n.dataSectionSeismic),
          _DataGroup(
            children: [
              _DataTile(
                icon: Icons.monitor_heart_outlined,
                title: l10n.navEarthquake,
                subtitle: l10n.dataEarthquakeSubtitle,
                onTap: () => context.pushNamed(AppRoutes.earthquake),
              ),
            ],
          ),
          SectionHeader(l10n.dataSectionWeather),
          _DataGroup(
            children: [
              for (final (tab, icon) in _weatherRankingEntries)
                _DataTile(
                  icon: icon,
                  title: _weatherRankingLabel(l10n, tab),
                  subtitle: l10n.dataWeatherRankingSubtitle,
                  onTap: () => context.pushNamed(
                    AppRoutes.weatherRanking,
                    queryParameters: {'tab': tab},
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tonal card wrapping one or more [_DataTile]s — same Material recipe as More.
class _DataGroup extends StatelessWidget {
  const _DataGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.xxl + AppSpacing.xl,
            color: theme.colorScheme.outlineVariant,
          ),
        );
      }
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.medium,
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
