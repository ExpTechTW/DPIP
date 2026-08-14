/// The radio's airtime over the last 24 hours: how busy the channel was, and
/// how much of that was this radio transmitting.
///
/// **One axis, on purpose.** Both series are a percentage of airtime, so they
/// share a scale and can be read against each other — that comparison *is* the
/// question ("is the congestion mine or everyone's?"). Two y-scales would let
/// any pair of shapes be drawn to look alike, which is the most common way a
/// chart lies.
///
/// Air time is drawn as a filled area under the channel line rather than a
/// second free-floating line, because it is a *part* of the total: the fill is
/// this radio's share, the gap above it everyone else's.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MeshUtilizationChart extends StatelessWidget {
  const MeshUtilizationChart({super.key, required this.samples});

  /// Oldest first, inside [MeshStore.metricRetention].
  final List<MeshMetricSample> samples;

  /// Series colours, stepped per mode from the same two hues and validated
  /// against each surface (lightness band, chroma, CVD separation at
  /// ΔE ≥ 8, and 3:1 contrast). Dark is its own step, not a flip.
  static const Color _channelLight = Color(0xFF1E88E5);
  static const Color _airLight = Color(0xFFD97706);
  static const Color _channelDark = Color(0xFF3D96E8);
  static const Color _airDark = Color(0xFFBF8517);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final channelColor = dark ? _channelDark : _channelLight;
    final airColor = dark ? _airDark : _airLight;

    final points = [
      for (final sample in samples)
        if (sample.channelUtilization != null || sample.airUtilTx != null)
          sample,
    ];
    if (points.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          l10n.meshtasticNoHistory,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final first = points.first.at.millisecondsSinceEpoch.toDouble();
    final last = points.last.at.millisecondsSinceEpoch.toDouble();
    // A flat 0–100 axis would squash a mesh that idles under 10%; the ceiling
    // follows the data instead, with a floor so a quiet radio isn't magnified
    // into a dramatic-looking one.
    final peak = points.fold<double>(0, (max, sample) {
      final channel = sample.channelUtilization ?? 0;
      final air = sample.airUtilTx ?? 0;
      return [max, channel, air].reduce((a, b) => a > b ? a : b);
    });
    final ceiling = peak <= 10 ? 10.0 : (peak * 1.2).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _LegendEntry(
                color: channelColor,
                label: l10n.meshtasticChannelUse,
                value: points.last.channelUtilization,
              ),
              _LegendEntry(
                color: airColor,
                label: l10n.meshtasticAirtime,
                value: points.last.airUtilTx,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: first,
                maxX: last,
                minY: 0,
                maxY: ceiling,
                clipData: const FlClipData.all(),
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: ceiling / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    // Recessive: the grid orients, it doesn't compete.
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: ceiling / 2,
                      getTitlesWidget: (value, meta) => Text(
                        // l10n-ignore: percentage axis tick
                        '${value.round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      // Ends only: a 24-hour window needs its bounds, not a
                      // tick every hour.
                      interval: (last - first).clamp(1, double.infinity),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          _hourLabel(value),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  // Air time first so the channel line draws over its fill.
                  _series(points, (s) => s.airUtilTx, airColor, filled: true),
                  _series(points, (s) => s.channelUtilization, channelColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _series(
    List<MeshMetricSample> points,
    double? Function(MeshMetricSample) value,
    Color color, {
    bool filled = false,
  }) => LineChartBarData(
    spots: [
      for (final sample in points)
        if (value(sample) != null)
          FlSpot(sample.at.millisecondsSinceEpoch.toDouble(), value(sample)!),
    ],
    color: color,
    barWidth: 2,
    isCurved: true,
    curveSmoothness: 0.2,
    preventCurveOverShooting: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: filled,
      color: color.withValues(alpha: 0.18),
    ),
  );

  // l10n-ignore: clock tick on the time axis
  String _hourLabel(double millis) {
    final at = DateTime.fromMillisecondsSinceEpoch(millis.round());
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }
}

/// A legend entry that also carries the latest reading — identity never rests
/// on colour alone, and the number people actually want is the current one.
class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          // Text wears text tokens; the swatch beside it carries identity.
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          // l10n-ignore: percentage readout
          value == null ? '—' : '${value!.toStringAsFixed(1)}%',
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
