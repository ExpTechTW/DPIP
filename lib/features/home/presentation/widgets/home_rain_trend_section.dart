/// Home-sheet card: next-hour per-minute precipitation as a bar chart.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// intl 0.20 defines its own `TextDirection` class, which would shadow dart:ui's
// enum used by `TextPainter` — pull only `DateFormat` to keep them apart.
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

/// Bar chart of the coming hour's rain (one rod per minute). Y has no mm labels;
/// the bottom axis shows a few clock ticks.
///
/// Reads the live trend from [HomeWeatherController] (which follows the
/// selected township). The title carries the data's update time — the server's
/// `start` stamp as Taipei wall clock. While no data is available the chart
/// area is a grey pane: a spinner during the first fetch, an error + retry row
/// on failure — never a fabricated chart.
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
      body = _Chart(
        data: data,
        now: AppTime.utc,
        barColor: colors.primary,
        secondary: secondary,
      );
    } else {
      body = _NoData(
        loading: controller.loading,
        failure: controller.hourTrendFailure,
        secondary: secondary,
        onRetry: controller.refresh,
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
                  if (data != null)
                    Text(
                      l10n.homeRainTrendUpdated(_updatedClock(data)),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w500,
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

  /// Taipei wall-clock `HH:mm` of the trend's server `start` stamp — the
  /// data's own moment, so it stays honest even if the fetch was a while ago.
  static String _updatedClock(RainHourTrend data) {
    final taipei = data.startUtc.add(const Duration(hours: 8));
    return DateFormat('HH:mm').format(taipei);
  }
}

/// Grey pane replacing the chart while no trend data is available: the same
/// 120px band the chart would occupy, tinted by the card's surface role.
class _NoData extends StatelessWidget {
  const _NoData({
    required this.loading,
    required this.failure,
    required this.secondary,
    required this.onRetry,
  });

  final bool loading;
  final Failure? failure;
  final Color secondary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final Widget child;
    if (loading) {
      child = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: secondary),
      );
    } else if (failure != null) {
      child = Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context).homeForecastEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: AppRadius.medium,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Center(child: child),
    );
  }
}

/// The trend's bar chart: one rod per minute, no mm / numeric Y labels — height
/// alone carries intensity; the bottom axis labels minutes from now.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.data,
    required this.now,
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

  /// Pixels the label occupies, so the tick can be re-centred on its axis.
  static double _textWidth(String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  final RainHourTrend data;

  /// Corrected "now" (UTC). The chart is anchored to it: bar i is the minute
  /// `now + i`, so the data window [data.startUtc, +60 m) lands partway in and
  /// minutes past its end carry no forecast (full-height grey rods).
  final DateTime now;

  final Color barColor;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The chart runs from "now"; the data covers [start, start+60 m) only.
    // Minutes outside that window have no forecast — [headEnd] bars before the
    // data begins (a fetch newer than its stamp) and everything from
    // [tailStart] on (the usual case: the hour ran out ahead of the clock).
    final elapsed = now.difference(data.startUtc).inMinutes;
    final headEnd = math.min(math.max(0, -elapsed), data.mm.length);
    final tailStart = math.min(
      math.max(data.mm.length - elapsed, 0),
      data.mm.length,
    );

    double valueAt(int i) {
      final source = i + elapsed;
      if (source < 0 || source >= data.mm.length) return 0;
      return math.min(data.mm[source], _maxMm);
    }

    // Minutes outside the data window carry no forecast — render their rods as
    // full-height grey bars, so the missing span reads as a grey band drawn by
    // the chart itself (no overlay to misalign with the plot area).
    bool hasDataAt(int i) => i >= headEnd && i < tailStart;

    final chart = BarChart(
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
                  toY: hasDataAt(i) ? valueAt(i) : _maxMm,
                  width: 2.5,
                  color: hasDataAt(i)
                      ? barColor
                      : secondary.withValues(alpha: 0.28),
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
                final style = Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: secondary);
                // fl_chart centres every title widget on its tick's axis
                // position, so a bare [tick, label] row would push the tick
                // left of the bar (X=0's lands off the chart). Mirroring the
                // label width on the left re-centres the tick on the axis.
                final labelWidth = _textWidth(label, style);
                return Padding(
                  padding: EdgeInsets.only(left: labelWidth + AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 1,
                        height: 6,
                        color: secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(label, style: style),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    return SizedBox(height: 120, child: chart);
  }
}
