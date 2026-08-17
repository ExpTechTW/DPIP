/// A small "n/total" pill signalling that its card is one of several the user
/// can tap through — the monitor's live overlay and the report replay page's
/// map overlay both show one alert card at a time and cycle through the rest
/// on tap, so this is shared rather than kept as two near-identical widgets.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AlertCycleChip extends StatelessWidget {
  const AlertCycleChip({
    super.key,
    required this.position,
    required this.count,
  });

  /// This alert's 1-based position within [count].
  final int position;

  /// The number of alerts to cycle through.
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            '$position/$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
