import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_chrome.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
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

  /// This page's branch index in the shell.
  static const int tabIndex = 0;

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

  /// Refreshes what goes stale on this screen whenever Home reappears — the tab
  /// is opened, or the app returns from the background. The header's weather and
  /// the backdrop's radar frame are the two live things here; the reset signal
  /// already drives the radar (and the sheet), so this adds the weather.
  void _refresh() {
    _resetSignal?.fire();
    context.read<HomeWeatherController>().refresh();
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
    return RefreshOnAppear(
      tabIndex: HomePage.tabIndex,
      onAppear: _refresh,
      child: Scaffold(
        body: RegionSwipeArea(
          child: Stack(
            children: [
              // Shared map backdrop; a tap opens the full map tab framed on the
              // same view (via the camera hand-off). Opaque so the detector is
              // itself the hit target — the backdrop map ignores pointers
              // (display-only), so deferToChild would never see a hit.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final handoff = context.read<MapCameraHandoff>();
                    // Only a current/saved township hands off Home's framing; every
                    // other selection (全國, or 所在地 with no GPS fix) opens the map
                    // on the whole of Taiwan, matching the nav-bar entry.
                    final framesTownship = switch (context
                        .read<RegionStore>()
                        .selected) {
                      CurrentArea(:final code) => code != null,
                      SavedArea() => true,
                      _ => false,
                    };
                    if (framesTownship && handoff.homeBounds != null) {
                      handoff.requestHomeView();
                    } else {
                      handoff.request(BaseMap.taiwanBounds);
                    }
                    context.goNamed(AppRoutes.map);
                  },
                  child: const HomeMapBackdrop(),
                ),
              ),
              // The one weather sheet — full-screen behind the region bar so its
              // weather fills up into (and past) the bar.
              Positioned.fill(
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: _onExtentChanged,
                  child: DraggableScrollableSheet(
                    controller: _sheet,
                    // Built-in velocity-aware snapping between the two detents, so
                    // a flick keeps its momentum and settles up. The old manual
                    // pointer-up settle snapped by position only (no velocity), so
                    // any short drag up sprang back to rest with no inertia.
                    snap: true,
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
              // Region bar overlay — blends into the weather, then dismisses as
              // the rising sheet invades it (Home derives the dials from extent;
              // the bar itself stays feature-agnostic).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: extent,
                  builder: (context, e, _) => RegionBar(
                    blend: HomeChrome.regionBlend(e),
                    dismiss: HomeChrome.regionDismiss(e),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
