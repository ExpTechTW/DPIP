/// The 強震監視器's 震度排行 card: places and the strongest felt intensity in
/// each, strongest first — TREM-Lite's bottom-right list, drawn under the map
/// legend on the live monitor and on the replay page alike.
///
/// Only drawn while there is something to rank; a calm minute shows nothing
/// rather than an empty card over the map. What goes in the list — and that
/// only a live feed may fill it — is the caller's rule (`RtsAlertTracker`);
/// this is the drawing, shared so the two surfaces cannot drift apart.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';

/// One row: a place's display [name] and its felt intensity [level] (0–9).
typedef IntensityRankingEntry = ({String name, int level});

class IntensityRankingCard extends StatelessWidget {
  const IntensityRankingCard({super.key, required this.entries});

  /// Strongest first; the card draws them in the order given.
  final List<IntensityRankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: FrostedSurface(
        borderRadius: AppRadius.small,
        shadow: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.monitorIntensityRanking,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        IntensityBadge(
                          label: Intensity.label(entry.level),
                          color: IntensityColors.discrete(entry.level),
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(entry.name, style: text.bodyMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
