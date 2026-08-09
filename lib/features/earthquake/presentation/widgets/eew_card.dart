/// A single EEW alert card: epicentre location with its magnitude and depth.
/// Shared between the live [EarthquakePage] list and the report replay page's
/// map overlay.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class EewCard extends StatelessWidget {
  const EewCard({super.key, required this.eew});

  final Eew eew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final info = eew.info;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.location, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.eewSummary(
                      info.magnitude.toStringAsFixed(1),
                      info.depth.toStringAsFixed(0),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
