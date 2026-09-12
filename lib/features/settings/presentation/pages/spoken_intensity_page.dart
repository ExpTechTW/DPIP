/// Settings: whether the seismic monitor speaks the estimated intensity before
/// the EEW warning sound.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One switch, not a two-card choice.
///
/// The first cut mirrored `EewSourcePage` with an "on" card and an "off" card.
/// Review (#568) pointed out that a page holding a single on/off setting is a
/// switch's job, and two cards made it look like it offered more than it does.
/// The one thing the cards did better — giving the cost somewhere to be said —
/// is kept as the note under the switch. Speech delays the warning sound by
/// however long the phrase takes, and a user has to read that *before* turning
/// this on, so the note is visible whichever way the switch sits rather than
/// only in the "on" state.
class SpokenIntensityPage extends StatelessWidget {
  const SpokenIntensityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<EewSpokenAnnouncementSettings>();
    final enabled = settings.enabled;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.eewSpokenAnnouncementTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            l10n.eewSpokenAnnouncementDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SwitchCard(
            icon: enabled
                ? Icons.record_voice_over_outlined
                : Icons.voice_over_off_outlined,
            title: Text(l10n.eewSpokenAnnouncementTitle),
            // The state in words, not just the switch's position — the same
            // line the More menu shows under this row, so the two agree.
            subtitle: Text(
              enabled
                  ? l10n.eewSpokenAnnouncementOn
                  : l10n.eewSpokenAnnouncementOff,
            ),
            value: enabled,
            onChanged: settings.setEnabled,
          ),
          const SizedBox(height: AppSpacing.md),
          _DelayNote(Text(l10n.eewSpokenAnnouncementOnDescription)),
        ],
      ),
    );
  }
}

/// The setting itself: icon, title, current state and a trailing [Switch].
///
/// The whole card toggles, not just the switch — a switch you can only hit by
/// aiming at the switch is a smaller target than the card it sits in.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Widget title;
  final Widget subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      toggled: value,
      child: Material(
        color: value
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
          side: BorderSide(
            color: value ? colors.primary : colors.outlineVariant,
            width: value ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: value
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(
                    icon,
                    color: value ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: theme.textTheme.titleMedium,
                        child: title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        child: subtitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The cost of turning the setting on, kept in view in both states.
class _DelayNote extends StatelessWidget {
  const _DelayNote(this.text);

  final Widget text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              child: text,
            ),
          ),
        ],
      ),
    );
  }
}
