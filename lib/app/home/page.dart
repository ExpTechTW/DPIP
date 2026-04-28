/// The new home page providing weather data via [HomeModel].
library;

import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/app/home/_models/weather_params.dart';
import 'package:dpip/app/home/_widgets/all_observation_average.dart';
import 'package:dpip/app/home/_widgets/assistant_hint.dart';
import 'package:dpip/app/home/_widgets/day_cycle.dart';
import 'package:dpip/app/home/_widgets/greeting.dart';
import 'package:dpip/app/home/_widgets/location_chip.dart';
import 'package:dpip/app/home/_widgets/radar.dart';
import 'package:dpip/app/home/_widgets/temperature.dart';
import 'package:dpip/app/home/_widgets/weather.dart';
import 'package:dpip/app/home/_widgets/weather_background.dart';
import 'package:dpip/app/home/_widgets/weather_parameters.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The main home page widget.
///
/// Lazily creates a [HomeModel] on first dependency resolution, provides it to
/// all child widgets, supports pull-to-refresh, and automatically refreshes
/// weather data every 30 minutes.
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
                Positioned.fill(child: WeatherBackground(scrollOffset: _scrollOffset)),
                RefreshIndicator(
                  onRefresh: homeModel.manualRefresh,
                  child: ListView(
                    controller: _scrollController,
                    children: const [
                      Greeting(),
                      LocationChip(),
                      SizedBox(height: 16),
                      Temperature(),
                      Weather(),
                      SizedBox(height: 16),
                      AssistantHint(),
                      AllObservationAverage(),
                      WeatherParameters(),
                      DayCycle(),
                      Radar(),
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
