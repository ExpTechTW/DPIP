/// Home-sheet card: next-hour per-minute precipitation as a bar chart.
library;

import 'dart:math' as math;

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

    // The one-line reading under the title — intensity and whether the rain
    // keeps up through the hour. Nothing for an all-dry hour.
    String? subtitle;
    if (data != null) {
      final s = data.summary;
      subtitle = switch (s.grade) {
        RainHourTrendGrade.none => null,
        RainHourTrendGrade.scattered => l10n.homeRainTrendScattered,
        RainHourTrendGrade.light =>
          s.sustained
              ? l10n.homeRainTrendLightSustained
              : l10n.homeRainTrendLightStopping(s.stopInMinutes!),
        RainHourTrendGrade.heavy =>
          s.sustained
              ? l10n.homeRainTrendHeavySustained
              : l10n.homeRainTrendHeavyStopping(s.stopInMinutes!),
      };
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
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
/// alone carries intensity; the bottom axis labels minutes from now.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.data,
    required this.barColor,
    required this.secondary,
  });

  /// Fixed Y ceiling in mm — the API can forecast above this, so each bar is
  /// clamped at [_maxMm]. The scale's top gridline is excluded by fl_chart's
  /// `maxIncluded: false`, so the ceiling is one interval above the last guide
  /// (35) to keep the 30 mm line visible.
  static const double _maxMm = 35;

  /// X-axis ticks, minutes from [RainHourTrend.startSecond].
  static const List<int> _ticks = [0, 10, 20, 30, 40, 50];

  final RainHourTrend data;
  final Color barColor;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      // Room for the edge X labels (現在 / 50分) — the chart clips its own
      // titles at the first/last bar otherwise.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 120,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: _maxMm,
            alignment: BarChartAlignment.spaceBetween,
            groupsSpace: 0,
            barGroups: [
              for (var i = 0; i < data.mm.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: math.min(data.mm[i], _maxMm),
                      width: 2.5,
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(1),
                      ),
                    ),
                  ],
                ),
            ],
            // A solid X axis, plus 10 / 20 / 30 mm dashed guides — the fixed
            // Y ceiling makes them land on stable fractions of the chart
            // height. The 0 line is suppressed: it sits flush on the X axis,
            // where it would read as an axis rule rather than a guide.
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 10,
              getDrawingHorizontalLine: (value) => value == 0
                  ? FlLine(color: Colors.transparent, strokeWidth: 0)
                  : FlLine(
                      color: secondary.withValues(alpha: 0.35),
                      strokeWidth: 1,
                      dashArray: const [4, 4],
                    ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: secondary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
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
                    final minute = value.round();
                    if (!_ticks.contains(minute)) {
                      return const SizedBox.shrink();
                    }
                    final label = minute == 0
                        ? l10n.mapTimelineNow
                        : l10n.homeRainTrendMinute(minute);
                    // The titles band starts flush under the X axis, and fl_chart
                    // stretches each title widget to the full band height — so
                    // start-alignment pins the tick's top to the axis line (the
                    // tick hangs down from it) and rides the label up beside it.
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 1,
                          height: 6,
                          color: secondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          label,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: secondary),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
