import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/core/settings/home_chrome.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The area (地區) indicator at the top of Home and Events — a centered carousel
/// of badges over page dots. The selected area sits in the middle with a filled
/// badge; neighbours flank it and areas two or more away fade out.
///
/// It only *displays* [AreaSelection]; switching is a horizontal swipe anywhere
/// (see `RegionSwipeArea`) and the carousel slides to re-centre. When placed over
/// the home weather backdrop, pass [sheetExtent]: as the sheet climbs the bar
/// first *blends* into the weather (its background fades transparent and its
/// badges flip to light), then *dismisses* — sliding up and fading out — once the
/// rising sheet invades it, leaving the weather unobstructed. It carries its own
/// top safe area so both effects cover the status-bar row too.
class RegionBar extends StatefulWidget {
  const RegionBar({super.key, this.sheetExtent});

  /// The active Home sheet's extent (0→1) driving the bar's blend and dismissal;
  /// null (Events) keeps it an opaque surface bar.
  final ValueListenable<double>? sheetExtent;

  @override
  State<RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<RegionBar> {
  late final PageController _controller;
  AreaSelection? _areas;
  bool _animating = false;

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

  double get _page => !_controller.hasClients
      ? _controller.initialPage.toDouble()
      : (_controller.page ?? _controller.initialPage.toDouble());

  void _animateToSelected() {
    if (!_controller.hasClients) return;
    final index = _areas!.selectedIndex;
    if (_page.round() == index) return;
    _animating = true;
    _controller
        .animateToPage(
          index,
          duration: AppMotion.medium,
          curve: Curves.easeInOutCubicEmphasized,
        )
        .whenComplete(() {
          if (mounted) _animating = false;
        });
  }

  @override
  void dispose() {
    _areas?.removeListener(_animateToSelected);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<AreaSelection>();
    // Safety net: snap to the shared selection if this bar missed a change while
    // off-screen — keeps Home and Events in sync.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _animating || !_controller.hasClients) return;
      if (_page.round() != areas.selectedIndex) {
        _controller.jumpToPage(areas.selectedIndex);
      }
    });
    final sheetExtent = widget.sheetExtent;
    if (sheetExtent == null) {
      return _build(context, blend: 0, dismiss: 0, count: areas.count);
    }
    return ValueListenableBuilder<double>(
      valueListenable: sheetExtent,
      builder: (context, extent, _) => _build(
        context,
        blend: HomeChrome.regionBlend(extent),
        dismiss: HomeChrome.regionDismiss(extent),
        count: areas.count,
      ),
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
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: count,
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _RegionBadge(
                      index: index,
                      distance: (_page - index).abs(),
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
