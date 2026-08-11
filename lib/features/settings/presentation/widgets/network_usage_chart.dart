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

/// Which time window the chart shows.
enum NetworkChartWindow {
  /// Trailing 24 hours, one point per hour.
  day,

  /// Trailing 7 days, one point per 6 hours.
  week,
}

/// Trend for the Network usage section, switchable between the last 24 hours
/// (hourly) and the last 7 days (6-hour buckets).
///
/// One bar per point: **red** is what the app actually downloaded, **green**
/// what the cache saved on top — so the shape of the day and the cache payoff
/// read together. A [SegmentedButton] switches the window (24h / 7d), another
/// the series (stacked, download-only, saved-only). The x-axis is labelled in
/// Taipei wall-clock (`11日13時`).
///
/// Deliberately English-only, matching the Debug page's convention.
class NetworkUsageChart extends StatefulWidget {
  const NetworkUsageChart({
    super.key,
    required this.history,
    required this.week,
  });

  /// Trailing 24 hours, one [HourUsage] per hour.
  final List<HourUsage> history;

  /// Trailing 7 days, one [HourUsage] per 6-hour bucket.
  final List<HourUsage> week;

  @override
  State<NetworkUsageChart> createState() => _NetworkUsageChartState();
}

class _NetworkUsageChartState extends State<NetworkUsageChart> {
  static const Color _downloadColor = Color(0xFFE53935); // red 600
  static const Color _savedColor = Color(0xFF66BB6A); // green 400

  NetworkChartMode _mode = NetworkChartMode.both;
  NetworkChartWindow _window = NetworkChartWindow.day;

  /// The samples the active window plots.
  List<HourUsage> get _samples =>
      _window == NetworkChartWindow.day ? widget.history : widget.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final samples = _samples;
    final showDownload =
        _mode == NetworkChartMode.both || _mode == NetworkChartMode.download;
    final showSaved =
        _mode == NetworkChartMode.both || _mode == NetworkChartMode.saved;

    // Scale the max to what this mode actually plots.
    final maxBytes = samples.fold<int>(
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

    // Plot in the smaller unit that still fits the largest point, so a light
    // usage day isn't a sub-one-MB sliver.
    final (String unit, double divisor) = maxBytes >= 1024 * 1024
        ? ('MB', 1024 * 1024)
        : ('KB', 1024.0);
    final maxY = (maxBytes / divisor).ceilToDouble();
    final yInterval = maxY / 4;

    final groups = [
      for (var i = 0; i < samples.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [_rod(samples[i], divisor, showDownload, showSaved)],
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
          _ModeToggle(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<NetworkChartWindow>(
            segments: const [
              ButtonSegment(value: NetworkChartWindow.day, label: Text('24h')),
              ButtonSegment(value: NetworkChartWindow.week, label: Text('7d')),
            ],
            selected: {_window},
            onSelectionChanged: (selection) =>
                setState(() => _window = selection.first),
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
                groupsSpace: _window == NetworkChartWindow.day ? 2 : 6,
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
                      // 24h: every 4th hour. 7d: every 4th six-hour bucket,
                      // i.e. one label a day.
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= samples.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            _taipeiLabel(samples[index].hour),
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
                      final sample = samples[group.x];
                      final lines = StringBuffer(_taipeiLabel(sample.hour));
                      if (showDownload) {
                        lines.writeln(
                          '↓ ${_formatNumber(sample.down / divisor)} $unit',
                        );
                      }
                      if (showSaved) {
                        lines.writeln(
                          'Saved ${_formatNumber(sample.saved / divisor)} $unit',
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
    HourUsage sample,
    double divisor,
    bool showDownload,
    bool showSaved,
  ) {
    final down = sample.down / divisor;
    final saved = sample.saved / divisor;
    return BarChartRodData(
      toY: (showDownload ? down : 0) + (showSaved ? saved : 0),
      width: _window == NetworkChartWindow.day ? 6 : 12,
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

  /// Taipei wall-clock label of a UTC epoch hour, e.g. `11日13時`.
  static String _taipeiLabel(int utcHour) {
    final time = AppTime.taipei(
      DateTime.fromMillisecondsSinceEpoch(utcHour * 3600000, isUtc: true),
    );
    // l10n-ignore: owner-specified zh-TW time format on the English-only debug page.
    return '${time.day}日${time.hour}時';
  }
}

/// The series selector — stacked, download-only, or saved-only.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final NetworkChartMode mode;
  final ValueChanged<NetworkChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<NetworkChartMode>(
      segments: const [
        ButtonSegment(value: NetworkChartMode.both, label: Text('Both')),
        ButtonSegment(
          value: NetworkChartMode.download,
          label: Text('Download'),
        ),
        ButtonSegment(value: NetworkChartMode.saved, label: Text('Saved')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
