import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/shared/widgets/area_page_sync.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pages a screen's body by area, so switching areas slides the *whole page*
/// (not just the region bar). Like the bar, the pager is non-interactive — a
/// horizontal swipe anywhere (see `RegionSwipeArea`) drives [AreaSelection] and
/// the pager slides to match (via [AreaPageSyncMixin]), keeping the bar and body
/// in step.
class RegionPager extends StatefulWidget {
  const RegionPager({super.key, required this.itemBuilder});

  /// Builds the body for the area at the given index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<RegionPager> createState() => _RegionPagerState();
}

class _RegionPagerState extends State<RegionPager> with AreaPageSyncMixin {
  @override
  Widget build(BuildContext context) {
    final areas = context.watch<AreaSelection>();
    syncAreaPageOffscreen(areas.selectedIndex);
    return PageView.builder(
      controller: areaPageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: areas.count,
      itemBuilder: widget.itemBuilder,
    );
  }
}
