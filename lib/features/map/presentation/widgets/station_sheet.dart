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
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A trend series to plot: absolute Unix-second [times] aligned index-wise to
/// [values] (nullable — a gap is skipped in the line).
///
/// [directions] is set only for the wind layer (meteorological ° from which
/// the wind blows); the chart then draws direction ticks on the speed curve.
class TrendSeries {
  const TrendSeries({
    required this.times,
    required this.values,
    this.directions,
  });

  final List<int> times;
  final List<double?> values;

  /// Wind direction (°) per sample, index-aligned to [times], or null when the
  /// layer has no direction channel.
  final List<int?>? directions;
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

  /// Fixed Y-axis floor for the trend chart, or null to auto-fit the series.
  double? get chartMinY;

  /// Fixed Y-axis ceiling for the trend chart, or null to auto-fit the series.
  double? get chartMaxY;

  /// When true, the trend plot is a bar chart (rain accumulation); otherwise a
  /// line (temperature / humidity / …).
  bool get chartBars;

  /// The trend series for [id] over [range] (`24h` | `7d`).
  Future<Result<TrendSeries>> trend(String id, String range);

  /// Programmatically select [id] and bump [selectionRevision] so the sheet
  /// opens (e.g. a ranking-list handoff). No-op when the id is unknown after
  /// data has loaded; callers should wait for the layer's [render] first.
  void select(String id);

  /// Deselects — collapses the sheet fully.
  void close();
}

/// A draggable bottom sheet for a station-value layer.
///
/// Mechanics match [TyphoonPanel]: bottom-aligned, `expand: false` (map above
/// stays tappable), and a key remount to pop/collapse. Trend futures are cached
/// on this State so a remount does not re-hit the network or flash the chart.
///
/// At full height the sheet merges with the status-bar band: the grip hides,
/// top corners flush, and content clears the safe inset while the sheet colour
/// fills behind the system UI — one continuous panel, not a floating card.
class StationSheet extends StatefulWidget {
  const StationSheet({super.key, required this.source});

  final StationSheetSource source;

  /// Collapsed peek height — also used by the map scaffold when framing.
  static const double peekExtent = 0.14;
  static const double _rest = 0.42;
  static const double _expanded = 1.0;
  static const double _atTopEpsilon = 0.02;

  static bool _isAtTop(double extent) => extent >= _expanded - _atTopEpsilon;

  @override
  State<StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<StationSheet> {
  /// `stationId|range` → in-flight / completed trend fetch.
  final Map<String, Future<Result<TrendSeries>>> _trendCache = {};

  /// Live sheet fraction — chrome (grip / flush / status-bar fill) only.
  final ValueNotifier<double> _extent = ValueNotifier(StationSheet.peekExtent);

  /// Last selection we seeded [_extent] for — don't clobber a mid-drag extent
  /// on unrelated rebuilds.
  int? _seededRevision;
  String? _seededStationId;

  Future<Result<TrendSeries>> _trend(String id, String range) {
    final key = '$id|$range';
    return _trendCache.putIfAbsent(key, () => widget.source.trend(id, range));
  }

  void _invalidateTrend(String id, String range) {
    _trendCache.remove('$id|$range');
  }

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: source.selectionRevision,
      builder: (context, revision, _) => ValueListenableBuilder<String?>(
        valueListenable: source.selection,
        builder: (context, stationId, _) {
          final selected = stationId != null;
          final initial = selected
              ? StationSheet._rest
              : StationSheet.peekExtent;
          // Key remount sets initialChildSize (typhoon pattern). Seed chrome
          // to match — DSS only notifies after the first drag.
          if (revision != _seededRevision || stationId != _seededStationId) {
            _seededRevision = revision;
            _seededStationId = stationId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _extent.value = initial;
            });
          }
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _extent.value = notification.extent;
              return false;
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                key: ValueKey(selected ? 'sel-$revision' : 'peek'),
                expand: false,
                initialChildSize: initial,
                minChildSize: StationSheet.peekExtent,
                maxChildSize: StationSheet._expanded,
                snap: true,
                snapSizes: const [StationSheet._rest],
                builder: (context, scrollController) {
                  // Body is the VLB child — extent ticks only restyle chrome.
                  final body = stationId == null
                      ? _EmptyBody(
                          scrollController: scrollController,
                          extent: _extent,
                        )
                      : _SheetBody(
                          source: source,
                          stationId: stationId,
                          scrollController: scrollController,
                          loadTrend: _trend,
                          invalidateTrend: _invalidateTrend,
                          extent: _extent,
                        );
                  return ValueListenableBuilder<double>(
                    valueListenable: _extent,
                    child: body,
                    builder: (context, extent, child) {
                      final atTop = StationSheet._isAtTop(extent);
                      final topInset = MediaQuery.paddingOf(context).top;
                      return AnnotatedRegion<SystemUiOverlayStyle>(
                        value: SystemUiOverlayStyle(
                          statusBarColor: atTop
                              ? colors.surface
                              : Colors.transparent,
                          statusBarIconBrightness:
                              theme.brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark,
                          statusBarBrightness: theme.brightness,
                        ),
                        child: _SheetSurface(
                          flushTop: atTop,
                          // Sheet paints under the status bar; pad content so
                          // titles clear the island. Mid-height: no top gap.
                          child: Padding(
                            padding: EdgeInsets.only(top: atTop ? topInset : 0),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Peek: grab handle + "tap a station" hint.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.scrollController, required this.extent});

  final ScrollController scrollController;
  final ValueListenable<double> extent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      controller: scrollController,
      // Scrollables inherit MediaQuery padding by default — that would shove a
      // status-bar-sized gap above the grip even with no SafeArea wrapper.
      padding: EdgeInsets.zero,
      children: [
        _SheetGrip(extent: extent),
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

/// The sheet's grab handle — hidden once the sheet is flush with the top.
class _SheetGrip extends StatefulWidget {
  const _SheetGrip({required this.extent});

  final ValueListenable<double> extent;

  @override
  State<_SheetGrip> createState() => _SheetGripState();
}

class _SheetGripState extends State<_SheetGrip> {
  late bool _show = !StationSheet._isAtTop(widget.extent.value);

  @override
  void initState() {
    super.initState();
    widget.extent.addListener(_onExtent);
  }

  @override
  void didUpdateWidget(_SheetGrip old) {
    super.didUpdateWidget(old);
    if (old.extent != widget.extent) {
      old.extent.removeListener(_onExtent);
      widget.extent.addListener(_onExtent);
      _onExtent();
    }
  }

  @override
  void dispose() {
    widget.extent.removeListener(_onExtent);
    super.dispose();
  }

  void _onExtent() {
    final next = !StationSheet._isAtTop(widget.extent.value);
    if (next == _show) return;
    // Defer — flipping grip mid-DSS-layout dirties parentData for semantics.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final show = !StationSheet._isAtTop(widget.extent.value);
      if (show != _show) setState(() => _show = show);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
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
  const _SheetSurface({required this.child, this.flushTop = false});

  final Widget child;

  /// Full-bleed under the status bar — drop top radius / shadow so it reads as
  /// one panel with the safe-area band, not a floating card.
  final bool flushTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = flushTop ? BorderRadius.zero : AppRadius.topSheet;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: flushTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.source,
    required this.stationId,
    required this.scrollController,
    required this.loadTrend,
    required this.invalidateTrend,
    required this.extent,
  });

  final StationSheetSource source;
  final String stationId;
  final ScrollController scrollController;
  final Future<Result<TrendSeries>> Function(String id, String range) loadTrend;
  final void Function(String id, String range) invalidateTrend;
  final ValueListenable<double> extent;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  String _range = '24h';
  int _attempt = 0;
  late Future<Result<TrendSeries>> _future = widget.loadTrend(
    widget.stationId,
    _range,
  );

  @override
  void didUpdateWidget(_SheetBody old) {
    super.didUpdateWidget(old);
    if (old.stationId != widget.stationId) _useCached();
  }

  void _useCached() => setState(() {
    _attempt++;
    _future = widget.loadTrend(widget.stationId, _range);
  });

  void _refetch() {
    widget.invalidateTrend(widget.stationId, _range);
    _useCached();
  }

  void _setRange(String range) {
    if (range == _range) return;
    setState(() {
      _range = range;
      _attempt++;
      _future = widget.loadTrend(widget.stationId, _range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.stationId;
    final reading = widget.source.reading(id);
    // ListView (not SliverFillRemaining): FillRemaining + AnimatedSize under a
    // resizing DSS marks parentData dirty mid-semantics flush and asserts in
    // debug. Chart height lerps with extent instead.
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.zero,
      children: [
        _SheetGrip(extent: widget.extent),
        _StationHero(
          extent: widget.extent,
          name: widget.source.stationName(id),
          subtitle: widget.source.stationSubtitle(id),
          reading: reading,
          valueColor: widget.source.valueColor(id),
          onClose: widget.source.close,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: _ChartCard(
            child: _ExtentChartSlot(
              extent: widget.extent,
              child: FutureBuilder<Result<TrendSeries>>(
                key: ValueKey('${id}_$_range$_attempt'),
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LoadingView();
                  return snapshot.data!.when(
                    ok: (series) => _TrendChart(
                      series: series,
                      range: _range,
                      unit: widget.source.unit,
                      accent: widget.source.valueColor(id),
                      fixedMinY: widget.source.chartMinY,
                      fixedMaxY: widget.source.chartMaxY,
                      bars: widget.source.chartBars,
                    ),
                    err: (failure) =>
                        ErrorView(detail: failure.message, onRetry: _refetch),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sizes the trend plot from sheet [extent] — compact at rest, tall when full
/// — without SliverFillRemaining (unsafe under DSS resize).
class _ExtentChartSlot extends StatelessWidget {
  const _ExtentChartSlot({required this.extent, required this.child});

  final ValueListenable<double> extent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    return ValueListenableBuilder<double>(
      valueListenable: extent,
      child: child,
      builder: (context, e, child) {
        final t =
            ((e - StationSheet._rest) /
                    (StationSheet._expanded - StationSheet._rest))
                .clamp(0.0, 1.0);
        // Grow with the sheet, but leave room below — never fill leftover void.
        final compact = (screenH * 0.28).clamp(220.0, 300.0);
        final expanded = (screenH * 0.42).clamp(300.0, 420.0);
        final height = compact + (expanded - compact) * t;
        return SizedBox(height: height, child: child);
      },
    );
  }
}

/// Station name / reading that scale up when the sheet snaps flush — fills the
/// hero band so a full-height sheet doesn't look like a short card on a void.
class _StationHero extends StatefulWidget {
  const _StationHero({
    required this.extent,
    required this.name,
    required this.onClose,
    this.subtitle,
    this.reading,
    this.valueColor,
  });

  final ValueListenable<double> extent;
  final String name;
  final String? subtitle;
  final String? reading;
  final Color? valueColor;
  final VoidCallback onClose;

  @override
  State<_StationHero> createState() => _StationHeroState();
}

class _StationHeroState extends State<_StationHero> {
  late bool _expanded = StationSheet._isAtTop(widget.extent.value);

  @override
  void initState() {
    super.initState();
    widget.extent.addListener(_onExtent);
  }

  @override
  void didUpdateWidget(_StationHero old) {
    super.didUpdateWidget(old);
    if (old.extent != widget.extent) {
      old.extent.removeListener(_onExtent);
      widget.extent.addListener(_onExtent);
      _onExtent();
    }
  }

  @override
  void dispose() {
    widget.extent.removeListener(_onExtent);
    super.dispose();
  }

  void _onExtent() {
    final next = StationSheet._isAtTop(widget.extent.value);
    if (next == _expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final expanded = StationSheet._isAtTop(widget.extent.value);
      if (expanded != _expanded) setState(() => _expanded = expanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final nameStyle = _expanded
        ? theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final subStyle =
        (_expanded ? theme.textTheme.bodyMedium : theme.textTheme.bodySmall)
            ?.copyWith(color: colors.onSurfaceVariant);
    final readingStyle = _expanded
        ? theme.textTheme.displayMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
            height: 1,
          )
        : theme.textTheme.displaySmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
            height: 1,
          );
    final dotSize = _expanded ? 14.0 : 10.0;

    // No AnimatedSize here — it + DSS resize trips semantics.parentDataDirty.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        _expanded ? AppSpacing.md : 0,
        AppSpacing.sm,
        _expanded ? AppSpacing.md : AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.valueColor case final dot?) ...[
                Padding(
                  padding: EdgeInsets.only(
                    top: _expanded ? 8 : 5,
                    right: AppSpacing.sm,
                  ),
                  child: AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: Curves.easeOutCubic,
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: AppMotion.medium,
                      curve: Curves.easeOutCubic,
                      style: nameStyle ?? const TextStyle(),
                      child: Text(widget.name),
                    ),
                    if (widget.subtitle case final sub?)
                      AnimatedDefaultTextStyle(
                        duration: AppMotion.medium,
                        curve: Curves.easeOutCubic,
                        style: subStyle ?? const TextStyle(),
                        child: Text(sub),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
                visualDensity: VisualDensity.compact,
                onPressed: widget.onClose,
              ),
            ],
          ),
          if (widget.reading case final reading?) ...[
            SizedBox(height: _expanded ? AppSpacing.md : AppSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              style: readingStyle ?? const TextStyle(),
              child: Text(reading),
            ),
          ],
        ],
      ),
    );
  }
}

/// Soft inset panel that frames the trend plot so the curve reads as a card
/// content block rather than floating on the sheet.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: child,
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

/// The fl_chart plot of a [TrendSeries] over [range].
///
/// Default is a curved line. Rain uses [bars]. Wind series keep direction
/// **off** the curve: each bottom-axis tick is `arrow` over `time` (X-axis →
/// direction → clock), matching the map's blow-toward convention. Tooltip still
/// carries the exact ° reading.
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.series,
    required this.range,
    required this.unit,
    this.accent,
    this.fixedMinY,
    this.fixedMaxY,
    this.bars = false,
  });

  final TrendSeries series;
  final String range;
  final String unit;

  /// Station's map colour — tints the curve / bars so the sheet matches the
  /// tapped dot.
  final Color? accent;

  /// When set, pins the Y axis (humidity 0–100, wind/rain floor 0, …).
  final double? fixedMinY;
  final double? fixedMaxY;

  /// Rainfall uses bars; everything else uses a line.
  final bool bars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lineColor = accent ?? colors.primary;
    final isWind = series.directions != null;

    final spots = <FlSpot>[];
    // Spot index → sample index into times/values/directions (gaps skipped).
    final sampleAt = <int>[];
    final count = math.min(series.times.length, series.values.length);
    for (var i = 0; i < count; i++) {
      final value = series.values[i];
      if (value == null) continue;
      sampleAt.add(i);
      spots.add(FlSpot(series.times[i].toDouble(), value));
    }
    if (spots.isEmpty || (!bars && spots.length < 2)) {
      return Center(
        child: Text(
          l10n.trendNoData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    // Hourly feed → snap labels onto a clock-friendly step (1/2/3/4/6… h).
    // Compact "{hour}時" ticks fit denser than "HH:00"; wind arrows need a
    // little more room. Grid stays finer than labels when the step is small.
    const hourSec = 3600.0;
    final spanSec = (spots.last.x - spots.first.x).abs();
    final labelStep = niceTimeLabelStepSec(
      spanSec,
      targetTicks: range == '7d' ? 8 : (isWind ? 8 : 12),
    );
    final gridStep = labelStep <= 4 * hourSec ? hourSec : labelStep / 2;
    // Domain = first→last sample so the curve spans the plot (no empty gutters
    // from snapping minX/maxX out past the data onto clock labels).
    final minX = spots.first.x;
    final maxX = spots.last.x == minX ? minX + labelStep : spots.last.x;
    // Label grid still snaps to clock hours; anchor independently of minX.
    final labelAnchor = _floorToStep(spots.first.x, labelStep);

    var dataMinY = spots.first.y, dataMaxY = spots.first.y;
    for (final s in spots) {
      if (s.y < dataMinY) dataMinY = s.y;
      if (s.y > dataMaxY) dataMaxY = s.y;
    }
    // Round the value axis onto a "nice" step and snap the bounds to it, so the
    // ticks land on 30 / 32 / 34 rather than wherever the data happened to stop.
    final axisLo = fixedMinY ?? dataMinY;
    final axisHi = fixedMaxY ?? dataMaxY;
    final yInterval = niceAxisStep((axisHi - axisLo).abs(), 8);
    final headroom = yInterval / 2;
    final minY =
        fixedMinY ??
        ((dataMinY - headroom) / yInterval).floorToDouble() * yInterval;
    var maxY =
        fixedMaxY ??
        ((dataMaxY + headroom) / yInterval).ceilToDouble() * yInterval;
    if (maxY <= minY) maxY = minY + yInterval;

    String timeLabel(double x) {
      final t = DateTime.fromMillisecondsSinceEpoch(
        x.toInt() * 1000,
        isUtc: true,
      ).add(const Duration(hours: 8));
      final hourMark = l10n.chartHourLabel(t.hour);
      // Daily-or-wider: date only. Sub-daily 7d: date + hour. 24h: compact hour.
      if (labelStep >= 24 * hourSec) return DateFormat('M/d').format(t);
      if (range == '7d') {
        return t.hour == 0
            ? DateFormat('M/d').format(t)
            : '${DateFormat('M/d').format(t)} $hourMark';
      }
      return hourMark;
    }

    bool onLabelStep(double value) => _isOnStep(value, labelAnchor, labelStep);

    int? directionForSpot(int spotIndex) {
      final directions = series.directions;
      if (directions == null || spotIndex < 0 || spotIndex >= sampleAt.length) {
        return null;
      }
      final sample = sampleAt[spotIndex];
      if (sample >= directions.length) return null;
      return directions[sample];
    }

    /// Nearest sample's meteorological "from" at chart-x [x] (for axis ticks).
    int? directionNear(double x) {
      final directions = series.directions;
      if (directions == null || spots.isEmpty) return null;
      var best = 0;
      var bestDist = (spots.first.x - x).abs();
      for (var i = 1; i < spots.length; i++) {
        final d = (spots[i].x - x).abs();
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }
      return directionForSpot(best);
    }

    // Bottom axis: wind needs a second row for arrows above the clock labels.
    final bottomReserved = isWind ? 40.0 : 22.0;

    FlTitlesData titles({
      required double titleMinX,
      required double titleMaxX,
      required double? Function(double value) labelX,
      double? bottomInterval,
    }) => FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: yInterval,
          // Wide enough for "1007.5" without soft-wrapping mid-number.
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            if (value <= minY || value >= maxY) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(
                _axisLabel(value, yInterval),
                textAlign: TextAlign.right,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
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
          reservedSize: bottomReserved,
          interval: bottomInterval ?? labelStep,
          getTitlesWidget: (value, meta) {
            final x = labelX(value);
            if (x == null ||
                x < titleMinX - 1 ||
                x > titleMaxX + 1 ||
                !onLabelStep(x)) {
              return const SizedBox.shrink();
            }
            final time = Text(
              timeLabel(x),
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
            // fl_chart sizes each title to the tick slot; without
            // UnconstrainedBox, "20時" wraps to 20 / 時.
            if (!isWind) {
              return SideTitleWidget(
                meta: meta,
                space: AppSpacing.xs,
                child: UnconstrainedBox(child: time),
              );
            }
            final from = directionNear(x);
            return SideTitleWidget(
              meta: meta,
              space: 2,
              child: UnconstrainedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (from != null)
                      Transform.rotate(
                        angle: (from + 180) * math.pi / 180,
                        child: Icon(
                          Icons.navigation,
                          size: 12,
                          color: lineColor,
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                    const SizedBox(height: 2),
                    time,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (bars) {
      // Index-domain bars — dense 10-min rain series stays readable as thin rods.
      final barWidth = spots.length > 100
          ? 1.5
          : spots.length > 48
          ? 2.5
          : spots.length > 24
          ? 4.0
          : 6.0;
      final groups = [
        for (var i = 0; i < spots.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spots[i].y,
                width: barWidth,
                color: lineColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ],
          ),
      ];
      return BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: 0,
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
          titlesData: titles(
            titleMinX: minX,
            titleMaxX: maxX,
            bottomInterval: 1,
            labelX: (value) {
              final i = value.round();
              if (i < 0 || i >= spots.length) return null;
              return spots[i].x;
            },
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceContainerHigh,
              tooltipBorderRadius: AppRadius.small,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              tooltipMargin: AppSpacing.sm,
              maxContentWidth: 168,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final i = group.x;
                final x = (i >= 0 && i < spots.length) ? spots[i].x : 0.0;
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} $unit',
                  theme.textTheme.titleSmall!.copyWith(
                    color: lineColor,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.start,
                  children: [
                    TextSpan(
                      text: '\n${timeLabel(x)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        duration: Duration.zero,
      );
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
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            shadow: Shadow(
              color: lineColor.withValues(alpha: 0.28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            // End marker only — wind direction lives on the bottom axis.
            dotData: FlDotData(
              checkToShowDot: (spot, bar) => spot == bar.spots.last,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4.5,
                color: lineColor,
                strokeColor: colors.surface,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.22),
                  lineColor.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          drawVerticalLine: true,
          // Hourly grid (data cadence); labels may be every N hours.
          verticalInterval: gridStep,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) {
            // Emphasise labelled hours so the fine grid doesn't compete.
            final labelled = onLabelStep(value);
            return FlLine(
              color: colors.outlineVariant.withValues(
                alpha: labelled ? 0.35 : 0.14,
              ),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          titleMinX: minX,
          titleMaxX: maxX,
          labelX: (value) => value,
        ),
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indices) => [
            for (final _ in indices)
              TouchedSpotIndicatorData(
                FlLine(
                  color: lineColor.withValues(alpha: 0.35),
                  strokeWidth: 1,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: lineColor,
                        strokeColor: colors.surface,
                        strokeWidth: 2,
                      ),
                ),
              ),
          ],
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.surfaceContainerHigh,
            tooltipBorderRadius: AppRadius.small,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            tooltipMargin: AppSpacing.sm,
            maxContentWidth: 168,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorder: BorderSide(
              color: lineColor.withValues(alpha: 0.55),
              width: 1,
            ),
            getTooltipItems: (touched) => [
              for (final spot in touched)
                _tooltipItem(
                  spot: spot,
                  unit: unit,
                  time: timeLabel(spot.x),
                  direction: directionForSpot(spot.spotIndex),
                  colors: colors,
                  textTheme: theme.textTheme,
                  accent: lineColor,
                ),
            ],
          ),
        ),
      ),
      // No tween on rebuild — a mid-drag remount used to re-animate the curve
      // and read as pull-to-refresh. Data swaps still replace spots instantly.
      duration: Duration.zero,
    );
  }
}

/// Chart touch tooltip: value emphasized, meta (direction / time) muted.
LineTooltipItem _tooltipItem({
  required FlSpot spot,
  required String unit,
  required String time,
  required int? direction,
  required ColorScheme colors,
  required TextTheme textTheme,
  required Color accent,
}) {
  final valueStyle = textTheme.titleSmall!.copyWith(
    color: accent,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );
  final metaStyle = textTheme.labelSmall!.copyWith(
    color: colors.onSurfaceVariant,
    height: 1.4,
  );
  return LineTooltipItem(
    '${spot.y.toStringAsFixed(1)} $unit',
    valueStyle,
    textAlign: TextAlign.start,
    children: [
      if (direction != null)
        TextSpan(
          text: '\n${_compassLabel(direction)} · $direction°',
          style: metaStyle,
        ),
      TextSpan(text: '\n$time', style: metaStyle),
    ],
  );
}

/// 8-point compass label for a meteorological "from" bearing.
String _compassLabel(int fromDegrees) {
  const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return labels[((fromDegrees % 360) / 45).round() % 8];
}

/// Floors [x] onto a multiple of [step] (Unix-second axis helpers).
double _floorToStep(double x, double step) => (x / step).floorToDouble() * step;

/// Whether [value] sits on `origin + n·step` within 1 s (float-safe).
bool _isOnStep(double value, double origin, double step) {
  final n = ((value - origin) / step).round();
  return (value - (origin + n * step)).abs() < 1;
}

/// Clock-friendly hour steps (divide a day cleanly, then multi-day).
const _niceTimeHours = [1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 24.0, 48.0, 72.0];

/// A label interval in **seconds** for a time axis spanning [spanSec], aiming
/// for about [targetTicks] labels. Picks the smallest hour step in
/// [_niceTimeHours] that is ≥ the rough spacing — so a 24 h series with
/// target 12 lands on 2 h ticks, not every hour.
double niceTimeLabelStepSec(double spanSec, {int targetTicks = 12}) {
  if (!spanSec.isFinite || spanSec <= 0) return 3600;
  final roughHours = (spanSec / 3600) / math.max(targetTicks, 1);
  for (final hours in _niceTimeHours) {
    if (hours >= roughHours) return hours * 3600;
  }
  return _niceTimeHours.last * 3600;
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

/// An axis value printed with just enough decimals for its [step], so a 0.5
/// step doesn't collapse to two identical labels. Trailing `.0` is dropped so
/// "1007.0" stays "1007" and fits the left gutter.
String _axisLabel(double value, double step) {
  if (step >= 1) return value.toStringAsFixed(0);
  final label = value.toStringAsFixed(1);
  return label.endsWith('.0') ? label.substring(0, label.length - 2) : label;
}
