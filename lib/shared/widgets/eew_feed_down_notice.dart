/// Says that the EEW feed is down, wherever an alert would otherwise appear.
///
/// Every surface that shows a live alert renders nothing when there is none —
/// and, rightly, nothing for an alert whose feed has gone stale or offline,
/// since an aged alert must never pass for a current one. Together those made
/// a dead feed look exactly like a calm one: the empty space on Home and in the
/// monitor read as "no earthquake" when it only meant "no connection". This is
/// what fills that space instead.
///
/// The colours follow `RealtimeView`'s freshness banner — tertiary while the
/// feed is merely late, error once it has given up — so a feed that is down
/// reads the same everywhere in the app.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class EewFeedDownNotice extends StatelessWidget {
  /// A self-contained pill — Home's banner slot and its alert section.
  const EewFeedDownNotice({
    super.key,
    required this.status,
    this.elevation = 0,
    this.maxLines = 2,
  }) : inline = false;

  /// Just the icon and the words, in the feed-state colour, for a surface
  /// that already has its own background — the monitor's status strip.
  const EewFeedDownNotice.inline({
    super.key,
    required this.status,
    this.maxLines = 2,
  }) : inline = true,
       elevation = 0;

  /// The EEW feed's status — meaningful only when [isDown].
  final RealtimeStatus status;

  /// The pill's elevation; non-zero where it floats over the map.
  final double elevation;

  /// One where the slot has a fixed height (Home's banner), two elsewhere.
  final int maxLines;

  final bool inline;

  /// Whether a feed in [status] is down: aged past live, or given up on. A
  /// feed still making its first connection is not — every launch passes
  /// through that.
  static bool isDown(RealtimeStatus status) =>
      status == RealtimeStatus.stale || status == RealtimeStatus.offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final offline = status == RealtimeStatus.offline;
    final icon = offline ? Icons.cloud_off_outlined : Icons.schedule_outlined;
    final label = AppLocalizations.of(context).eewFeedDown;

    if (inline) {
      final ink = offline ? colors.error : colors.tertiary;
      return Row(
        children: [
          Icon(icon, size: 16, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final background = offline
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final ink = offline ? colors.onErrorContainer : colors.onTertiaryContainer;
    return Material(
      color: background,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
