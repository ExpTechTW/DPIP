/// How every EEW card says "this alert was cancelled" — a small tag for the
/// header and a strip that takes the place of the local-estimate tiles.
///
/// Shared for the same reason [EewEstimateTile] is: the earthquake list, the
/// replay overlay, the map monitor and the home sheet each carry their own
/// card (the layering gate keeps them apart), and a cancel that looked
/// different on each of them is a cancel somebody misreads. Deliberately
/// neutral — surface tones, never the error or intensity colours — because
/// the one thing a cancelled card must not do is still look like a warning.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The "已取消" pill beside a cancelled card's title.
class EewCancelledTag extends StatelessWidget {
  const EewCancelledTag({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          AppLocalizations.of(context).eewCancelled,
          maxLines: 1,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The line a cancelled card shows where a live one shows its local
/// intensity and S-wave countdown: a cancelled event has neither.
class EewCancelledNotice extends StatelessWidget {
  const EewCancelledNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(context).eewCancelledNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
