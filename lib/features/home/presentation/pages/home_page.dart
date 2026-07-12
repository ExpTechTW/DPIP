import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/area_selection.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
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

/// Home tab — the region bar pinned at the top over a shared map backdrop, with
/// a per-area draggable sheet. A horizontal swipe anywhere pages the whole body
/// (a map tap still opens the full map tab); the sheet's height is **shared**
/// across areas, so switching slides the content without collapsing the sheet.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// The sheet extent shared by every area's sheet, so a switch keeps the sheet
  /// at the same height instead of springing back to rest.
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
        child: Column(
          children: [
            const SafeArea(bottom: false, child: RegionBar()),
            Expanded(
              child: Stack(
                children: [
                  // Shared map backdrop; a tap opens the full map tab.
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => context.goNamed(AppRoutes.map),
                      child: const HomeMapBackdrop(),
                    ),
                  ),
                  // Per-area sheet the pager slides on a switch; each keeps its
                  // own state but adopts the shared height.
                  Positioned.fill(
                    child: RegionPager(
                      itemBuilder: (context, index) => _HomeSheetPage(
                        key: ValueKey(index),
                        index: index,
                        sharedExtent: _sharedExtent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One area's draggable sheet over the shared backdrop. Owns the drag mechanics
/// and mirrors [sharedExtent]: while active it publishes its extent there, and
/// on becoming active it adopts it — so switching areas never collapses the
/// sheet.
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
  }

  bool get _isActive => _areas?.selectedIndex == widget.index;

  /// On becoming the visible area, adopt the shared height (freshly-built pages
  /// already start there via `initialChildSize`).
  void _onSelectionChanged() => _jumpTo(widget.sharedExtent.value);

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
