import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Home tab — a single draggable weather sheet over a shared map backdrop, with
/// the region bar pinned on top.
///
/// One sheet serves every area: switching areas slides only the sheet's
/// *content* (see `HomeContent`), never the sheet itself, so the sheet height
/// and the immersive chrome ([HomeSheetExtent]) can't be reset by a switch. A
/// swipe anywhere pages the area (`RegionSwipeArea`); a tap on the exposed map
/// opens the full map tab.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DraggableScrollableController _sheet = DraggableScrollableController();
  HomeSheetExtent? _extent;
  HomeResetSignal? _resetSignal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extent = context.read<HomeSheetExtent>();
    final signal = context.read<HomeResetSignal>();
    if (signal != _resetSignal) {
      _resetSignal?.removeListener(_resetSheet);
      _resetSignal = signal..addListener(_resetSheet);
    }
  }

  /// Publishes the live extent so the chrome (region bar + bottom nav) can
  /// choreograph its dismissal off it — the single source of truth.
  bool _onExtentChanged(DraggableScrollableNotification notification) {
    _extent?.value = notification.extent;
    return false;
  }

  /// Snaps to the nearest detent (rest or full) when a drag ends.
  void _settle() {
    if (!_sheet.isAttached) return;
    final size = _sheet.size;
    final target = size < (HomeSheet.restExtent + HomeSheet.maxExtent) / 2
        ? HomeSheet.restExtent
        : HomeSheet.maxExtent;
    if ((size - target).abs() < 0.001) return;
    _sheet.animateTo(target, duration: AppMotion.medium, curve: Curves.easeOut);
  }

  /// Collapses the sheet to rest whenever Home is (re-)entered, so an expanded,
  /// chrome-hidden sheet never strands a fresh visitor with no visible nav.
  void _resetSheet() {
    if (_sheet.isAttached) {
      _sheet.jumpTo(HomeSheet.restExtent);
    } else {
      _extent?.value = HomeSheet.restExtent;
    }
  }

  @override
  void dispose() {
    _resetSignal?.removeListener(_resetSheet);
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherMode = context.watch<ExperimentalSettings>().weatherMode;
    final extent = context.read<HomeSheetExtent>();
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
            // The one weather sheet — full-screen behind the region bar so its
            // weather fills up into (and past) the bar.
            Positioned.fill(
              child: Listener(
                onPointerUp: (_) => _settle(),
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: _onExtentChanged,
                  child: DraggableScrollableSheet(
                    controller: _sheet,
                    // Floor = rest: the sheet is never smaller than its default.
                    initialChildSize: HomeSheet.restExtent,
                    minChildSize: HomeSheet.restExtent,
                    maxChildSize: HomeSheet.maxExtent,
                    builder: (context, scrollController) => HomeSheet(
                      scrollController: scrollController,
                      extent: extent,
                      weatherMode: weatherMode,
                    ),
                  ),
                ),
              ),
            ),
            // Region bar overlay — blends into the weather, then dismisses as
            // the rising sheet invades it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: RegionBar(sheetExtent: extent),
            ),
          ],
        ),
      ),
    );
  }
}
