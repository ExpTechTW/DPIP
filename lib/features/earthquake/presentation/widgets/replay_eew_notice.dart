import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/replay_eew_probe.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The line the replay shows on the EEW slot while there is no card to show.
///
/// Four different things can be true at that moment and they must not look
/// alike: nothing has answered yet, the feed is failing, the feed is down, or
/// the event was sampled and nothing turned up. Only the last one is a verdict;
/// the other three are states of the connection, so the wording never borrows
/// "there is no EEW" for them.
class ReplayEewNotice extends StatelessWidget {
  const ReplayEewNotice({super.key, required this.slot});

  /// The slot to draw. [ReplayEewSlot.card] and [ReplayEewSlot.pending] draw
  /// nothing, so the caller can pass whatever it decided without branching.
  final ReplayEewSlot slot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String message, String? detail) = switch (slot) {
      ReplayEewSlot.waiting => (
        Icons.hourglass_empty,
        l10n.replayEewWaiting,
        null,
      ),
      ReplayEewSlot.retrying => (
        Icons.sync_problem,
        l10n.replayEewRetrying,
        null,
      ),
      ReplayEewSlot.unavailable => (
        Icons.cloud_off,
        l10n.replayEewUnavailable,
        null,
      ),
      ReplayEewSlot.none => (
        Icons.search_off,
        l10n.replayEewNone,
        l10n.replayEewNoneDetail,
      ),
      ReplayEewSlot.card ||
      ReplayEewSlot.pending => (Icons.hourglass_empty, '', null),
    };
    if (message.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: AppRadius.medium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.labelLarge?.copyWith(color: muted),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muted.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
