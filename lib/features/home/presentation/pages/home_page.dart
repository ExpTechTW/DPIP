import 'package:dpip/app/theme/app_motion.dart';
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
/// (map tap still opens the full map tab); each area keeps its own sheet.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                  // Per-area draggable sheet, slid by the pager on a switch;
                  // each area keeps its own sheet state (keyed by index).
                  Positioned.fill(
                    child: RegionPager(
                      itemBuilder: (context, index) =>
                          _HomeSheetPage(key: ValueKey(index)),
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

/// One area's draggable sheet over the shared backdrop. Owns the drag mechanics:
/// the sheet rests at [HomeSheet.restExtent] and springs there when released, or
/// expands to [HomeSheet.maxExtent].
class _HomeSheetPage extends StatefulWidget {
  const _HomeSheetPage({super.key});

  @override
  State<_HomeSheetPage> createState() => _HomeSheetPageState();
}

class _HomeSheetPageState extends State<_HomeSheetPage> {
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final ValueNotifier<double> _extent = ValueNotifier<double>(
    HomeSheet.restExtent,
  );
  HomeResetSignal? _resetSignal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = context.read<HomeResetSignal>();
    if (signal != _resetSignal) {
      _resetSignal?.removeListener(_resetSheet);
      _resetSignal = signal..addListener(_resetSheet);
    }
  }

  /// Snaps the sheet back to rest (used when the Home tab is re-entered).
  void _resetSheet() {
    if (!_sheet.isAttached) return;
    if ((_sheet.size - HomeSheet.restExtent).abs() < 0.001) return;
    _sheet.jumpTo(HomeSheet.restExtent);
    _extent.value = HomeSheet.restExtent;
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    _extent.value = notification.extent;
    return false;
  }

  /// Snaps the sheet to the nearest detent when a drag ends: down to
  /// [HomeSheet.restExtent] (spring-back) or up to [HomeSheet.maxExtent].
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
          initialChildSize: HomeSheet.restExtent,
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
