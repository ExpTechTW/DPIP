/// The small selectable pill both map sheets use to pick which item of a set
/// they are showing — one storm out of several, one 報 out of an event.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A labelled pill that reads as pressed when [selected].
///
/// Extracted from the typhoon sheet's cyclone picker so the tsunami sheet's
/// report picker (第1報 / 第2報 / 第3報) is the same affordance rather than a
/// second, slightly different one. Deliberately a pill and not a dropdown: the
/// sets it chooses between are small, and every option stays visible — a reader
/// comparing 第1報 with 第3報 should not have to open a menu twice.
class SelectablePill extends StatelessWidget {
  const SelectablePill({
    super.key,
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
    final radius = BorderRadius.circular(AppSpacing.lg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryContainer.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
