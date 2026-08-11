/// Hourly downloaded-vs-saved trend for the Debug page's Network usage section.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One stacked bar per hour over the trailing [history] (typically 24 h, Taipei
/// wall-clock on the x-axis): the blue segment is what the app actually
/// downloaded, the green segment what the cache saved on top — so the shape of
/// the day and the cache payoff read together.
///
/// Deliberately English-only, matching the Debug page's convention.
class NetworkUsageChart extends StatelessWidget {
  const NetworkUsageChart({super.key, required this.history});

  final List<HourUsage> history;

  static const Color _savedColor = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final maxBytes = history.fold<int>(
      0,
      (m, h) => math.max(m, h.down + h.saved),
    );
    if (maxBytes == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Text(
          'No traffic recorded yet — use the app and come back.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    // Plot in the smaller unit that still fits the largest hour, so a light
    // usage day isn't a sub-one-MB sliver.
    final (String unit, double divisor) = maxBytes >= 1024 * 1024
        ? ('MB', 1024 * 1024)
        : ('KB', 1024.0);
    final maxY = (maxBytes / divisor).ceilToDouble();
    final yInterval = maxY / 4;

    final groups = [
      for (var i = 0; i < history.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: history[i].down / divisor + history[i].saved / divisor,
              width: 6,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
              rodStackItems: [
                BarChartRodStackItem(
                  0,
                  history[i].down / divisor,
                  colors.primary,
                ),
                BarChartRodStackItem(
                  history[i].down / divisor,
                  history[i].down / divisor + history[i].saved / divisor,
                  _savedColor,
                ),
              ],
            ),
          ],
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(colors.primary),
              const SizedBox(width: AppSpacing.sm),
              const Text('Downloaded'),
              const SizedBox(width: AppSpacing.md),
              _legendDot(_savedColor),
              const SizedBox(width: AppSpacing.sm),
              const Text('Saved'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceBetween,
                groupsSpace: 2,
                barGroups: groups,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value == 0 ? '0' : value.toStringAsFixed(0),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _taipeiHour(history[index].hour).toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceContainerHigh,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    tooltipMargin: AppSpacing.sm,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = history[group.x];
                      final down = hour.down / divisor;
                      final saved = hour.saved / divisor;
                      return BarTooltipItem(
                        '${_taipeiHour(hour.hour).toString().padLeft(2, '0')}:00\n'
                        '↓ ${_formatNumber(down)} $unit\n'
                        'Saved ${_formatNumber(saved)} $unit',
                        theme.textTheme.labelSmall!.copyWith(
                          color: colors.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  /// Taipei wall-clock hour of a UTC epoch hour — what the "now" column reads.
  static int _taipeiHour(int utcHour) => AppTime.taipei(
    DateTime.fromMillisecondsSinceEpoch(utcHour * 3600000, isUtc: true),
  ).hour;
}
