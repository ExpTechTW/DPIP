/// Settings: choose which agencies' EEW (Earthquake Early Warning) alerts the
/// live monitor, its replay, and the earthquake list show.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Two-card choice — the active source is called out with a tinted surface,
/// outline and radio-style check. Tapping either updates
/// [EewCwaOnlySettings], which every EEW data source reads fresh on its next
/// poll.
class EewSourcePage extends StatelessWidget {
  const EewSourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<EewCwaOnlySettings>();
    final cwaOnly = settings.enabled;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eewSourceSettings)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            l10n.eewSourceSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SourceOptionCard(
            icon: Icons.hub_outlined,
            title: Text(l10n.eewSourceAll),
            description: Text(l10n.eewSourceAllDescription),
            selected: !cwaOnly,
            onTap: () => settings.setEnabled(false),
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceOptionCard(
            icon: Icons.account_balance_outlined,
            title: Text(l10n.eewSourceCwaOnly),
            description: Text(l10n.eewSourceCwaOnlyDescription),
            selected: cwaOnly,
            onTap: () => settings.setEnabled(true),
          ),
        ],
      ),
    );
  }
}

/// A source choice with enough visual structure to make the current filter
/// obvious without relying on the checkmark alone.
class _SourceOptionCard extends StatelessWidget {
  const _SourceOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Widget title;
  final Widget description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: colors.onSurface),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          child: title,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                          child: description,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
