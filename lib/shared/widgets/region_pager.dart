import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pages a screen's body by area, so switching areas slides the *whole page*
/// (not just the region bar). Like the bar, the pager is non-interactive — a
/// horizontal swipe anywhere (see `RegionSwipeArea`) drives [AreaSelection] and
/// the pager slides to match, keeping the bar and body in step.
class RegionPager extends StatefulWidget {
  const RegionPager({super.key, required this.itemBuilder});

  /// Builds the body for the area at the given index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<RegionPager> createState() => _RegionPagerState();
}

class _RegionPagerState extends State<RegionPager> {
  late final PageController _controller;
  AreaSelection? _areas;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
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

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AreaSelection>().count;
    return PageView.builder(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: widget.itemBuilder,
    );
  }
}
