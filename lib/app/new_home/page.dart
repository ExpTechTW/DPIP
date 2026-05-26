/// The new home page providing weather data via [HomeModel].
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/app/new_home/_widgets/assistant_hint.dart';
import 'package:dpip/app/new_home/_widgets/day_cycle.dart';
import 'package:dpip/app/new_home/_widgets/forecast.dart';
import 'package:dpip/app/new_home/_widgets/greeting.dart';
import 'package:dpip/app/new_home/_widgets/location_chip.dart';
import 'package:dpip/app/new_home/_widgets/radar.dart';
import 'package:dpip/app/new_home/_widgets/station_info.dart';
import 'package:dpip/app/new_home/_widgets/temperature.dart';
import 'package:dpip/app/new_home/_widgets/weather.dart';
import 'package:dpip/app/new_home/_widgets/weather_background.dart';
import 'package:dpip/app/new_home/_widgets/wind.dart';
import 'package:dpip/models/settings/location.dart';
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
                StationInfo(),
                Forecast(),
                Wind(),
                DayCycle(),
                Radar(),
              ],
            ),
          ),
        ],
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
