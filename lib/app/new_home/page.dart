/// The new home page — a concise weather + alerts + events dashboard.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/app/new_home/_models/weather_params.dart';
import 'package:dpip/app/new_home/_widgets/assistant_hint.dart';
import 'package:dpip/app/new_home/_widgets/day_cycle.dart';
import 'package:dpip/app/new_home/_widgets/eew_alert.dart';
import 'package:dpip/app/new_home/_widgets/events_timeline.dart';
import 'package:dpip/app/new_home/_widgets/forecast.dart';
import 'package:dpip/app/new_home/_widgets/greeting.dart';
import 'package:dpip/app/new_home/_widgets/location_chip.dart';
import 'package:dpip/app/new_home/_widgets/radar.dart';
import 'package:dpip/app/new_home/_widgets/station_info.dart';
import 'package:dpip/app/new_home/_widgets/temperature.dart';
import 'package:dpip/app/new_home/_widgets/thunderstorm_alert.dart';
import 'package:dpip/app/new_home/_widgets/weather.dart';
import 'package:dpip/app/new_home/_widgets/weather_background.dart';
import 'package:dpip/app/new_home/_widgets/weather_particles.dart';
import 'package:dpip/app/new_home/_widgets/wind.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The main home page widget.
///
/// Lazily creates a [HomeModel] on first dependency resolution, provides it to
/// all child widgets, supports pull-to-refresh, and automatically refreshes
/// weather data every 30 minutes. The page mirrors the original home's hero +
/// alerts + events flow with a modern shader + particle weather background.
class NewHomePage extends StatefulWidget {
  /// Creates a [NewHomePage].
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final _scrollOffset = ValueNotifier<double>(0);
  final _scrollController = ScrollController();
  HomeModel? _homeModel;

  void _onScroll() => _scrollOffset.value = _scrollController.offset;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _homeModel ??= HomeModel(context.read<SettingsLocationModel>())..startAutoRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final homeModel = _homeModel!;

    return ChangeNotifierProvider.value(
      value: homeModel,
      child: Selector<HomeModel, ({int scene, double cloud, double rain})>(
        selector: (_, m) {
          final d = m.weather?.data;
          return (
            scene: resolveSkyScene(DateTime.now().hour),
            cloud: cloudWeight(d),
            rain: rainWeight(d),
          );
        },
        builder: (context, params, _) {
          final colorScheme = ColorScheme.fromSeed(
            seedColor: _seedColor(params.scene, params.cloud, params.rain),
            brightness: context.theme.brightness,
          );

          return AnimatedTheme(
            duration: const Duration(milliseconds: 600),
            data: context.theme.copyWith(
              colorScheme: colorScheme,
              cardTheme: CardThemeData(
                color: colorScheme.surface / 95,
              ),
            ),
            child: Stack(
              children: [
                // Layered weather background: shader sky + animated particles.
                Positioned.fill(child: WeatherBackground(scrollOffset: _scrollOffset)),
                const Positioned.fill(child: WeatherParticles()),
                RefreshIndicator(
                  onRefresh: homeModel.manualRefresh,
                  child: ListView(
                    controller: _scrollController,
                    children: const [
                      Greeting(),
                      LocationChip(),
                      SizedBox(height: 8),
                      // Critical alerts surface first.
                      EewAlerts(),
                      ThunderstormAlert(),
                      SizedBox(height: 8),
                      // Weather hero.
                      Temperature(),
                      Weather(),
                      SizedBox(height: 16),
                      // Detail cards.
                      AssistantHint(),
                      StationInfo(),
                      Forecast(),
                      Wind(),
                      DayCycle(),
                      SizedBox(height: 16),
                      // Radar preview - 1 tap to full map.
                      Radar(),
                      // Events timeline - the originally-missing list.
                      EventsTimeline(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _scrollOffset.dispose();
    _homeModel?.dispose();
    super.dispose();
  }
}

Color _seedColor(int scene, double cloud, double rain) {
  final base = switch (scene) {
    1 => const Color(0xFF1A237E),
    2 => const Color(0xFF6A1B9A),
    3 => const Color(0xFFC62828),
    _ => const Color(0xFF1565C0),
  };
  if (rain > 0.4) {
    return Color.lerp(base, const Color(0xFF263238), ((rain - 0.4) * 1.2).clamp(0.0, 0.7))!;
  }
  if (cloud > 0.5) {
    return Color.lerp(base, const Color(0xFF546E7A), (cloud - 0.5) * 0.5)!;
  }
  return base;
}
