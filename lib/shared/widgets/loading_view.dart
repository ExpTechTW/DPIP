import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A small inline spinner for list rows / cards — no label, sized for context.
/// Use instead of a hand-rolled `SizedBox` + `CircularProgressIndicator` so
/// every in-list waiting state shares the same weight.
class InlineLoading extends StatelessWidget {
  const InlineLoading({super.key, this.size = 24, this.color});

  /// Edge length in logical pixels.
  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: color ?? Theme.of(context).colorScheme.primary,
    ),
  );
}

/// The loading state of the async-state contract: a centered spinner with a
/// label, so every feature shows waiting the same way instead of a blank frame.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  /// Overrides the default "Loading…" label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            label ?? AppLocalizations.of(context).commonLoading,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
