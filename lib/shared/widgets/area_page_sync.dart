import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Binds a driven [PageController] to [AreaSelection] for a widget that only
/// *reflects* the selection (RegionBar's badge carousel, RegionPager's body).
///
/// Owns the controller lifecycle, the selection listener, an in-flight guard so
/// an animation isn't interrupted, and an off-screen resync — the subtle state
/// machine both widgets otherwise copy verbatim. Mix in, read [areaPage] in
/// build, and call [syncAreaPageOffscreen] from build (it schedules a
/// post-frame catch-up). Override [areaViewportFraction] for a peeking carousel.
mixin AreaPageSyncMixin<W extends StatefulWidget> on State<W> {
  late final PageController areaPageController;
  AreaSelection? _areas;
  bool _animating = false;

  /// Fraction of the viewport each page occupies — 1 (full) by default; a
  /// carousel that peeks neighbours overrides it (e.g. 0.25).
  double get areaViewportFraction => 1;

  @override
  void initState() {
    super.initState();
    areaPageController = PageController(
      viewportFraction: areaViewportFraction,
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

  /// The controller's live page (or its initial page before it's attached).
  double get areaPage => !areaPageController.hasClients
      ? areaPageController.initialPage.toDouble()
      : (areaPageController.page ?? areaPageController.initialPage.toDouble());

  void _animateToSelected() {
    if (!areaPageController.hasClients) return;
    final index = _areas!.selectedIndex;
    if (areaPage.round() == index) return;
    _animating = true;
    areaPageController
        .animateToPage(
          index,
          duration: AppMotion.medium,
          curve: Curves.easeInOutCubicEmphasized,
        )
        .whenComplete(() {
          if (mounted) _animating = false;
        });
  }

  /// Snaps to [selectedIndex] on the next frame if this widget missed a change
  /// while off-screen (e.g. on another tab) — keeps Home and Events in step.
  /// Call from build; it's a no-op mid-animation or when already aligned.
  void syncAreaPageOffscreen(int selectedIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _animating || !areaPageController.hasClients) return;
      if (areaPage.round() != selectedIndex) {
        areaPageController.jumpToPage(selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _areas?.removeListener(_animateToSelected);
    areaPageController.dispose();
    super.dispose();
  }
}
