import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/presentation/event_labels.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A small pill naming where a card stands — 進行中, 結束時間未定, 已結束 or
/// 已撤銷.
///
/// A card in force is filled with the primary colour so it stands out in a
/// list of mostly finished ones; an ended card sits on a neutral surface; a
/// cancelled one is only outlined, so it never reads as in force.
class EventStatusChip extends StatelessWidget {
  const EventStatusChip({super.key, required this.status});

  /// The state shown.
  final EventCardStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (fill, ink, border) = switch (status) {
      EventCardStatus.active ||
      EventCardStatus.openEnded => (colors.primary, colors.onPrimary, null),
      EventCardStatus.ended => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        null,
      ),
      EventCardStatus.cancelled => (
        Colors.transparent,
        colors.onSurfaceVariant,
        colors.outline,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.small,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          status.label(AppLocalizations.of(context)),
          style: theme.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
