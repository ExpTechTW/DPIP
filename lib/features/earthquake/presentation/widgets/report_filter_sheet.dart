/// Bottom sheet to edit a [ReportListQuery] for the earthquake report list.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Opens the filter sheet and returns the applied query, or `null` if dismissed
/// without applying.
Future<ReportListQuery?> showReportFilterSheet(
  BuildContext context, {
  required ReportListQuery initial,
}) {
  return showModalBottomSheet<ReportListQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 1,
      builder: (context, scrollController) => _ReportFilterSheet(
        initial: initial,
        scrollController: scrollController,
      ),
    ),
  );
}

const double _magMin = 0;
const double _magMax = 8;
const double _depthFloor = 0;
const double _depthCeil = 150; // top of slider = no max-depth filter
const double _intensityMin = 1;
const double _intensityMax = 9;

class _ReportFilterSheet extends StatefulWidget {
  const _ReportFilterSheet({
    required this.initial,
    required this.scrollController,
  });

  final ReportListQuery initial;
  final ScrollController scrollController;

  @override
  State<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<_ReportFilterSheet> {
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

  static DateTimeRange? _datesFromQuery(ReportListQuery q) {
    final start = q.startTime;
    final end = q.endTime;
    if (start == null || end == null) return null;
    final s = DateTime.tryParse(start);
    final e = DateTime.tryParse(end);
    if (s == null || e == null) return null;
    return DateTimeRange(start: s, end: e);
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

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange:
          _dates ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
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
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
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
                        style: theme.textTheme.titleLarge?.copyWith(
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
                            Intensity.label(_intensity.start.round()),
                            Intensity.label(_intensity.end.round()),
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
                        Intensity.label(_intensity.start.round()),
                        Intensity.label(_intensity.end.round()),
                      ),
                      onChanged: (v) => setState(() => _intensity = v),
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
                      onChanged: (v) => setState(() => _magnitude = v),
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
                                    _depth.end.toStringAsFixed(0),
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
                      onChanged: (v) => setState(() => _depth = v),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDates,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                _dates == null
                                    ? l10n.reportFilterDatePick
                                    : l10n.reportFilterRange(
                                        dateFmt.format(_dates!.start),
                                        dateFmt.format(_dates!.end),
                                      ),
                              ),
                            ),
                          ),
                          if (_dates != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            IconButton.filledTonal(
                              tooltip: l10n.reportFilterReset,
                              onPressed: () => setState(() => _dates = null),
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.reportFilterDateStartNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.reportFilterDateEndNote,
                        style: theme.textTheme.bodySmall?.copyWith(
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
              ),
              onPressed: () => Navigator.pop(context, _build()),
              child: Text(l10n.reportFilterApply),
            ),
          ),
        ],
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
