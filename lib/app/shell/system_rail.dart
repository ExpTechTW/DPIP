import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:foldable/foldable.dart';

/// iPhone Duo's system rail: the vertical strip the Dynamic Island and status
/// bar move into on the outer display and the landscape inner display.
///
/// There the HIG puts the tab bar in that strip, pinned to its bottom, instead
/// of along the bottom edge. Every other device keeps the ordinary bottom
/// [NavigationBar] unless the display setting asks for that same pill along the
/// bottom edge ([FloatingTabBar]) — this file owns both so there is one cell.

/// Test hook standing in for the hinge signal. `null` reads the real one.
@visibleForTesting
bool? debugAssumeFoldable;

/// The narrowest one-sided inset taken for a system rail. The measured rail is
/// 84 pt; a phone's landscape notch inset (~62 pt) is symmetric and fails the
/// one-sided test below anyway.
const double _minRailInset = 60;

/// Each cell is 48 × 48 — above iOS's 44 pt touch minimum.
const double kSystemRailControlExtent = 48;

/// Which side the system rail sits on, from the inset shape alone: no top
/// inset, and one side carrying a large inset the other does not.
AxisDirection? systemRailEdgeFor(EdgeInsets viewPadding) {
  if (viewPadding.top > 0.5) return null;
  final left = viewPadding.left;
  final right = viewPadding.right;
  if (right >= _minRailInset && left < right / 3) return AxisDirection.right;
  if (left >= _minRailInset && right < left / 3) return AxisDirection.left;
  return null;
}

/// The system rail's side, or `null` when this is not an iPhone Duo showing
/// one. The hinge signal comes first: a split-screen iPad or some future
/// device can produce a one-sided inset too, and the shape alone cannot tell
/// those apart. A build without the hinge signal (an older SDK) never enables
/// the rail and keeps the ordinary bottom bar.
AxisDirection? systemRailEdge(BuildContext context) {
  if (!(debugAssumeFoldable ?? DuoMediaQuery.isFoldableOf(context))) {
    return null;
  }
  return systemRailEdgeFor(MediaQuery.viewPaddingOf(context));
}

/// The shell's tab bar laid out down the system rail: icons only, one 48 pt
/// column in a frosted pill, pinned to the bottom of the rail.
///
/// Labels move to [Tooltip] and [Semantics]. The column scrolls (reversed, so
/// it stays pinned to the bottom when it fits) so a very short window still
/// reaches every tab.
class SystemRailTabBar extends StatelessWidget {
  const SystemRailTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom > 0 ? bottom : AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          reverse: true,
          child: FrostedSurface(
            borderRadius: BorderRadius.circular(kSystemRailControlExtent / 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _PillCell(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
                      extent: kSystemRailControlExtent,
                      indicator: const Size(40, 32),
                      iconSize: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same pill laid along the bottom edge instead of down the rail — the
/// alternative bottom bar (`NavBarStyle.floating`).
///
/// Icons only, for the same reason the rail has none: five labels do not fit
/// across a phone without shrinking them past the point of being readable, and
/// the pill is meant to be smaller than the strip it replaces. The labels stay
/// on [Tooltip] and [Semantics], so nothing the Material bar told a screen
/// reader is lost.
///
/// The cells are [kFloatingTabCellExtent] rather than the rail's 48, and the
/// pill dips into the home-indicator strip: at the full inset and the rail's
/// cell, a bar this wide read as a thin strip hovering above the window.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    // 12 pt off the safe-area inset, so the pill rests on the bottom of the
    // window instead of hovering above it. It overlaps the home-indicator
    // strip; the indicator is drawn over it and still takes the gesture.
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      // The top slot is not visual: the shell extends its body behind the bar,
      // and `Scaffold` hands the body `max(padding, bar height)` as its bottom
      // inset — so this is the gap the map's observation card keeps above the
      // pill. Without it the card's bottom edge and the pill's top edge are the
      // same line, and the two read as one block.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottom > _indicatorDip ? bottom - _indicatorDip : AppSpacing.sm,
      ),
      // `heightFactor: 1` because the bottom-bar slot hands down a loose
      // 0–full-height constraint: a bare Center takes all of it and draws the
      // pill in the middle of the screen.
      child: Center(
        heightFactor: 1,
        child: FrostedSurface(
          borderRadius: BorderRadius.circular(
            kFloatingTabCellExtent / 2 + _pillPadding,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _pillPadding,
              vertical: _pillPadding,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _PillCell(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                    extent: kFloatingTabCellExtent,
                    indicator: const Size(48, 36),
                    iconSize: 26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating bar's cell, 56 rather than the rail's 48: along the bottom of a
/// phone the rail's cell read as a thin strip, and a horizontal pill has the
/// width to give each tab more room.
const double kFloatingTabCellExtent = 56;

/// Gap between the pill and the cells inside it. Half the pill's height is
/// `extent / 2 + this`, which is where the capsule radius comes from.
const double _pillPadding = AppSpacing.xs;

/// How far the pill is allowed to sit inside the home-indicator strip.
const double _indicatorDip = 12;

/// One cell of the pill: the icon, and a rounded indicator while it is the
/// current tab. The rail passes [kSystemRailControlExtent], the bottom bar
/// [kFloatingTabCellExtent]; the indicator and the icon come with the cell so
/// the two bars are the same shape at two sizes.
class _PillCell extends StatelessWidget {
  const _PillCell({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.extent,
    required this.indicator,
    required this.iconSize,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  final double extent;
  final Size indicator;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = selected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: SizedBox.square(
          dimension: extent,
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onTap,
              radius: extent / 2,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  width: indicator.width,
                  height: indicator.height,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(indicator.height / 2),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: iconSize,
                      color: selected
                          ? colors.onSecondaryContainer
                          : colors.onSurfaceVariant,
                    ),
                    child: Center(child: icon),
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
