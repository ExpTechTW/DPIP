import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The empty state of the async-state contract: a calm icon + message for a
/// request that succeeded but returned nothing. Distinct from [ErrorView] — an
/// empty list is a valid outcome, not a failure.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});

  /// Leading icon conveying the empty context (e.g. a checkmark for "all clear").
  final IconData icon;

  /// The message explaining the empty state.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
