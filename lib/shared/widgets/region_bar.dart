import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A swipeable bar of the user's geographic areas (地區), shown at the top of
/// Home (inside the sheet) and Events. Swiping left/right switches the active
/// area via [AreaSelection]; page dots show the position. Both screens' bars
/// stay in sync through the shared selection.
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
      initialPage: context.read<AreaSelection>().selectedIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final areas = context.read<AreaSelection>();
    if (areas != _areas) {
      _areas?.removeListener(_syncPage);
      _areas = areas..addListener(_syncPage);
    }
  }

  /// Animates the pager when the selection changes elsewhere (the other
  /// screen's bar).
  void _syncPage() {
    if (!_controller.hasClients) return;
    final index = _areas!.selectedIndex;
    if (_controller.page?.round() == index) return;
    _controller.animateToPage(
      index,
      duration: AppMotion.medium,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _areas?.removeListener(_syncPage);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final areas = context.watch<AreaSelection>();
    return SizedBox(
      height: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: areas.select,
              itemCount: areas.count,
              itemBuilder: (context, index) => Center(
                child: Text(
                  l10n.areaPlaceholder(index + 1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _PageDots(count: areas.count, active: areas.selectedIndex),
        ],
      ),
    );
  }
}

/// The row of dots under the region pager marking the active area.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == active
                  ? colors.primary
                  : colors.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
