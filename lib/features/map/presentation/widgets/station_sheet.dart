/// The collapsible detail sheet for a station-value map layer: the tapped
/// station's current reading and its 24h / 7d trend chart.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A trend series to plot: absolute Unix-second [times] aligned index-wise to
/// [values] (nullable — a gap is skipped in the line).
class TrendSeries {
  const TrendSeries({required this.times, required this.values});

  final List<int> times;
  final List<double?> values;
}

/// What [StationSheet] needs from a station-value layer; the layer implements it.
abstract interface class StationSheetSource {
  /// The selected station code, or null when none is tapped.
  ValueListenable<String?> get selection;

  /// Bumped on every tap that (re-)selects a station, so the sheet can re-pop
  /// even when the same station is tapped again after being collapsed.
  ValueListenable<int> get selectionRevision;

  /// The station's display name for [id].
  String stationName(String id);

  /// A subtitle (county · town) for [id], or null.
  String? stationSubtitle(String id);

  /// The current reading text for [id] (e.g. "27.8°C"), or null if unknown.
  String? reading(String id);

  /// The colour this station's value has on the map, or null when it has no
  /// reading. Shown as a small mark beside the name so the sheet is visibly the
  /// dot the user just tapped — identity carried by a mark, not by tinting text.
  Color? valueColor(String id);

  /// The layer's short title (e.g. "溫度"), for the sheet header.
  String title(BuildContext context);

  /// The value unit (e.g. "°C"), labelling the chart's Y axis.
  String get unit;

  /// The trend series for [id] over [range] (`24h` | `7d`).
  Future<Result<TrendSeries>> trend(String id, String range);

  /// Deselects — collapses the sheet fully.
  void close();
}

/// A draggable bottom sheet for a station-value layer. Always present as a small
/// peek (with a "tap a station" hint); picking a station on the map pops it up
/// to a comfortable rest height showing the reading and a range-switchable
/// (24h / 7d) trend chart, and deselecting settles it back to the peek.
class StationSheet extends StatelessWidget {
  const StationSheet({super.key, required this.source});

  final StationSheetSource source;

  /// Collapsed peek height, and the height it pops to when a station is picked.
  /// [peekExtent] is public because the map scaffold subtracts the resting sheet
  /// from the map when framing, so the two must agree on one number.
  static const double peekExtent = 0.14;
  static const double _rest = 0.42;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: source.selectionRevision,
      builder: (context, revision, _) => ValueListenableBuilder<String?>(
        valueListenable: source.selection,
        builder: (context, stationId, _) {
          final selected = stationId != null;
          // Bottom-anchored + expand:false so the sheet only overlays its own
          // height and the map above stays tappable — a full-screen overlay
          // swallows the platform view's taps (Flutter #71608).
          //
          // The size is driven by a KEY-SWAP, not controller.animateTo, which is
          // unreliable with expand:false (it closes the sheet instead of
          // stopping at the target — Flutter #121954). The key carries the
          // selection *revision*, so EVERY tap-select (even re-tapping the same
          // station after collapsing it) remounts the sheet at [_rest] and it
          // pops again; with no selection it settles at [peekExtent].
          return Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              key: ValueKey(selected ? 'sel-$revision' : 'peek'),
              expand: false,
              initialChildSize: selected ? _rest : peekExtent,
              minChildSize: peekExtent,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [_rest],
              builder: (context, scrollController) => _SheetSurface(
                child: stationId == null
                    ? _EmptyBody(scrollController: scrollController)
                    : _SheetBody(
                        source: source,
                        stationId: stationId,
                        scrollController: scrollController,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The peek content shown before any station is picked: the grab handle over a
/// short "tap a station" hint.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      controller: scrollController,
      children: [
        const _Grip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.stationSheetEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The sheet's grab handle.
class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The frosted, rounded sheet panel.
class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.topSheet,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: AppRadius.topSheet, child: child),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.source,
    required this.stationId,
    required this.scrollController,
  });

  final StationSheetSource source;
  final String stationId;
  final ScrollController scrollController;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  String _range = '24h';
  int _attempt = 0;
  late Future<Result<TrendSeries>> _future = _load();

  Future<Result<TrendSeries>> _load() =>
      widget.source.trend(widget.stationId, _range);

  @override
  void didUpdateWidget(_SheetBody old) {
    super.didUpdateWidget(old);
    if (old.stationId != widget.stationId) _refetch();
  }

  void _refetch() => setState(() {
    _attempt++;
    _future = _load();
  });

  void _setRange(String range) {
    if (range == _range) return;
    setState(() {
      _range = range;
      _attempt++;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final id = widget.stationId;
    final reading = widget.source.reading(id);
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [
        const _Grip(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The station's own colour from the map ramp: identity travels as a
              // mark, so the reading itself can stay in plain ink.
              if (widget.source.valueColor(id) case final dot?) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: AppSpacing.sm),
                  child: _StationDot(color: dot),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.source.stationName(id),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.source.stationSubtitle(id) case final sub?)
                      Text(
                        sub,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
                visualDensity: VisualDensity.compact,
                onPressed: widget.source.close,
              ),
            ],
          ),
        ),
        // The reading is the one number this sheet exists for, so it leads —
        // large, in ink, with proportional figures (tabular digits make a lone
        // display-size number look gappy).
        if (reading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              reading,
              style: theme.textTheme.displaySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _RangeToggle(range: _range, onChanged: _setRange),
        ),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.lg,
              0,
            ),
            child: FutureBuilder<Result<TrendSeries>>(
              key: ValueKey(_attempt),
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingView();
                return snapshot.data!.when(
                  ok: (series) => _TrendChart(
                    series: series,
                    range: _range,
                    unit: widget.source.unit,
                  ),
                  err: (failure) =>
                      ErrorView(detail: failure.message, onRetry: _refetch),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The station's map colour, ringed in the surface so it stays legible on any
/// backdrop — the same 2px surface ring the chart's end marker uses.
class _StationDot extends StatelessWidget {
  const _StationDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
    );
  }
}

/// A compact two-option range switch.
///
/// Sized to its labels rather than the full width: it is a minor control on a
/// sheet whose subject is the reading and its curve, and a full-bleed pill gave
/// it more visual weight than either.
class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.range, required this.onChanged});

  final String range;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.large,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RangeChip(
              label: l10n.trendRange24h,
              selected: range == '24h',
              onTap: () => onChanged('24h'),
            ),
            _RangeChip(
              label: l10n.trendRange7d,
              selected: range == '7d',
              onTap: () => onChanged('7d'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected ? colors.surface : Colors.transparent,
      borderRadius: AppRadius.large,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// The fl_chart line plot of a [TrendSeries] over [range].
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.series,
    required this.range,
    required this.unit,
  });

  final TrendSeries series;
  final String range;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final spots = <FlSpot>[];
    // Bound by the shorter series — the time axis and each value column are
    // decoded from independent arrays, so a truncated payload could misalign.
    final count = math.min(series.times.length, series.values.length);
    for (var i = 0; i < count; i++) {
      final value = series.values[i];
      if (value != null) spots.add(FlSpot(series.times[i].toDouble(), value));
    }
    if (spots.length < 2) {
      return Center(
        child: Text(
          l10n.trendNoData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final minX = spots.first.x, maxX = spots.last.x;
    var minY = spots.first.y, maxY = spots.first.y;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    // Round the value axis onto a "nice" step and snap the bounds to it, so the
    // ticks land on 30 / 32 / 34 rather than wherever the data happened to stop.
    // Without this the axis read 35, 34, 32 — unequal gaps, which makes the eye
    // misjudge every slope on the curve.
    final yInterval = niceAxisStep((maxY - minY).abs(), 4);
    final headroom = yInterval / 2;
    minY = ((minY - headroom) / yInterval).floorToDouble() * yInterval;
    maxY = ((maxY + headroom) / yInterval).ceilToDouble() * yInterval;
    // ~3 labels along the time axis, and a margin at each end: fl_chart centres
    // a label on its tick, so one landing near a bound gets cropped by the plot
    // edge. Dropping those is better than shipping a half-drawn timestamp.
    final xSpan = (maxX - minX).abs();
    final xInterval = (xSpan / 3).clamp(1.0, double.infinity);
    final xMargin = xSpan * 0.08;

    String timeLabel(double x) {
      final t = DateTime.fromMillisecondsSinceEpoch(
        x.toInt() * 1000,
        isUtc: true,
      ).add(const Duration(hours: 8));
      return DateFormat(range == '7d' ? 'M/d' : 'HH:mm').format(t);
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            // Only the latest point is marked. A dot on every reading is noise;
            // one on the end says "you are here" and anchors the hero value
            // above to the right end of the curve.
            dotData: FlDotData(
              checkToShowDot: (spot, bar) => spot == bar.spots.last,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: colors.primary,
                // A surface ring, not a border: it keeps the marker legible
                // where it sits on the line and the axis.
                strokeColor: colors.surface,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              // A wash, never a saturated block — the line carries the reading.
              color: colors.primary.withValues(alpha: 0.10),
            ),
          ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          // Solid hairlines one step off the surface: a grid is scaffolding, so
          // it should be findable and never compete with the curve. (Dashes
          // would read as a threshold rather than a grid.)
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.outlineVariant.withValues(alpha: 0.5),
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
              // Matches the grid so every line is labelled and vice versa.
              interval: yInterval,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                // fl_chart also emits the axis ends; drawing those would clip
                // against the plot edge.
                if (value <= minY || value >= maxY) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    _axisLabel(value, yInterval),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      // Ticks are a column of numbers, so they align.
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (value <= minX + xMargin || value >= maxX - xMargin) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    timeLabel(value),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // fl_chart's default tooltip background is a fixed dark slate; pair
            // it with the theme's inverse surface so it's legible in both themes.
            getTooltipColor: (_) => colors.inverseSurface,
            getTooltipItems: (touched) => [
              for (final spot in touched)
                LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $unit\n${timeLabel(spot.x)}',
                  theme.textTheme.labelSmall!.copyWith(
                    color: colors.onInverseSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "nice" axis step (1, 2, 5 × a power of ten) that splits [span] into roughly
/// [targetTicks] intervals. Public so the tick maths is unit-testable.
///
/// Axis ticks have to sit on numbers a reader can subtract in their head: with an
/// arbitrary step the gaps between labels are unequal, and the eye reads slope
/// from spacing, so an uneven axis quietly misrepresents the curve.
double niceAxisStep(double span, int targetTicks) {
  if (!span.isFinite || span <= 0) return 1;
  final rough = span / targetTicks;
  final magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  final normalised = rough / magnitude;
  final step = normalised <= 1
      ? 1.0
      : normalised <= 2
      ? 2.0
      : normalised <= 5
      ? 5.0
      : 10.0;
  return step * magnitude;
}

/// An axis value printed with just enough decimals for its [step], so a 0.5 step
/// doesn't collapse to two identical labels.
String _axisLabel(double value, double step) =>
    value.toStringAsFixed(step >= 1 ? 0 : 1);
