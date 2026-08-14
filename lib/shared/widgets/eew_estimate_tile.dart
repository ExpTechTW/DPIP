/// One EEW estimate tile — a small label over a bold value, on a tonal or
/// fixed background. Every EEW alert card across features (the earthquake
/// monitor, report replay, map overlay, and home sheet) renders its local-
/// intensity/S-wave-countdown pair through this one widget, so the colours
/// can't drift between them the way they used to when each card kept its own
/// copy.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EewEstimateTile extends StatelessWidget {
  const EewEstimateTile({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  /// The S-wave alert tile's background: a fixed vivid red regardless of app
  /// theme or arrival state — M3's dark-mode `error` role is a pale pink for
  /// contrast, which reads as calm rather than urgent for a safety-critical
  /// warning.
  static Color alertRed() => AppTheme.scheme(Brightness.light).error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.small,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
