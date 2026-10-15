/// The "still showing data, but it is not current" strip — one look for every
/// surface that can put aged data on screen, realtime feed or one-shot list.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A thin banner flagging that the data below it is not current.
///
/// - [FreshnessBanner.feed]: a realtime feed has aged (`stale`) or dropped
///   (`offline`) — what [RealtimeView] puts over its last snapshot.
/// - [FreshnessBanner.saved]: a one-shot fetch could not reach its source and
///   the screen shows the copy saved last time ([Staleness]), with how old
///   that copy is when it is known.
class FreshnessBanner extends StatelessWidget {
  /// For a realtime feed in [status] — `stale` or `offline`.
  const FreshnessBanner.feed({super.key, required RealtimeStatus this.status})
    : staleness = null;

  /// For a saved copy shown in place of a current answer.
  const FreshnessBanner.saved({super.key, required Staleness this.staleness})
    : status = null;

  /// The feed's status, for [FreshnessBanner.feed].
  final RealtimeStatus? status;

  /// Why and since when the data is a saved copy, for [FreshnessBanner.saved].
  final Staleness? staleness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final saved = staleness;

    final (
      Color background,
      Color foreground,
      IconData icon,
      String label,
    ) = saved != null
        ? (
            colors.errorContainer,
            colors.onErrorContainer,
            Icons.cloud_off_outlined,
            switch (saved.since) {
              final since? => l10n.freshnessSavedCopy(
                ageLabel(l10n, AppTime.utc.difference(since)),
              ),
              null => l10n.freshnessSavedCopyUnknownAge,
            },
          )
        : switch (status) {
            RealtimeStatus.offline => (
              colors.errorContainer,
              colors.onErrorContainer,
              Icons.cloud_off_outlined,
              l10n.feedOffline,
            ),
            _ => (
              colors.tertiaryContainer,
              colors.onTertiaryContainer,
              Icons.schedule,
              l10n.feedStale,
            ),
          };

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            // Expanded: the saved-copy line carries an age and runs longer
            // than one line in some languages.
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [age] as the coarsest whole unit that still says something: minutes
  /// under an hour, hours under two days, days beyond. Never "0 minutes" —
  /// a copy is at least a minute old by the time anyone reads the label —
  /// and a negative age (a clock that moved) reads as the minimum too.
  static String ageLabel(AppLocalizations l10n, Duration age) {
    if (age < const Duration(hours: 1)) {
      return l10n.durationMinutes(age.inMinutes < 1 ? 1 : age.inMinutes);
    }
    if (age < const Duration(days: 2)) return l10n.durationHours(age.inHours);
    return l10n.durationDays(age.inDays);
  }
}
