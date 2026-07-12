import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The area (地區) indicator shown at the top of Home and Events — the current
/// area name over page dots. It only *displays* [AreaSelection]; switching is a
/// horizontal swipe anywhere on the page (see `RegionSwipeArea`), so both
/// screens' bars stay in sync through the shared selection.
class RegionBar extends StatelessWidget {
  const RegionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final areas = context.watch<AreaSelection>();
    return SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: Text(
              l10n.areaPlaceholder(areas.selectedIndex + 1),
              key: ValueKey(areas.selectedIndex),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _PageDots(count: areas.count, active: areas.selectedIndex),
        ],
      ),
    );
  }
}

/// The row of dots under the area name marking the active area.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == active
                  ? colors.primary
                  : colors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
