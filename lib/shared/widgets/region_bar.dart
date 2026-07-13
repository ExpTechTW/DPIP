import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/area_page_sync.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The area (地區) indicator at the top of Home and Events — a centered carousel
/// of badges over page dots. The selected area sits in the middle with a filled
/// badge; neighbours flank it and areas two or more away fade out.
///
/// It only *displays* [AreaSelection]; switching is a horizontal swipe anywhere
/// (see `RegionSwipeArea`) and the carousel slides to re-centre. Two `0→1`
/// dials drive its look over a backdrop, so the widget stays feature-agnostic:
/// [blend] fades the background transparent and flips the badges to light;
/// [dismiss] slides the whole bar up and fades it out. Home feeds these from its
/// sheet extent; Events leaves them at 0 for an opaque bar. It carries its own
/// top safe area so both effects cover the status-bar row too.
class RegionBar extends StatefulWidget {
  const RegionBar({super.key, this.blend = 0, this.dismiss = 0});

  /// How much the bar blends into the backdrop (0 opaque → 1 transparent, light
  /// badges).
  final double blend;

  /// How far the bar has slid up and faded out (0 shown → 1 gone).
  final double dismiss;

  @override
  State<RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<RegionBar> with AreaPageSyncMixin {
  // Peeking carousel: the centre badge flanked by its neighbours.
  @override
  double get areaViewportFraction => 0.25;

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<AreaSelection>();
    syncAreaPageOffscreen(areas.selectedIndex);
    return _build(
      context,
      blend: widget.blend,
      dismiss: widget.dismiss,
      count: areas.count,
    );
  }

  Widget _build(
    BuildContext context, {
    required double blend,
    required double dismiss,
    required int count,
  }) {
    final colors = Theme.of(context).colorScheme;
    // Slide up by the bar's own height and fade out once the sheet invades it;
    // release taps to the sheet behind as soon as it is mostly gone.
    return IgnorePointer(
      ignoring: dismiss > 0.5,
      child: Opacity(
        opacity: 1 - dismiss,
        child: FractionalTranslation(
          translation: Offset(0, -dismiss),
          child: ColoredBox(
            color: Color.lerp(colors.surface, Colors.transparent, blend)!,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: PageView.builder(
                  controller: areaPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: count,
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: areaPageController,
                    builder: (context, _) => _RegionBadge(
                      index: index,
                      distance: (areaPage - index).abs(),
                      reveal: blend,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single area badge, styled by its [distance] from the carousel centre and
/// shifted to light as [reveal] rises so it stays legible over the backdrop.
class _RegionBadge extends StatelessWidget {
  const _RegionBadge({
    required this.index,
    required this.distance,
    required this.reveal,
  });

  final int index;
  final double distance;
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // 1 at the centre → 0 one step away: badge fill and text emphasis.
    final fill = (1 - distance).clamp(0.0, 1.0);
    // Full within one step, then fades out toward two steps away.
    final opacity = distance <= 1
        ? 1.0
        : (1 - (distance - 1) * 0.85).clamp(0.15, 1.0);

    // Palette shifts to light as the backdrop takes over.
    final badgeBase = Color.lerp(
      colors.primaryContainer,
      Colors.white.withValues(alpha: 0.22),
      reveal,
    )!;
    final restText = Color.lerp(colors.onSurface, Colors.white, reveal)!;
    final centreText = Color.lerp(
      colors.onPrimaryContainer,
      Colors.white,
      reveal,
    )!;

    return GestureDetector(
      // Tapping a badge selects it — the other switch mode besides swiping.
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<AreaSelection>().select(index),
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: badgeBase.withValues(alpha: badgeBase.a * fill),
              borderRadius: AppRadius.large,
            ),
            child: Text(
              l10n.areaPlaceholder(index + 1),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Color.lerp(restText, centreText, fill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
