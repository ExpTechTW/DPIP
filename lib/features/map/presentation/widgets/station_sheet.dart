/// The collapsible detail sheet for a station-value map layer: the tapped
/// station's current reading and its 24h / 7d trend chart.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_motion.dart';
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

  /// The station's display name for [id].
  String stationName(String id);

  /// A subtitle (county · town) for [id], or null.
  String? stationSubtitle(String id);

  /// The current reading text for [id] (e.g. "27.8°C"), or null if unknown.
  String? reading(String id);

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
class StationSheet extends StatefulWidget {
  const StationSheet({super.key, required this.source});

  final StationSheetSource source;

  @override
  State<StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<StationSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  /// Collapsed peek height — the sheet never goes below this, so the hint (and
  /// grab handle) always show. A tap pops it up to [_rest].
  static const double _peek = 0.14;
  static const double _rest = 0.42;

  @override
  void initState() {
    super.initState();
    widget.source.selection.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.source.selection.removeListener(_onSelectionChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Pop up to [_rest] when a station is picked; settle back to [_peek] when it
  /// is deselected. Driven explicitly so the height is reliable regardless of
  /// where the sheet was last dragged.
  void _onSelectionChanged() {
    if (!_controller.isAttached) return;
    final target = widget.source.selection.value == null ? _peek : _rest;
    if ((_controller.size - target).abs() < 0.005) return;
    _controller.animateTo(
      target,
      duration: AppMotion.medium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _peek,
      minChildSize: _peek,
      maxChildSize: 0.85,
      snap: true,
      // Keep the rest height a real snap detent, so a drag settles there and not
      // only at the peek / full extremes.
      snapSizes: const [_rest],
      builder: (context, scrollController) => _SheetSurface(
        child: ValueListenableBuilder<String?>(
          valueListenable: widget.source.selection,
          builder: (context, stationId, _) => stationId == null
              ? _EmptyBody(scrollController: scrollController)
              : _SheetBody(
                  source: widget.source,
                  stationId: stationId,
                  scrollController: scrollController,
                ),
        ),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.source.stationName(id),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              if (reading != null)
                Text(
                  reading,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
                onPressed: widget.source.close,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: '24h', label: Text(l10n.trendRange24h)),
              ButtonSegment(value: '7d', label: Text(l10n.trendRange7d)),
            ],
            selected: {_range},
            onSelectionChanged: (s) => _setRange(s.first),
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
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
      ],
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
    final pad = ((maxY - minY).abs() * 0.15).clamp(1.0, double.infinity);
    minY -= pad;
    maxY += pad;
    // ~4 labels along the time axis.
    final xInterval = ((maxX - minX) / 4).clamp(1.0, double.infinity);

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
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.outlineVariant, strokeWidth: 0.5),
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
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (value <= minX || value >= maxX) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    timeLabel(value),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
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
