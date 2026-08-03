/// Bottom sheet to edit a [ReportListQuery] for the earthquake report list.
///
/// Top chrome matches map 拖盤 ([StationSheet] / [TyphoonPanel]): mid-height has
/// a rounded top + grip and no status-bar gap; flush at `1.0` drops radius,
/// hides the grip, and pads content under the status bar.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Result of closing the filter sheet. [query] is always the latest edits so
/// draft survives a dismiss; [search] is true only when the user tapped 查詢.
final class ReportFilterSheetResult {
  const ReportFilterSheetResult({required this.query, required this.search});

  final ReportListQuery query;
  final bool search;
}

/// Opens the filter sheet. Edits are always returned (dismiss or search) so the
/// list page can keep [ReportListQuery] draft until it is popped. Only
/// [ReportFilterSheetResult.search] should trigger a network fetch.
Future<ReportFilterSheetResult?> showReportFilterSheet(
  BuildContext context, {
  required ReportListQuery initial,
}) {
  // Scaffold zeros MediaQuery padding/viewPadding under the AppBar; the modal
  // route does too. Read the FlutterView directly so status-bar inset is real
  // (map 拖盤 never hit this — they sit outside a modal + use page MediaQuery
  // that still has top padding via the shell).
  final systemPadding = MediaQueryData.fromView(View.of(context)).padding;
  return showModalBottomSheet<ReportFilterSheetResult>(
    context: context,
    // Root navigator — shell uses extendBody, so a branch-sheet sits *under*
    // the bottom nav and the action button vanishes behind it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _ReportFilterSheet(initial: initial, systemPadding: systemPadding),
  );
}

const double _restExtent = 0.72;
const double _minExtent = 0.45;
const double _maxExtent = 1.0;
const double _atTopEpsilon = 0.02;

bool _isAtTop(double extent) => extent >= _maxExtent - _atTopEpsilon;

const double _magMin = 0;
const double _magMax = 8;
const double _depthFloor = 0;
const double _depthCeil = 150; // top of slider = no max-depth filter
const double _intensityMin = 1;
const double _intensityMax = 9;

class _ReportFilterSheet extends StatefulWidget {
  const _ReportFilterSheet({
    required this.initial,
    required this.systemPadding,
  });

  final ReportListQuery initial;

  /// Raw system insets from the page that opened the sheet (not the modal).
  final EdgeInsets systemPadding;

  @override
  State<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<_ReportFilterSheet> {
  final ValueNotifier<double> _extent = ValueNotifier(_restExtent);

  late RangeValues _intensity = RangeValues(
    (widget.initial.minIntensity ?? _intensityMin.toInt())
        .clamp(_intensityMin.toInt(), _intensityMax.toInt())
        .toDouble(),
    (widget.initial.maxIntensity ?? _intensityMax.toInt())
        .clamp(_intensityMin.toInt(), _intensityMax.toInt())
        .toDouble(),
  );
  late RangeValues _magnitude = RangeValues(
    widget.initial.minMagnitude ?? _magMin,
    widget.initial.maxMagnitude ?? _magMax,
  );
  late RangeValues _depth = RangeValues(
    widget.initial.minDepth ?? _depthFloor,
    () {
      final d = widget.initial.maxDepth;
      if (d == null || d >= _depthCeil) return _depthCeil;
      return d.clamp(_depthFloor, _depthCeil);
    }(),
  );
  late DateTimeRange? _dates = _datesFromQuery(widget.initial);

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  static DateTimeRange? _datesFromQuery(ReportListQuery q) {
    final start = q.startTime;
    final end = q.endTime;
    if (start == null || end == null) return null;
    final s = _parseYmd(start);
    final e = _parseYmd(end);
    if (s == null || e == null) return null;
    return DateTimeRange(start: s, end: e);
  }

  /// Local calendar day — `DateTime.tryParse('YYYY-MM-DD')` is UTC and can
  /// shift the day in non-Taipei zones / confuse the range picker restore.
  static DateTime? _parseYmd(String ymd) {
    final parts = ymd.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  bool get _intensityFull =>
      _intensity.start <= _intensityMin && _intensity.end >= _intensityMax;
  bool get _magnitudeFull =>
      _magnitude.start <= _magMin && _magnitude.end >= _magMax;
  bool get _depthFull =>
      _depth.start <= _depthFloor && _depth.end >= _depthCeil;

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  ReportListQuery _build() {
    final dates = _dates;
    return ReportListQuery(
      minIntensity: _intensityFull ? null : _intensity.start.round(),
      maxIntensity: _intensityFull ? null : _intensity.end.round(),
      minMagnitude: _magnitudeFull ? null : _magnitude.start,
      maxMagnitude: _magnitudeFull ? null : _magnitude.end,
      minDepth: _depthFull || _depth.start <= _depthFloor ? null : _depth.start,
      maxDepth: _depthFull || _depth.end >= _depthCeil ? null : _depth.end,
      startTime: dates == null ? null : _ymd(dates.start),
      endTime: dates == null ? null : _ymd(dates.end),
    );
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _intensity = const RangeValues(_intensityMin, _intensityMax);
      _magnitude = const RangeValues(_magMin, _magMax);
      _depth = const RangeValues(_depthFloor, _depthCeil);
      _dates = null;
    });
  }

  static final DateTime _earliestDate = DateTime(1995, 1, 1);

  /// Taipei calendar "today" from [AppTime.utc8] (fields are UTC+8 wall time).
  static DateTime get _taipeiToday {
    final t = AppTime.utc8;
    return DateTime(t.year, t.month, t.day);
  }

  Future<void> _pickDates() async {
    final today = _taipeiToday;
    final earliest = _earliestDate;
    final existing = _dates;
    // Clamp a remembered range into the legal window (clock / policy drift).
    DateTimeRange initialRange;
    if (existing != null) {
      var start = existing.start.isBefore(earliest) ? earliest : existing.start;
      var end = existing.end.isAfter(today) ? today : existing.end;
      if (start.isAfter(end)) start = end;
      initialRange = DateTimeRange(start: start, end: end);
    } else {
      final start = today.subtract(const Duration(days: 30));
      initialRange = DateTimeRange(
        start: start.isBefore(earliest) ? earliest : start,
        end: today,
      );
    }
    final picked = await showDateRangePicker(
      context: context,
      locale: Localizations.localeOf(context),
      firstDate: earliest,
      lastDate: today,
      initialDateRange: initialRange,
      helpText: AppLocalizations.of(context).reportFilterDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _dates = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);
    final dateFmt = DateFormat('yyyy/MM/dd');
    final height = media.size.height;

    return SizedBox(
      height: height,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Barrier / drag / back — keep edits in draft, don't search.
          Navigator.pop(
            context,
            ReportFilterSheetResult(query: _build(), search: false),
          );
        },
        child: NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            _extent.value = notification.extent;
            return false;
          },
          child: DraggableScrollableSheet(
            expand: true,
            initialChildSize: _restExtent,
            minChildSize: _minExtent,
            maxChildSize: _maxExtent,
            snap: true,
            snapSizes: const [_restExtent],
            builder: (context, scrollController) {
              return ValueListenableBuilder<double>(
                valueListenable: _extent,
                builder: (context, extent, _) {
                  final atTop = _isAtTop(extent);
                  final viewInsets = MediaQuery.viewInsetsOf(context);
                  final topInset = widget.systemPadding.top;
                  final bottomInset = widget.systemPadding.bottom;
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
                      // Sheet paints under the status bar; pad content only when
                      // flush so mid-height has no top gap (same as StationSheet).
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: atTop ? topInset : 0,
                          bottom: viewInsets.bottom,
                        ),
                        child: Column(
                          children: [
                            _SheetGrip(extent: _extent),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                // Scrollables inherit MediaQuery padding by
                                // default — that would shove a status-bar gap
                                // above the grip even mid-height.
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.sm,
                                  AppSpacing.lg,
                                  AppSpacing.md,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tune, color: colors.primary),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          l10n.reportFilterTitle,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _reset,
                                        child: Text(l10n.reportFilterReset),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _SectionCard(
                                    icon: Icons.vibration,
                                    title: l10n.reportFilterIntensity,
                                    trailing: _ValuePill(
                                      label: _intensityFull
                                          ? l10n.reportFilterAny
                                          : l10n.reportFilterRange(
                                              Intensity.label(
                                                _intensity.start.round(),
                                              ),
                                              Intensity.label(
                                                _intensity.end.round(),
                                              ),
                                            ),
                                    ),
                                    child: SliderTheme(
                                      data: _sliderTheme(context),
                                      child: RangeSlider(
                                        values: _intensity,
                                        min: _intensityMin,
                                        max: _intensityMax,
                                        divisions: 8,
                                        labels: RangeLabels(
                                          Intensity.label(
                                            _intensity.start.round(),
                                          ),
                                          Intensity.label(
                                            _intensity.end.round(),
                                          ),
                                        ),
                                        onChanged: (v) =>
                                            setState(() => _intensity = v),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _SectionCard(
                                    icon: Icons.speed_outlined,
                                    title: l10n.reportFilterMagnitude,
                                    trailing: _ValuePill(
                                      label: _magnitudeFull
                                          ? l10n.reportFilterAny
                                          : l10n.reportFilterRange(
                                              'M${_magnitude.start.toStringAsFixed(1)}',
                                              'M${_magnitude.end.toStringAsFixed(1)}',
                                            ),
                                    ),
                                    child: SliderTheme(
                                      data: _sliderTheme(context),
                                      child: RangeSlider(
                                        values: _magnitude,
                                        min: _magMin,
                                        max: _magMax,
                                        divisions: 16,
                                        labels: RangeLabels(
                                          'M${_magnitude.start.toStringAsFixed(1)}',
                                          'M${_magnitude.end.toStringAsFixed(1)}',
                                        ),
                                        onChanged: (v) =>
                                            setState(() => _magnitude = v),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _SectionCard(
                                    icon: Icons.vertical_align_bottom_outlined,
                                    title: l10n.reportFilterDepth,
                                    trailing: _ValuePill(
                                      label: _depthFull
                                          ? l10n.reportFilterAny
                                          : l10n.reportFilterRange(
                                              l10n.reportFilterDepthKm(
                                                _depth.start.toStringAsFixed(0),
                                              ),
                                              _depth.end >= _depthCeil
                                                  ? l10n.reportFilterAny
                                                  : l10n.reportFilterDepthKm(
                                                      _depth.end
                                                          .toStringAsFixed(0),
                                                    ),
                                            ),
                                    ),
                                    child: SliderTheme(
                                      data: _sliderTheme(context),
                                      child: RangeSlider(
                                        values: _depth,
                                        min: _depthFloor,
                                        max: _depthCeil,
                                        divisions: 30,
                                        labels: RangeLabels(
                                          l10n.reportFilterDepthKm(
                                            _depth.start.toStringAsFixed(0),
                                          ),
                                          _depth.end >= _depthCeil
                                              ? l10n.reportFilterAny
                                              : l10n.reportFilterDepthKm(
                                                  _depth.end.toStringAsFixed(0),
                                                ),
                                        ),
                                        onChanged: (v) =>
                                            setState(() => _depth = v),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _SectionCard(
                                    icon: Icons.date_range_outlined,
                                    title: l10n.reportFilterDate,
                                    trailing: _ValuePill(
                                      label: _dates == null
                                          ? l10n.reportFilterAny
                                          : l10n.reportFilterRange(
                                              dateFmt.format(_dates!.start),
                                              dateFmt.format(_dates!.end),
                                            ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _pickDates,
                                                icon: const Icon(
                                                  Icons.calendar_month_outlined,
                                                ),
                                                label: Text(
                                                  _dates == null
                                                      ? l10n.reportFilterDatePick
                                                      : l10n.reportFilterRange(
                                                          dateFmt.format(
                                                            _dates!.start,
                                                          ),
                                                          dateFmt.format(
                                                            _dates!.end,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            if (_dates != null) ...[
                                              const SizedBox(
                                                width: AppSpacing.sm,
                                              ),
                                              IconButton.filledTonal(
                                                tooltip: l10n.reportFilterReset,
                                                onPressed: () => setState(
                                                  () => _dates = null,
                                                ),
                                                icon: const Icon(Icons.clear),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          l10n.reportFilterDateStartNote,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          l10n.reportFilterDateEndNote,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                AppSpacing.lg + bottomInset,
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.medium,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(
                                  context,
                                  ReportFilterSheetResult(
                                    query: _build(),
                                    search: true,
                                  ),
                                ),
                                child: Text(l10n.reportFilterApply),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SliderTheme.of(context).copyWith(
      trackHeight: 4,
      activeTrackColor: colors.primary,
      inactiveTrackColor: colors.surfaceContainerHighest,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colors.primary,
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
      showValueIndicator: ShowValueIndicator.onlyForContinuous,
    );
  }
}

/// Rounded panel mid-height; flush (no radius / shadow) when at the top.
class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child, this.flushTop = false});

  final Widget child;
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

/// Grab handle — hidden once the sheet is flush with the top.
class _SheetGrip extends StatefulWidget {
  const _SheetGrip({required this.extent});

  final ValueListenable<double> extent;

  @override
  State<_SheetGrip> createState() => _SheetGripState();
}

class _SheetGripState extends State<_SheetGrip> {
  late bool _show = !_isAtTop(widget.extent.value);

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
    final next = !_isAtTop(widget.extent.value);
    if (next == _show) return;
    // Defer — flipping grip mid-DSS-layout dirties parentData for semantics.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final show = !_isAtTop(widget.extent.value);
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
