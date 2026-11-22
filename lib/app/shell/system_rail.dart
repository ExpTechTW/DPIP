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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottom > 0 ? bottom : AppSpacing.lg,
      ),
      // `heightFactor: 1` because the bottom-bar slot hands down a loose
      // 0–full-height constraint: a bare Center takes all of it and draws the
      // pill in the middle of the screen.
      child: Center(
        heightFactor: 1,
        child: FrostedSurface(
          borderRadius: BorderRadius.circular(kSystemRailControlExtent / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  _PillCell(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One 48 pt cell of the pill: the icon, and a rounded indicator while it is
/// the current tab.
class _PillCell extends StatelessWidget {
  const _PillCell({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

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
          dimension: kSystemRailControlExtent,
          child: Material(
            type: MaterialType.transparency,
            child: InkResponse(
              onTap: onTap,
              radius: kSystemRailControlExtent / 2,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 40,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: 24,
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
