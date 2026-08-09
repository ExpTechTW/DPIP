/// Home-sheet card: next-hour per-minute rainfall as a bar chart.
library;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart of the coming hour's rain (one rod per minute). Y has no mm labels;
/// the bottom axis shows a few clock ticks. Uses [RainHourTrend.placeholder]
/// until the forecast API is wired.
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

  /// Live trend when the API is ready; null → [RainHourTrend.placeholder].
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
    final skyIsLight = weatherSkyIsLight(weatherMode);
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
    final data = trend ?? RainHourTrend.placeholder();
    final maxY = data.mm.fold<double>(0, (a, b) => a > b ? a : b);
    // Keep a floor so an all-zero hour still draws a readable empty chart.
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.15;
    final barColor = colors.primary;

    return RainOnCard(
      intensity: rain,
      // The backdrop reveal is the scene alpha: the effect fades in with the
      // sky and runs at full strength once the sheet is up.
      opacity: reveal,
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
              SizedBox(
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
                            if (i != 0 &&
                                i != 15 &&
                                i != 30 &&
                                i != 45 &&
                                i != 59) {
                              return const SizedBox.shrink();
                            }
                            final minuteOffset = i == 59 ? 60 : i;
                            final label = _tickLabel(
                              data.startSecond,
                              minuteOffset,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: secondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
