/// The radio panel's history charts — one visual language, four questions.
///
/// Every chart here is the same construction: a legend whose entries carry the
/// current reading (identity never rests on colour alone), an analysis line of
/// small stats where the data supports one, and a touch-enabled line chart on
/// a recessive grid with the day's bounds and midpoint on the time axis.
/// The shared scaffold ([MeshChart]) is what keeps them from drifting apart.
///
/// Axis policy, per chart: utilization and battery live on axes whose meaning
/// is fixed (percent — battery pinned to 0–100 so a healthy pack's 2% sag is
/// not magnified into a cliff); counts and rates follow their data with
/// headroom. One axis per chart, always — a second scale gets its own chart
/// or a legend reading, never a second y-axis.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/models/series_runs.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Channel/air utilization — how busy the mesh's airtime is.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final channelColor = dark ? _channelDark : _channelLight;
    final airColor = dark ? _airDark : _airLight;

    // Two lists on purpose. `readings` is what exists, and answers the
    // legend, the stats and the axis bounds. `samples` is every slice of the
    // day — including the ones that carried nothing — and is what gets
    // plotted, so `_line` can break at the holes. Handing the filtered list to
    // the plotter is what re-bridges a gap: the missing slices simply stop
    // existing and the line runs straight across the time they occupied.
    final readings = [
      for (final sample in samples)
        if (sample.channelUtilization != null || sample.airUtilTx != null)
          sample,
    ];
    if (readings.length < 2) return const MeshChartEmpty();
    final points = samples;

    // The axis follows the data so a mesh idling under 10% is readable, with
    // a floor so a quiet radio isn't magnified into a dramatic one.
    final peak = readings.fold<double>(0, (max, sample) {
      final channel = sample.channelUtilization ?? 0;
      final air = sample.airUtilTx ?? 0;
      return [max, channel, air].reduce((a, b) => a > b ? a : b);
    });
    final channelValues = [
      for (final p in readings)
        if (p.channelUtilization != null) p.channelUtilization!,
    ];
    final avg = channelValues.isEmpty
        ? null
        : channelValues.reduce((a, b) => a + b) / channelValues.length;

    return MeshChart(
      legend: [
        MeshChartLegendEntry(
          color: channelColor,
          label: l10n.meshtasticChannelUse,
          // l10n-ignore: percentage readout
          text: _pct(readings.last.channelUtilization),
        ),
        MeshChartLegendEntry(
          color: airColor,
          label: l10n.meshtasticAirtime,
          // l10n-ignore: percentage readout
          text: _pct(readings.last.airUtilTx),
        ),
      ],
      stats: [
        if (avg != null)
          // l10n-ignore: percentage readout
          (l10n.meshtasticStatAvg, '${avg.toStringAsFixed(1)}%'),
        // l10n-ignore: percentage readout
        (l10n.meshtasticStatPeak, '${peak.toStringAsFixed(1)}%'),
      ],
      minY: 0,
      maxY: peak <= 10 ? 10.0 : (peak * 1.2).ceilToDouble(),
      // l10n-ignore: percentage axis tick
      leftLabel: (value) => '${value.round()}%',
      first: points.first.at,
      last: points.last.at,
      series: [
        // Air time first so the channel line draws over its fill.
        ...meshChartLine(points, (s) => s.airUtilTx, airColor, filled: true),
        ...meshChartLine(points, (s) => s.channelUtilization, channelColor),
      ],
      tooltipUnit: '%',
    );
  }

  static String _pct(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}%';
}

/// The radio's battery over the day, with drain analysis.
class MeshBatteryChart extends StatelessWidget {
  const MeshBatteryChart({super.key, required this.samples});

  final List<MeshMetricSample> samples;

  static const Color _light = Color(0xFF2E7D32);
  static const Color _dark = Color(0xFF67BB6E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.dark ? _dark : _light;

    // Enough battery readings to draw a line.
    final batteryPoints = [
      for (final sample in samples)
        if (sample.batteryPercent != null) sample,
    ];
    if (batteryPoints.length < 2) return const MeshChartEmpty();

    // The chart plots **every** sample, gapped or not: a sample without a
    // battery reading sits on the time axis as a hole, and `_line` breaks
    // there. Filtering first — as the old code did — handed `_line` a
    // gapless series and re-bridged the gap it was supposed to show.
    final points = samples;
    final current = batteryPoints.last.batteryPercent!;
    final voltage = batteryPoints.last.voltage;
    final drain = _drainPerHour(batteryPoints);

    return MeshChart(
      legend: [
        MeshChartLegendEntry(
          color: color,
          label: l10n.meshtasticBattery,
          // l10n-ignore: percentage readout
          text: '${current.clamp(0, 100)}%',
        ),
        if (voltage != null)
          MeshChartLegendEntry(
            color: theme.colorScheme.outline,
            label: l10n.meshtasticVoltage,
            // l10n-ignore: volts readout
            text: '${voltage.toStringAsFixed(2)} V',
          ),
      ],
      stats: [
        if (drain != null && drain < -0.05) ...[
          // l10n-ignore: rate readout
          (l10n.meshtasticStatDrain, '${drain.toStringAsFixed(1)}%/h'),
          if (current <= 100)
            (l10n.meshtasticStatEta, _etaLabel(l10n, current, -drain)),
        ] else if (drain != null && drain > 0.05) ...[
          (l10n.meshtasticStatTrend, l10n.meshtasticStatCharging),
          // l10n-ignore: rate readout
          (l10n.meshtasticStatDrain, '+${drain.toStringAsFixed(1)}%/h'),
          // How long to full, by the same fit — the question a charging pack
          // raises is when it will be ready, and it is the same arithmetic
          // with the distance measured upwards.
          if (current < 100)
            (l10n.meshtasticStatFull, _etaLabel(l10n, 100 - current, drain)),
        ] else if (drain != null)
          (l10n.meshtasticStatTrend, l10n.meshtasticStatStable),
      ],
      minY: 0,
      maxY: 100,
      // l10n-ignore: percentage axis tick
      leftLabel: (value) => '${value.round()}%',
      first: points.first.at,
      last: points.last.at,
      series: [
        ...meshChartLine(
          points,
          // 101 means external power; the line stays a battery line, capped
          // at full.
          (s) => s.batteryPercent?.clamp(0, 100).toDouble(),
          color,
          filled: true,
        ),
      ],
      tooltipUnit: '%',
    );
  }

  /// How many readings the slope is fitted over.
  ///
  /// The *recent* trend, not the day's average. A pack that drained hard this
  /// morning and has been flat since would otherwise keep predicting a death
  /// that stopped approaching hours ago — and the estimate a user acts on is
  /// about what the radio is doing now. Sixty readings is roughly the last
  /// hour at the radio's usual cadence, long enough to average out the
  /// quantisation and short enough to follow a change.
  static const int _slopeWindow = 60;

  /// …and never across a hole, whatever the count says.
  ///
  /// The count alone is not a window. After an outage there may be only a
  /// handful of recent readings, and "the last sixty" then reaches back across
  /// the hole to whatever preceded it — fitting one line through an hour of
  /// now and an hour of yesterday, whose slope describes neither. So the fit
  /// is confined to the **trailing continuous run**, by the same rule the
  /// lines are drawn with ([splitSeriesRuns]).
  ///
  /// That rule is used rather than a fixed one-hour cutoff because it adapts
  /// to the feed: at the radio's usual one-a-minute cadence sixty readings
  /// *are* the last hour, and on a radio that reports hourly a fixed hour
  /// would leave one reading and refuse to answer at all — throwing away a
  /// perfectly good twelve-hour trend.

  /// Battery slope in %/hour from a least-squares fit over the most recent
  /// [_slopeWindow] on-battery samples (external-power readings pin at 101 and
  /// would fake a charge).
  ///
  /// A fit, not first-minus-last: telemetry percent is quantised and noisy,
  /// and two arbitrary endpoints turn one noisy reading into the whole
  /// answer. Null with under an hour of readings — a slope from minutes is
  /// noise.
  static double? _drainPerHour(List<MeshMetricSample> points) {
    final onBattery = [
      for (final p in points)
        if (p.batteryPercent != null && p.batteryPercent! <= 100) p,
    ];
    if (onBattery.isEmpty) return null;
    final runs = splitSeriesRuns<int>([
      for (final p in onBattery) (p.at, p.batteryPercent),
    ]);
    if (runs.isEmpty) return null;
    final recent = runs.last;
    final usable = recent.length <= _slopeWindow
        ? recent
        : recent.sublist(recent.length - _slopeWindow);
    if (usable.length < 3) return null;
    // Enough elapsed time for the fit to mean something. Deliberately shorter
    // than the hour [_slopeWindow] usually covers: sixty readings a minute
    // apart span fifty-nine, and an hour-long guard would reject exactly the
    // window this is fitted over.
    final spanMs =
        usable.last.$1.millisecondsSinceEpoch -
        usable.first.$1.millisecondsSinceEpoch;
    if (spanMs < 20 * 60 * 1000) return null;
    final n = usable.length;
    final t0 = usable.first.$1.millisecondsSinceEpoch;
    var sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0;
    for (final (at, battery) in usable) {
      final x = (at.millisecondsSinceEpoch - t0) / (3600 * 1000);
      final y = battery!.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-9) return null;
    return (n * sumXY - sumX * sumY) / denom;
  }

  /// [distance] is how many percentage points remain to travel and [rate] how
  /// many per hour it is travelling — both positive, whichever way it is
  /// going.
  static String _etaLabel(AppLocalizations l10n, int distance, double rate) {
    final hours = distance / rate;
    if (hours >= 48) return l10n.meshtasticEtaDays((hours / 24).round());
    if (hours >= 1) return l10n.meshtasticEtaHours(hours.round());
    return l10n.meshtasticEtaHours(1);
  }
}

/// How many nodes the radio could see through the day, and how many of them
/// were recently heard — the mesh's coverage health.
class MeshNodesChart extends StatelessWidget {
  const MeshNodesChart({super.key, required this.samples});

  final List<MeshMetricSample> samples;

  /// Same validated palette family as the utilization pair — counts get the
  /// violet/teal steps so the four charts never reuse a hue for a different
  /// meaning.
  static const Color _totalLight = Color(0xFF7B1FA2);
  static const Color _totalDark = Color(0xFFAB63C6);
  static const Color _onlineLight = Color(0xFF00796B);
  static const Color _onlineDark = Color(0xFF2FA595);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final totalColor = dark ? _totalDark : _totalLight;
    final onlineColor = dark ? _onlineDark : _onlineLight;

    // See [MeshUtilizationChart]: readings answer the legend, every sample
    // gets plotted so the line can break where the radio said nothing.
    final readings = [
      for (final sample in samples)
        if (sample.nodesTotal != null) sample,
    ];
    if (readings.length < 2) return const MeshChartEmpty();
    final points = samples;

    final peakOnline = readings.fold<int>(
      0,
      (max, s) => math.max(max, s.nodesOnline ?? 0),
    );
    final ceiling = readings.fold<int>(
      1,
      (max, s) => math.max(max, s.nodesTotal ?? 0),
    );

    return MeshChart(
      legend: [
        MeshChartLegendEntry(
          color: totalColor,
          label: l10n.meshtasticNodesTotal,
          text: '${readings.last.nodesTotal}',
        ),
        MeshChartLegendEntry(
          color: onlineColor,
          label: l10n.meshtasticNodesOnline,
          text: '${readings.last.nodesOnline ?? '—'}',
        ),
      ],
      stats: [(l10n.meshtasticStatPeak, '$peakOnline')],
      minY: 0,
      maxY: (ceiling * 1.15).ceilToDouble(),
      leftLabel: (value) => '${value.round()}',
      first: points.first.at,
      last: points.last.at,
      series: [
        ...meshChartLine(points, (s) => s.nodesTotal?.toDouble(), totalColor),
        ...meshChartLine(
          points,
          (s) => s.nodesOnline?.toDouble(),
          onlineColor,
          filled: true,
        ),
      ],
      tooltipUnit: '',
    );
  }
}

/// Packets in and out per sample slice — the day's activity rhythm.
class MeshTrafficChart extends StatelessWidget {
  const MeshTrafficChart({super.key, required this.samples});

  final List<MeshMetricSample> samples;

  static const Color _rxLight = Color(0xFF0288D1);
  static const Color _rxDark = Color(0xFF3FA1DC);
  static const Color _txLight = Color(0xFFC2185B);
  static const Color _txDark = Color(0xFFD35186);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rxColor = dark ? _rxDark : _rxLight;
    final txColor = dark ? _txDark : _txLight;

    // See [MeshUtilizationChart]: readings answer the legend, every sample
    // gets plotted so the line can break where nothing was counted.
    final readings = [
      for (final sample in samples)
        if (sample.rxPackets != null || sample.txPackets != null) sample,
    ];
    if (readings.length < 2) return const MeshChartEmpty();
    final points = samples;

    var rxTotal = 0, txTotal = 0, peak = 0;
    for (final p in readings) {
      rxTotal += p.rxPackets ?? 0;
      txTotal += p.txPackets ?? 0;
      peak = math.max(peak, math.max(p.rxPackets ?? 0, p.txPackets ?? 0));
    }

    return MeshChart(
      legend: [
        MeshChartLegendEntry(
          color: rxColor,
          label: l10n.meshtasticRx,
          text: '$rxTotal',
        ),
        MeshChartLegendEntry(
          color: txColor,
          label: l10n.meshtasticTx,
          text: '$txTotal',
        ),
      ],
      stats: [(l10n.meshtasticStatPeak, '$peak')],
      minY: 0,
      maxY: math.max(4, peak * 1.2).ceilToDouble(),
      leftLabel: (value) => '${value.round()}',
      first: points.first.at,
      last: points.last.at,
      series: [
        ...meshChartLine(
          points,
          (s) => s.rxPackets?.toDouble(),
          rxColor,
          filled: true,
        ),
        ...meshChartLine(points, (s) => s.txPackets?.toDouble(), txColor),
      ],
      tooltipUnit: '',
    );
  }
}

/// One line series in the shared style: thin, softly curved, optional
/// gradient fill fading to nothing so stacked fills never turn to mud.
///
/// Returns **one bar per continuous run** of readings — see [splitSeriesRuns]
/// for what counts as continuous. Runs of a single point are dropped (there is
/// no line in one point).
///
/// Breaking on a missing *value* alone was not enough: the recorder writes a
/// row only when there is something to record, so an hours-long outage leaves
/// no rows at all and the two halves of the day sit adjacent in the list with
/// nothing null between them. The split is therefore on **time** as well.
List<LineChartBarData> meshChartLine(
  List<MeshMetricSample> points,
  double? Function(MeshMetricSample) value,
  Color color, {
  bool filled = false,
}) {
  final gradient = filled
      ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
          ],
        )
      : null;
  LineChartBarData bar(List<FlSpot> spots) => LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 2,
    isCurved: true,
    curveSmoothness: 0.2,
    preventCurveOverShooting: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: filled, gradient: gradient),
  );

  final runs = splitSeriesRuns<double>([
    for (final sample in points) (sample.at, value(sample)),
  ]);
  return [
    for (final run in runs)
      if (run.length >= 2)
        bar([
          for (final (at, v) in run)
            FlSpot(at.millisecondsSinceEpoch.toDouble(), v!),
        ]),
  ];
}

/// The shared chart shell: legend, stats line, and a touch-enabled line chart
/// with the day's bounds and midpoint on the time axis.
class MeshChart extends StatelessWidget {
  const MeshChart({
    super.key,
    required this.legend,
    required this.stats,
    required this.minY,
    required this.maxY,
    required this.leftLabel,
    required this.first,
    required this.last,
    required this.series,
    required this.tooltipUnit,
    this.caption = '',
  });

  final List<Widget> legend;

  /// `(label, value)` analysis readouts under the legend; empty hides the row.
  final List<(String, String)> stats;

  final double minY;
  final double maxY;
  final String Function(double) leftLabel;
  final DateTime first;
  final DateTime last;
  final List<LineChartBarData> series;

  /// Appended to tooltip values ('%' or '').
  final String tooltipUnit;

  /// One sentence under the chart saying what the shape means, for readings
  /// whose number is only legible to someone who already knows the mechanics.
  /// Empty hides the line.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstMs = first.millisecondsSinceEpoch.toDouble();
    final lastMs = last.millisecondsSinceEpoch.toDouble();
    final span = (lastMs - firstMs).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: legend,
          ),
        ),
        if (stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.lg,
              children: [
                for (final (label, value) in stats)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$label ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: value,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        else
          const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SizedBox(
            height: 132,
            child: LineChart(
              LineChartData(
                minX: firstMs,
                maxX: lastMs,
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  // Touch to read a moment: the tooltip names each series'
                  // value at the pressed time. Hit area wider than the line.
                  touchSpotThreshold: 24,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHighest,
                    tooltipBorderRadius: AppRadius.small,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) => [
                      for (final (i, spot) in spots.indexed)
                        LineTooltipItem(
                          i == 0
                              ? '${_clock(spot.x)}\n'
                                    '${_value(spot.y)}$tooltipUnit'
                              : '${_value(spot.y)}$tooltipUnit',
                          theme.textTheme.labelSmall!.copyWith(
                            color: spot.bar.color,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    // Recessive: the grid orients, it doesn't compete.
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
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
                      interval: (maxY - minY) / 2,
                      getTitlesWidget: (value, meta) => Text(
                        leftLabel(value),
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
                      // Quarters, so the three interior ticks are the ones
                      // that get drawn. A label is centred on its value, so a
                      // tick sitting exactly on `minX` has half of itself
                      // outside the plot — it collided with the y-axis labels
                      // on the left and was clipped on the right. Skipping the
                      // bounds costs nothing: the window is chosen by the
                      // reader, so its ends are already known.
                      interval: span / 4,
                      getTitlesWidget: (value, meta) {
                        final edge = span / 100;
                        if (value <= firstMs + edge || value >= lastMs - edge) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            _clock(value),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: series,
              ),
            ),
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  // l10n-ignore: clock tick on the time axis
  static String _clock(double millis) {
    final at = DateTime.fromMillisecondsSinceEpoch(millis.round());
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }

  static String _value(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);
}

/// The consistent empty state: not enough samples for a line yet.
class MeshChartEmpty extends StatelessWidget {
  const MeshChartEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        AppLocalizations.of(context).meshtasticNoHistory,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A legend entry that also carries the latest reading — identity never rests
/// on colour alone, and the number people actually want is the current one.
class MeshChartLegendEntry extends StatelessWidget {
  const MeshChartLegendEntry({
    super.key,
    required this.color,
    required this.label,
    required this.text,
  });

  final Color color;
  final String label;
  final String text;

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
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
