import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The header at the top of the home sheet: the selected area, its active
/// warning, and the current weather — condition icon + temperature on the left
/// (2/3), precipitation + humidity stacked on the right (1/3).
///
/// Values are placeholders until the weather/area API is wired.
class HomeSheetHeader extends StatelessWidget {
  const HomeSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('臺南市 歸仁區', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        const _WarningBadge(label: '大豪雨特報'),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left 2/3 — condition icon + temperature.
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '26.6',
                          style: theme.textTheme.displaySmall,
                        ),
                        TextSpan(
                          text: '°C',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right 1/3 — precipitation over humidity.
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Metric(
                    label: AppLocalizations.of(context).weatherPrecipitation,
                    value: '0.0 mm',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Metric(
                    label: AppLocalizations.of(context).weatherHumidity,
                    value: '90%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A pill flagging the area's active warning.
class _WarningBadge extends StatelessWidget {
  const _WarningBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small label over a prominent value (e.g. "Precipitation" / "0.0 mm").
class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
