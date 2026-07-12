import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
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
/// a backdrop (the home weather), pass [reveal] (0→1): the bar fades its own
/// background to transparent and flips its badges to light so it blends into the
/// backdrop instead of leaving an opaque strip. It carries its own top safe area
/// so that fade covers the status-bar row too.
class RegionBar extends StatefulWidget {
  const RegionBar({super.key, this.reveal});

  /// How much the backdrop behind the bar is revealed; null (Events) keeps it an
  /// opaque surface bar.
  final ValueListenable<double>? reveal;

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
    final reveal = widget.reveal;
    if (reveal == null) return _build(context, 0, areas.count);
    return ValueListenableBuilder<double>(
      valueListenable: reveal,
      builder: (context, value, _) => _build(context, value, areas.count),
    );
  }

  Widget _build(BuildContext context, double reveal, int count) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Color.lerp(colors.surface, Colors.transparent, reveal)!,
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
                reveal: reveal,
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
