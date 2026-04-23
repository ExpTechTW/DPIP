/// The new home page providing weather data via [HomeModel].
library;

import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/app/home/_widgets/all_observation_average.dart';
import 'package:dpip/app/home/_widgets/assistant_hint.dart';
import 'package:dpip/app/home/_widgets/day_cycle.dart';
import 'package:dpip/app/home/_widgets/greeting.dart';
import 'package:dpip/app/home/_widgets/location_chip.dart';
import 'package:dpip/app/home/_widgets/radar.dart';
import 'package:dpip/app/home/_widgets/temperature.dart';
import 'package:dpip/app/home/_widgets/weather.dart';
import 'package:dpip/app/home/_widgets/weather_parameters.dart';
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
  HomeModel? _homeModel;

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
      child: RefreshIndicator(
        onRefresh: homeModel.manualRefresh,
        child: ListView(
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
    );
  }

  @override
  void dispose() {
    _homeModel?.dispose();
    super.dispose();
  }
}
