import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The error state of the async-state contract: an icon, a headline, the
/// underlying reason, and an optional retry — so a failed request is always
/// visible and recoverable rather than a silent blank.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.headline,
    this.detail,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Overrides the default "Something went wrong" headline.
  final String? headline;

  /// The failure reason (e.g. a [Failure] message), shown under the headline.
  final String? detail;

  /// When non-null, shows a retry button that invokes this.
  final VoidCallback? onRetry;

  /// Leading icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              headline ?? l10n.commonError,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
