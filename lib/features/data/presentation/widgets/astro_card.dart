/// The one surface the astronomy pages are built from.
///
/// Every group on every astronomy page sits in the same inset rounded card, so
/// a table of planets reads as a peer of a list of twilight times rather than
/// as a different kind of thing. Shared rather than copied because the moon,
/// sun and planet pages are read one after another and any drift between them
/// shows immediately.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// One icon / label / value line.
typedef AstroReading = (IconData icon, String label, String value);

/// An inset rounded surface.
class AstroCard extends StatelessWidget {
  const AstroCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.medium,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    ),
  );
}

/// A card of readings, divided.
class AstroReadings extends StatelessWidget {
  const AstroReadings({super.key, required this.rows});

  final List<AstroReading> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AstroCard(
      child: Column(
        children: [
          for (final (index, (icon, label, value)) in rows.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: AppSpacing.xxl + AppSpacing.md,
                color: colors.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A pair of times that bracket an event — dawn either side of sunrise, dusk
/// either side of sunset. Rendered as one row so the pairing is visible.
class AstroSpan extends StatelessWidget {
  const AstroSpan({
    super.key,
    required this.icon,
    required this.label,
    required this.from,
    required this.to,
  });

  final IconData icon;
  final String label;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            // l10n-ignore: an en dash between two already-localised times
            '$from – $to',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
