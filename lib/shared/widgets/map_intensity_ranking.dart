/// The 震度排行榜 — the townships a seismic feed currently reports as shaking,
/// strongest first, as a card that opens from the map's top-left control row.
///
/// Ported from the legacy monitor (`app_old/page/map/monitor/monitor.dart`,
/// `_updateBoxLine`), which drew the same top three as bare chips pinned to the
/// map's top-left corner with no way to dismiss them. Here they live behind a
/// button in [MapCornerControls], deliberately in that row's chrome and
/// density, because the corner they occupied is the north-west of the island —
/// the one place a Taiwan map can least afford a permanent overlay.
///
/// Purely presentational: what may be shown, and in what order, is decided by
/// the caller (`rtsAreaRanking`) so the live monitor and the replay page can
/// share one rule.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';

/// One row: a township code (as [TownDirectory] keys it) and its intensity.
typedef IntensityRankingEntry = ({String code, int intensity});

/// The ranking itself: a frosted card of up to three townships, or the calm
/// empty line.
///
/// Two surfaces mount it — the live monitor and the replay page — from the same
/// control row, so it has to look the same either way. It only draws [areas];
/// whether there is anything to show at all is the caller's decision, and the
/// button that opened it is what closes it again.
class IntensityRankingCard extends StatelessWidget {
  const IntensityRankingCard({
    super.key,
    required this.areas,
    required this.directory,
  });

  /// Rows, strongest first; empty renders the calm line — live but nothing
  /// triggered, rather than a control that opens onto nothing.
  final List<IntensityRankingEntry> areas;

  /// Resolves a township code to its display name.
  final TownDirectory directory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return FrostedSurface(
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monitorIntensityRanking,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (areas.isEmpty)
              Text(
                l10n.monitorIntensityRankingEmpty,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              for (final area in areas)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: _RankRow(area: area, directory: directory),
                ),
          ],
        ),
      ),
    );
  }
}

/// An intensity reading at the ranking's own size — glyph-sized, so it can ride
/// on the collapsed button (`MapChipButton.trailing`) without making that button
/// taller than the plain ones beside it.
class IntensityRankingBadge extends StatelessWidget {
  const IntensityRankingBadge({super.key, required this.intensity});

  final int intensity;

  @override
  Widget build(BuildContext context) => IntensityBadge(
    label: Intensity.label(intensity),
    color: IntensityColors.discrete(intensity),
    size: 22,
  );
}

/// One township: its intensity badge and its full administrative name.
class _RankRow extends StatelessWidget {
  const _RankRow({required this.area, required this.directory});

  final IntensityRankingEntry area;
  final TownDirectory directory;

  @override
  Widget build(BuildContext context) {
    final town = directory.byCode(area.code);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntensityRankingBadge(intensity: area.intensity),
        const SizedBox(width: AppSpacing.sm),
        // A code with no directory entry still names *something* the feed
        // reported — printing the raw code beats dropping the row silently.
        Text(
          town?.fullName ?? area.code,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
