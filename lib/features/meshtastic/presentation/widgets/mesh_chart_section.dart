/// A history chart with its own time-range switch.
///
/// The range belongs to each chart rather than to the page, because the
/// questions differ: "has the battery been draining all day" wants 24 hours,
/// and "did the error rate spike just now" wants one — and a reader comparing
/// two charts should be able to hold one steady while moving the other.
///
/// The window is measured back from **now**, not from the newest sample. If
/// the radio has been away for three hours, the last hour genuinely contains
/// nothing, and showing the newest hour of data instead would present
/// three-hour-old readings as current.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:flutter/material.dart';

/// How far back a chart looks.
enum MeshChartRange {
  hour(Duration(hours: 1), '1h'),
  threeHours(Duration(hours: 3), '3h'),
  sixHours(Duration(hours: 6), '6h'),
  halfDay(Duration(hours: 12), '12h'),
  day(Duration(hours: 24), '24h');

  const MeshChartRange(this.window, this.label);

  final Duration window;

  /// l10n-ignore: an SI-style duration abbreviation, identical in every locale
  final String label;
}

class MeshChartSection extends StatefulWidget {
  const MeshChartSection({
    super.key,
    required this.title,
    required this.samples,
    required this.builder,
    this.initialRange = MeshChartRange.day,
    this.now,
  });

  final String title;

  /// The full retained history, oldest first. The section hands the builder
  /// only the part inside the chosen window.
  final List<MeshMetricSample> samples;

  final Widget Function(List<MeshMetricSample> windowed) builder;
  final MeshChartRange initialRange;

  /// Calibrated clock, injectable for tests. The same one the samples were
  /// stamped with — comparing a stored timestamp against the device clock
  /// would window by the clock offset rather than by elapsed time.
  final DateTime Function()? now;

  @override
  State<MeshChartSection> createState() => _MeshChartSectionState();
}

class _MeshChartSectionState extends State<MeshChartSection> {
  late MeshChartRange _range = widget.initialRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = widget.now?.call() ?? AppTime.utc.toLocal();
    final since = now.subtract(_range.window);
    final windowed = [
      for (final sample in widget.samples)
        if (!sample.at.isBefore(since)) sample,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _RangeSwitch(
                value: _range,
                onChanged: (range) => setState(() => _range = range),
              ),
            ],
          ),
        ),
        widget.builder(windowed),
      ],
    );
  }
}

/// The five windows as one compact strip.
///
/// Not a `SegmentedButton`: with five options its Material sizing (a 48 px
/// touch row with a check icon on the selected segment) takes most of a phone
/// width, leaving no room for the title beside it. These are a secondary
/// control on a dense diagnostic page, so they wear a small chip strip and
/// keep the row.
class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.value, required this.onChanged});

  final MeshChartRange value;
  final ValueChanged<MeshChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.large,
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in MeshChartRange.values)
            _RangeChip(
              label: range.label,
              selected: range == value,
              onTap: () => onChanged(range),
            ),
        ],
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
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.secondaryContainer : null,
            borderRadius: AppRadius.large,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              // The selected chip carries its state in the filled background
              // as well as the weight, so it does not rest on colour alone.
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? theme.colorScheme.onSecondaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
