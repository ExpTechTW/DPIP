import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/area_page_sync.dart';
import 'package:dpip/shared/widgets/region_label.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The area (地區) indicator at the top of Home and Events — a centered carousel
/// of badges over page dots. The selected area sits in the middle with a filled
/// badge; neighbours flank it and areas two or more away fade out.
///
/// It only *displays* [RegionStore]; switching is a horizontal swipe anywhere
/// (see `RegionSwipeArea`) and the carousel slides to re-centre. Two `0→1`
/// dials drive its look over a backdrop, so the widget stays feature-agnostic:
/// [blend] fades the bar background transparent and shifts badge ink for the
/// sky ([skyIsLight]); [dismiss] slides the whole bar up and fades it out. Home
/// feeds these from its sheet extent; Events leaves them at 0 for an opaque
/// bar. It carries its own top safe area so both effects cover the status-bar
/// row too.
///
/// A page may put one action at the bar's right end ([trailing]); it fades and
/// slides away with the bar, and is inked like the badges.
class RegionBar extends StatefulWidget {
  const RegionBar({
    super.key,
    this.blend = 0,
    this.dismiss = 0,
    this.skyIsLight = true,
    this.trailing,
  });

  /// The bar's own height, below the status bar it is inset by. Public because
  /// the Home map is laid out *behind* this bar, so its camera fit has to
  /// subtract this much from the top to frame inside the band the user can see.
  static const double height = 44;

  /// How much the bar blends into the backdrop (0 opaque → 1 transparent).
  final double blend;

  /// How far the bar has slid up and faded out (0 shown → 1 gone).
  final double dismiss;

  /// Whether the weather sky behind the bar is light — badge ink goes dark on
  /// a light sky (dark-theme white [ColorScheme.onSurface] would vanish).
  final bool skyIsLight;

  /// One action at the right end — an icon button. The carousel keeps an
  /// equal inset on both sides while it is there, so the selected badge stays
  /// centred on the screen rather than shifting left by half the button.
  final Widget? trailing;

  /// The width kept for [trailing], on each side of the carousel.
  static const double actionWidth = 44;

  @override
  State<RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<RegionBar> with AreaPageSyncMixin {
  // Peeking carousel: the centre badge flanked by its neighbours.
  @override
  double get areaViewportFraction => 0.25;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RegionStore>();
    syncAreaPageOffscreen(store.selectedIndex);
    // Read `areas` once (the getter allocates a fresh list each call).
    final areas = store.areas;
    final blend = widget.blend;
    final dismiss = widget.dismiss;
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final directory = context.read<TownDirectory>();
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
                height: RegionBar.height,
                child: _withTrailing(
                  context,
                  PageView.builder(
                    controller: areaPageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      // Resolved here, once per item, not inside the builder
                      // below: the label is a directory lookup that does not
                      // depend on the page position, and the builder runs for
                      // every visible badge on every pixel of the slide.
                      final label = regionAreaLabel(
                        l10n,
                        directory,
                        areas[index],
                      );
                      return AnimatedBuilder(
                        animation: areaPageController,
                        builder: (context, _) => _RegionBadge(
                          index: index,
                          label: label,
                          distance: (areaPage - index).abs(),
                          blend: blend,
                          skyIsLight: widget.skyIsLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [carousel] alone, or with [RegionBar.trailing] at the right end.
  Widget _withTrailing(BuildContext context, Widget carousel) {
    final trailing = widget.trailing;
    if (trailing == null) return carousel;
    // The same sky-aware ink as the unselected badges, for an icon button.
    final ink = inkOverWeather(
      Theme.of(context).colorScheme,
      widget.blend,
      skyIsLight: widget.skyIsLight,
    );
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RegionBar.actionWidth,
          ),
          child: carousel,
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: RegionBar.actionWidth,
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(foregroundColor: ink),
            ),
            child: Center(child: trailing),
          ),
        ),
      ],
    );
  }
}

/// A single area badge, styled by its [distance] from the carousel centre.
class _RegionBadge extends StatelessWidget {
  const _RegionBadge({
    required this.index,
    required this.label,
    required this.distance,
    required this.blend,
    required this.skyIsLight,
  });

  final int index;

  /// The area's display name, resolved by the bar (see its `itemBuilder`).
  final String label;
  final double distance;
  final double blend;
  final bool skyIsLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // 1 at the centre → 0 one step away: badge fill and text emphasis.
    final fill = (1 - distance).clamp(0.0, 1.0);
    // Full within one step, then fades out toward two steps away.
    final opacity = distance <= 1
        ? 1.0
        : (1 - (distance - 1) * 0.85).clamp(0.15, 1.0);

    // Unfilled neighbours sit on the (possibly transparent) bar — sky-aware
    // ink. The centre fill keeps [onPrimaryContainer] on [primaryContainer].
    final badgeBase = colors.primaryContainer;
    final restText = inkOverWeather(colors, blend, skyIsLight: skyIsLight);
    final centreText = colors.onPrimaryContainer;

    return GestureDetector(
      // Tapping a badge selects it — the other switch mode besides swiping.
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<RegionStore>().select(index),
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
              label,
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
