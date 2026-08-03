/// Bottom sheet to edit a [ReportListQuery] for the earthquake report list.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    builder: (context) => _ReportFilterSheet(initial: initial),
  );
}

/// Slider top = unlimited. Below that is a real km cap.
const double _depthUnlimited = 150;
const double _depthMin = 10;

class _ReportFilterSheet extends StatefulWidget {
  const _ReportFilterSheet({required this.initial});

  final ReportListQuery initial;

  @override
  State<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends State<_ReportFilterSheet> {
  late int? _minIntensity = widget.initial.minIntensity;
  late double _minMagnitude = widget.initial.minMagnitude ?? 0;

  /// [_depthUnlimited] means no max-depth filter.
  late double _maxDepth = () {
    final d = widget.initial.maxDepth;
    if (d == null || d >= _depthUnlimited) return _depthUnlimited;
    return d.clamp(_depthMin, _depthUnlimited);
  }();
  late final TextEditingController _loc = TextEditingController(
    text: widget.initial.loc ?? '',
  );

  bool get _depthUnlimitedSelected => _maxDepth >= _depthUnlimited;

  @override
  void dispose() {
    _loc.dispose();
    super.dispose();
  }

  ReportListQuery _build() {
    final loc = _loc.text.trim();
    return ReportListQuery(
      minIntensity: _minIntensity,
      minMagnitude: _minMagnitude > 0 ? _minMagnitude : null,
      maxDepth: _depthUnlimitedSelected ? null : _maxDepth,
      loc: loc.isEmpty ? null : loc,
    );
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _minIntensity = null;
      _minMagnitude = 0;
      _maxDepth = _depthUnlimited;
      _loc.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    title: l10n.reportFilterMinIntensity,
                    trailing: _ValuePill(
                      label: _minIntensity == null
                          ? l10n.reportFilterAny
                          : Intensity.label(_minIntensity!),
                      color: _minIntensity == null
                          ? null
                          : IntensityColors.discrete(_minIntensity!),
                    ),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _IntensityChip(
                          label: l10n.reportFilterAny,
                          selected: _minIntensity == null,
                          onTap: () => setState(() => _minIntensity = null),
                        ),
                        for (var i = 1; i <= 9; i++)
                          _IntensityChip(
                            label: Intensity.label(i),
                            color: IntensityColors.discrete(i),
                            selected: _minIntensity == i,
                            onTap: () => setState(() => _minIntensity = i),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.speed_outlined,
                    title: l10n.reportFilterMinMagnitude,
                    trailing: _ValuePill(
                      label: _minMagnitude <= 0
                          ? l10n.reportFilterAny
                          : 'M${_minMagnitude.toStringAsFixed(1)}',
                    ),
                    child: SliderTheme(
                      data: _sliderTheme(context),
                      child: Slider(
                        value: _minMagnitude,
                        min: 0,
                        max: 7,
                        divisions: 14,
                        label: _minMagnitude <= 0
                            ? l10n.reportFilterAny
                            : 'M${_minMagnitude.toStringAsFixed(1)}',
                        onChanged: (v) => setState(() => _minMagnitude = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.vertical_align_bottom_outlined,
                    title: l10n.reportFilterMaxDepth,
                    trailing: _ValuePill(
                      label: _depthUnlimitedSelected
                          ? l10n.reportFilterAny
                          : l10n.reportFilterDepthKm(
                              _maxDepth.toStringAsFixed(0),
                            ),
                    ),
                    child: SliderTheme(
                      data: _sliderTheme(context),
                      child: Slider(
                        value: _maxDepth,
                        min: _depthMin,
                        max: _depthUnlimited,
                        divisions: 28, // 5 km steps (10…150)
                        label: _depthUnlimitedSelected
                            ? l10n.reportFilterAny
                            : l10n.reportFilterDepthKm(
                                _maxDepth.toStringAsFixed(0),
                              ),
                        onChanged: (v) => setState(() => _maxDepth = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    icon: Icons.place_outlined,
                    title: l10n.reportFilterLocation,
                    child: TextField(
                      controller: _loc,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: l10n.reportFilterLocationHint,
                        filled: true,
                        fillColor: colors.surface,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.small,
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.small,
                          borderSide: BorderSide(
                            color: colors.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.small,
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
  const _ValuePill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = color ?? colors.primaryContainer;
    final fg = color == null
        ? colors.onPrimaryContainer
        : (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
              ? Colors.white
              : Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.small),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  const _IntensityChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = selected
        ? (color ?? colors.primary)
        : colors.surfaceContainerHighest;
    final fg = selected
        ? (color == null
              ? colors.onPrimary
              : (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
                    ? Colors.white
                    : Colors.black87))
        : colors.onSurface;
    return Material(
      color: bg,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: AppRadius.small,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            border: selected && color != null
                ? Border.all(color: color!.withValues(alpha: 0.9), width: 1.5)
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
