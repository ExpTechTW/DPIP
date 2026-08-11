/// Hourly downloaded-vs-saved trend for the Debug page's Network usage section.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/network/network_usage_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Which series the chart plots: both stacked, or one on its own.
enum NetworkChartMode {
  /// Download (red) and Saved (green) as stacked bars.
  both,

  /// Download bars only.
  download,

  /// Saved bars only.
  saved,
}

/// Hourly trend for the Network usage section.
///
/// One bar per hour over the trailing [history] (typically 24 h, Taipei
/// wall-clock on the x-axis): **red** is what the app actually downloaded,
/// **green** what the cache saved on top — so the shape of the day and the
/// cache payoff read together. A [SegmentedButton] switches between stacked
/// and single-series views.
///
/// Deliberately English-only, matching the Debug page's convention.
class NetworkUsageChart extends StatefulWidget {
  const NetworkUsageChart({super.key, required this.history});

  final List<HourUsage> history;

  @override
  State<NetworkUsageChart> createState() => _NetworkUsageChartState();
}

class _NetworkUsageChartState extends State<NetworkUsageChart> {
  static const Color _downloadColor = Color(0xFFE53935); // red 600
  static const Color _savedColor = Color(0xFF66BB6A); // green 400

  NetworkChartMode _mode = NetworkChartMode.both;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showDownload =
        _mode == NetworkChartMode.both || _mode == NetworkChartMode.download;
    final showSaved =
        _mode == NetworkChartMode.both || _mode == NetworkChartMode.saved;

    // Scale the max to what this mode actually plots.
    final maxBytes = widget.history.fold<int>(
      0,
      (m, h) =>
          math.max(m, (showDownload ? h.down : 0) + (showSaved ? h.saved : 0)),
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
      for (var i = 0; i < widget.history.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [_rod(widget.history[i], divisor, showDownload, showSaved)],
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
              if (showDownload) ...[
                _legendDot(_downloadColor),
                const SizedBox(width: AppSpacing.sm),
                const Text('Downloaded'),
              ],
              if (showDownload && showSaved) ...[
                const SizedBox(width: AppSpacing.md),
              ],
              if (showSaved) ...[
                _legendDot(_savedColor),
                const SizedBox(width: AppSpacing.sm),
                const Text('Saved'),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<NetworkChartMode>(
            segments: const [
              ButtonSegment(value: NetworkChartMode.both, label: Text('Both')),
              ButtonSegment(
                value: NetworkChartMode.download,
                label: Text('Download'),
              ),
              ButtonSegment(
                value: NetworkChartMode.saved,
                label: Text('Saved'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
                        if (index < 0 || index >= widget.history.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _taipeiHour(widget.history[index].hour).toString(),
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
                      final hour = widget.history[group.x];
                      final lines = StringBuffer(
                        '${_taipeiHour(hour.hour).toString().padLeft(2, '0')}:00',
                      );
                      if (showDownload) {
                        lines.writeln(
                          '↓ ${_formatNumber(hour.down / divisor)} $unit',
                        );
                      }
                      if (showSaved) {
                        lines.writeln(
                          'Saved ${_formatNumber(hour.saved / divisor)} $unit',
                        );
                      }
                      return BarTooltipItem(
                        lines.toString().trimRight(),
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

  BarChartRodData _rod(
    HourUsage hour,
    double divisor,
    bool showDownload,
    bool showSaved,
  ) {
    final down = hour.down / divisor;
    final saved = hour.saved / divisor;
    return BarChartRodData(
      toY: (showDownload ? down : 0) + (showSaved ? saved : 0),
      width: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      rodStackItems: switch ((showDownload, showSaved)) {
        (true, true) => [
          BarChartRodStackItem(0, down, _downloadColor),
          BarChartRodStackItem(down, down + saved, _savedColor),
        ],
        (true, false) => [BarChartRodStackItem(0, down, _downloadColor)],
        (false, true) => [BarChartRodStackItem(0, saved, _savedColor)],
        (false, false) => const [],
      },
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
