import 'dart:ui' show ImageFilter;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_chrome.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/features/home/presentation/widgets/home_map_backdrop.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
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

  /// Peak blur sigma over the exposed map once the sheet is fully up — matches
  /// the sheet's own frosted blur ([HomeSheet] at full opacity) so the map's
  /// edge crossing under the sheet doesn't read as a hard transition.
  static const double _mapBlurPeak = 24;

  /// Peak dim applied to the same scrim — darkens the exposed map so the
  /// sheet's cards gain contrast against it. The frosted panel itself is normal
  /// content and is never dimmed with it.
  static const double _mapDimPeak = 0.35;

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

  /// Refreshes what goes stale on this screen whenever Home reappears — weather,
  /// active events, and the backdrop radar (via the reset signal).
  void _refresh() {
    _resetSignal?.fire();
    context.read<HomeWeatherController>().refresh();
    context.read<HomeActiveEventsController>().refresh();
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
    final experimental = context.watch<ExperimentalSettings>();
    final skyTimeMode = experimental.skyTimeMode;
    // The station's live reading drives both the look and the continuous
    // channels: the code picks the mode (keyframes/clouds), and the rain/snow
    // intensity + humidity ride along as overrides where the code carries them.
    final data = context.watch<HomeWeatherController>().weather?.data;
    final backdrop = resolveBackdrop(experimental.weatherMode, data);
    final weatherMode = backdrop.mode;
    final rainIntensity = backdrop.rain;
    final snowIntensity = backdrop.snow;
    // Record fields don't promote, so bind the humidity before dividing.
    final humidityPct = backdrop.humidity;
    final humidity = humidityPct == null ? null : humidityPct / 100;
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
                      handoff.requestHomeView(layerId: 'radar');
                    } else {
                      handoff.request(BaseMap.taiwanBounds, layerId: 'radar');
                    }
                    context.goNamed(AppRoutes.map);
                  },
                  child: const HomeMapBackdrop(),
                ),
              ),
              // Blurs and dims the map backdrop as the sheet climbs
              // ([HomeChrome.mapDim]), so the exposed map recedes behind the
              // sheet's frosted chrome and its cards gain contrast. Ignored for
              // pointers so the map tap still passes.
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<double>(
                    valueListenable: extent,
                    builder: (context, extentValue, _) {
                      final t = HomeChrome.mapDim(extentValue);
                      final sigma = t * _mapBlurPeak;
                      final dim = t * _mapDimPeak;
                      // The tree's shape never changes — no SizedBox/ImageFiltered
                      // swap at t=0, which would re-parent the subtree right over
                      // the map platform view at the exact edge the sheet starts
                      // climbing (the same re-parent flash as the sheet's sky).
                      // `enabled` makes the filter a no-op at rest without
                      // touching the tree.
                      return ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: sigma,
                          sigmaY: sigma,
                        ),
                        enabled: t > 0,
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: dim),
                        ),
                      );
                    },
                  ),
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
                      skyTimeMode: skyTimeMode,
                      rainIntensity: rainIntensity,
                      snowIntensity: snowIntensity,
                      humidity: humidity == null ? null : humidity / 100,
                    ),
                  ),
                ),
              ),
              // Region bar overlay — blends into the weather, then dismisses as
              // the rising sheet invades it (Home derives the dials from extent;
              // the bar itself stays feature-agnostic). Both dials sit at 0 for
              // most of the sheet's travel (they only move in its top ~15%), so
              // this selects the pair rather than rebuilding the badge carousel
              // on every tick of the drag.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // The bar sits directly on the raw sky, same as the sheet
                // header — it needs the actual sky colour, not just the
                // weather type, or its badge ink goes near-invisible on a
                // clear night (see `skyIsLightFrom`).
                child: ValueListenableBuilder<Color?>(
                  valueListenable: SkyLutCache.panelAmbient,
                  builder: (context, sky, _) =>
                      Selector<
                        HomeSheetExtent,
                        ({double blend, double dismiss})
                      >(
                        selector: (_, sheetExtent) => (
                          blend: HomeChrome.regionBlend(sheetExtent.value),
                          dismiss: HomeChrome.regionDismiss(sheetExtent.value),
                        ),
                        builder: (context, dials, _) => RegionBar(
                          blend: dials.blend,
                          dismiss: dials.dismiss,
                          skyIsLight: skyIsLightFrom(sky, weatherMode),
                        ),
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

/// Resolves the home backdrop's inputs from the experimental force setting and
/// the station's live reading.
///
/// A forced [forced] mode shows exactly that authored look — the live code's
/// continuous channels (rain/snow intensity, humidity) belong to the
/// real-conditions path only. Otherwise forcing 晴天 while the code says 有雨
/// would render sunny keyframes with rain drops on top. [humidity] stays on the
/// API's 0..100 scale; the sheet divides by 100 when it feeds the sky.
({WeatherMode mode, double? rain, double? snow, int? humidity}) resolveBackdrop(
  WeatherMode forced,
  WeatherRealtimeData? data,
) {
  final live = forced == WeatherMode.auto;
  final code = data?.weatherCode ?? 0;
  return (
    mode: live ? weatherModeFor(code) : forced,
    rain: live ? weatherRainIntensity(code) : null,
    snow: live ? weatherSnowIntensity(code) : null,
    humidity: live ? data?.humidity : null,
  );
}
