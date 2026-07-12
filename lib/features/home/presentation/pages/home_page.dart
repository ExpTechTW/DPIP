import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/home_backdrop_reveal.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Home tab — the region bar pinned over a shared map backdrop, with a per-area
/// draggable sheet that expands full-screen *behind* the bar so its weather
/// backdrop fills the screen. A swipe anywhere pages the whole body (a map tap
/// opens the full map tab); the sheet height is shared across areas so switching
/// never collapses it.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Shared by every area's sheet so a switch keeps it at the same height.
  final ValueNotifier<double> _sharedExtent = ValueNotifier<double>(
    HomeSheet.restExtent,
  );

  @override
  void dispose() {
    _sharedExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RegionSwipeArea(
        child: Stack(
          children: [
            // Shared map backdrop; a tap opens the full map tab.
            Positioned.fill(
              child: GestureDetector(
                onTap: () => context.goNamed(AppRoutes.map),
                child: const HomeMapBackdrop(),
              ),
            ),
            // Per-area sheet the pager slides on a switch — full-screen behind
            // the region bar, so its weather fills up into the bar.
            Positioned.fill(
              child: RegionPager(
                itemBuilder: (context, index) => _HomeSheetPage(
                  key: ValueKey(index),
                  index: index,
                  sharedExtent: _sharedExtent,
                ),
              ),
            ),
            // Region bar overlay, fading transparent as the weather reveals.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: RegionBar(reveal: context.read<HomeBackdropReveal>()),
            ),
          ],
        ),
      ),
    );
  }
}

/// One area's draggable sheet over the shared backdrop. Owns the drag mechanics,
/// mirrors [sharedExtent] so switching never collapses the sheet, and publishes
/// its weather reveal to [HomeBackdropReveal] while it is the active area.
class _HomeSheetPage extends StatefulWidget {
  const _HomeSheetPage({
    super.key,
    required this.index,
    required this.sharedExtent,
  });

  final int index;
  final ValueNotifier<double> sharedExtent;

  @override
  State<_HomeSheetPage> createState() => _HomeSheetPageState();
}

class _HomeSheetPageState extends State<_HomeSheetPage> {
  final DraggableScrollableController _sheet = DraggableScrollableController();
  late final ValueNotifier<double> _extent = ValueNotifier<double>(
    widget.sharedExtent.value,
  );
  AreaSelection? _areas;
  HomeResetSignal? _resetSignal;
  HomeBackdropReveal? _reveal;

  @override
  void initState() {
    super.initState();
    _extent.addListener(_publishReveal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = context.read<HomeResetSignal>();
    if (signal != _resetSignal) {
      _resetSignal?.removeListener(_resetSheet);
      _resetSignal = signal..addListener(_resetSheet);
    }
    final areas = context.read<AreaSelection>();
    if (areas != _areas) {
      _areas?.removeListener(_onSelectionChanged);
      _areas = areas..addListener(_onSelectionChanged);
    }
    _reveal = context.read<HomeBackdropReveal>();
  }

  bool get _isActive => _areas?.selectedIndex == widget.index;

  /// Keeps [HomeBackdropReveal] in step with the active area's sheet.
  void _publishReveal() {
    if (_isActive) _reveal?.value = HomeSheet.weatherReveal(_extent.value);
  }

  /// On becoming visible, adopt the shared height and re-publish the reveal.
  void _onSelectionChanged() {
    _jumpTo(widget.sharedExtent.value);
    _publishReveal();
  }

  void _resetSheet() {
    widget.sharedExtent.value = HomeSheet.restExtent;
    _jumpTo(HomeSheet.restExtent);
  }

  void _jumpTo(double extent) {
    if (!_isActive) return;
    if (!_sheet.isAttached) {
      _extent.value = extent;
      return;
    }
    if ((_sheet.size - extent).abs() < 0.001) return;
    _sheet.jumpTo(extent);
    _extent.value = extent;
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    _extent.value = notification.extent;
    if (_isActive) widget.sharedExtent.value = notification.extent;
    return false;
  }

  /// Snaps the sheet to the nearest detent when a drag ends.
  void _settle() {
    if (!_sheet.isAttached) return;
    final size = _sheet.size;
    final target = size < (HomeSheet.restExtent + HomeSheet.maxExtent) / 2
        ? HomeSheet.restExtent
        : HomeSheet.maxExtent;
    if ((size - target).abs() < 0.001) return;
    _sheet.animateTo(target, duration: AppMotion.medium, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _resetSignal?.removeListener(_resetSheet);
    _areas?.removeListener(_onSelectionChanged);
    _extent.removeListener(_publishReveal);
    _sheet.dispose();
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherMode = context.watch<ExperimentalSettings>().weatherMode;
    return Listener(
      onPointerUp: (_) => _settle(),
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: _onExtentChanged,
        child: DraggableScrollableSheet(
          controller: _sheet,
          initialChildSize: widget.sharedExtent.value,
          minChildSize: HomeSheet.minExtent,
          maxChildSize: HomeSheet.maxExtent,
          builder: (context, scrollController) => HomeSheet(
            scrollController: scrollController,
            extent: _extent,
            weatherMode: weatherMode,
          ),
        ),
      ),
    );
  }
}
