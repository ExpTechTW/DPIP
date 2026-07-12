import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The area (地區) indicator at the top of Home and Events — a centered carousel
/// of badges. The selected area sits in the middle with a filled badge; its
/// neighbours flank it and areas two or more away fade out ("+2 太遠").
///
/// It only *displays* [AreaSelection] (the pager is non-interactive); switching
/// is a horizontal swipe anywhere on the page (see `RegionSwipeArea`). On a
/// selection change the carousel slides to re-centre — the recommended
/// `PageController`-driven transition — so both screens' bars stay in sync.
class RegionBar extends StatefulWidget {
  const RegionBar({super.key});

  @override
  State<RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<RegionBar> {
  late final PageController _controller;
  AreaSelection? _areas;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.25,
      initialPage: context.read<AreaSelection>().selectedIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final areas = context.read<AreaSelection>();
    if (areas != _areas) {
      _areas?.removeListener(_animateToSelected);
      _areas = areas..addListener(_animateToSelected);
    }
  }

  /// Slides the carousel to re-centre the selected area — the transition.
  void _animateToSelected() {
    if (!_controller.hasClients) return;
    final index = _areas!.selectedIndex;
    if ((_controller.page ?? _controller.initialPage.toDouble()).round() ==
        index) {
      return;
    }
    _controller.animateToPage(
      index,
      duration: AppMotion.medium,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _areas?.removeListener(_animateToSelected);
    _controller.dispose();
    super.dispose();
  }

  double get _page => !_controller.hasClients
      ? _controller.initialPage.toDouble()
      : (_controller.page ?? _controller.initialPage.toDouble());

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AreaSelection>().count;
    return SizedBox(
      height: 44,
      child: PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) =>
              _RegionBadge(index: index, distance: (_page - index).abs()),
        ),
      ),
    );
  }
}

/// A single area badge, styled by its [distance] from the carousel centre:
/// filled and opaque at the centre, plain alongside, faded two or more away.
class _RegionBadge extends StatelessWidget {
  const _RegionBadge({required this.index, required this.distance});

  final int index;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // 1 at the centre → 0 by one step away: the badge fill and text emphasis.
    final fill = (1 - distance).clamp(0.0, 1.0);
    // Full within one step, then fades out toward two steps away.
    final opacity = distance <= 1
        ? 1.0
        : (1 - (distance - 1) * 0.85).clamp(0.15, 1.0);

    return Opacity(
      opacity: opacity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: fill),
            borderRadius: AppRadius.large,
          ),
          child: Text(
            l10n.areaPlaceholder(index + 1),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Color.lerp(
                colors.onSurface,
                colors.onPrimaryContainer,
                fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
