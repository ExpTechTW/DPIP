/// Home-sheet card: next-hour per-minute rainfall as a bar chart.
library;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bar chart of the coming hour's rain (one rod per minute). Y has no mm labels;
/// the bottom axis shows a few clock ticks.
///
/// Reads the live trend from [HomeWeatherController] (which follows the
/// selected township); a spinner shows while the first fetch is in flight and
/// an error + retry row on failure — never a fabricated chart. Falls back to
/// [RainHourTrend.placeholder] only when the controller has no data to report
/// at all (no township, pre-wiring state).
class HomeRainTrendSection extends StatelessWidget {
  const HomeRainTrendSection({
    super.key,
    this.reveal = 0,
    this.trend,
    this.rain = 0,
    this.sky,
    this.weatherMode = WeatherMode.auto,
  });

  /// Weather-backdrop reveal (0→1) — glass + lightened foregrounds.
  final double reveal;

  /// Live trend override (widget tests); null → the controller's own data.
  final RainHourTrend? trend;

  /// The sky colour the card tints itself from — `SkyLutCache.panelAmbient`, or
  /// null when no backdrop is running. The reference's card is a 20 % pane of the sky,
  /// so without one there is nothing for it to be a pane *of* and it falls back
  /// to an opaque plate.
  final Color? sky;

  /// Backdrop sky mode — decides whether card ink goes dark or white as the
  /// card dissolves into the sky.
  final WeatherMode weatherMode;

  /// How hard it is raining *on this card* (0→1): droplets clinging to its face
  /// and water splashing off its top edge. 0 leaves the card untouched.
  final double rain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final skyIsLight = skyIsLightFrom(sky, weatherMode);
    final foreground = glassOnSurface(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final secondary = glassOnSurfaceVariant(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final cardColor = glassSurface(colors, reveal, sky: sky);

    final controller = context.watch<HomeWeatherController>();
    final data = trend ?? controller.hourTrend;

    final Widget body;
    if (data != null) {
      body = _Chart(data: data, barColor: colors.primary, secondary: secondary);
    } else if (controller.loading) {
      body = SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: secondary),
          ),
        ),
      );
    } else if (controller.hourTrendFailure != null) {
      body = Row(
        children: [
          Expanded(
            child: Text(
              l10n.homeForecastEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ),
          TextButton(
            onPressed: controller.refresh,
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    } else {
      body = _Chart(
        data: RainHourTrend.placeholder(),
        barColor: colors.primary,
        secondary: secondary,
      );
    }

    return RainOnCard(
      intensity: rain,
      // The backdrop reveal is the scene alpha: the effect fades in with the
      // sky and runs at full strength once the sheet is up.
      opacity: reveal,
      // glass defaults to true: the face gets the refracting droplets, same
      // as every other card — gated off automatically once the card's own
      // position gate closes, on its way up past the fold.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppRadius.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop_outlined, size: 18, color: secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.homeRainTrendTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

/// The trend's bar chart: one rod per minute, no mm / numeric Y labels — height
/// alone carries intensity; the bottom axis shows a few clock ticks.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.data,
    required this.barColor,
    required this.secondary,
  });

  final RainHourTrend data;
  final Color barColor;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final maxY = data.mm.fold<double>(0, (a, b) => a > b ? a : b);
    // Keep a floor so an all-zero hour still draws a readable empty chart.
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.15;

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: chartMaxY,
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: 0,
          barGroups: [
            for (var i = 0; i < data.mm.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data.mm[i],
                    width: 2.5,
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(1),
                    ),
                  ),
                ],
              ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            // No mm / numeric Y labels — height alone carries intensity.
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  // Ticks at start / +15 / +30 / +45 / +60.
                  if (i != 0 && i != 15 && i != 30 && i != 45 && i != 59) {
                    return const SizedBox.shrink();
                  }
                  final minuteOffset = i == 59 ? 60 : i;
                  final label = _tickLabel(data.startSecond, minuteOffset);
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: secondary),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Taipei wall clock (`HH:mm`) for [startSecond] + [minuteOffset].
  static String _tickLabel(int startSecond, int minuteOffset) {
    final wall = DateTime.fromMillisecondsSinceEpoch(
      (startSecond + minuteOffset * 60) * 1000,
      isUtc: true,
    ).add(const Duration(hours: 8));
    final hh = wall.hour.toString().padLeft(2, '0');
    final mm = wall.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
