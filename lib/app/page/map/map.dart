import "package:dpip/app/page/map/lightning/lightning.dart";
import "package:dpip/app/page/map/monitor/monitor.dart";
import "package:dpip/app/page/map/radar/radar.dart";
import "package:dpip/app/page/map/rain/rain.dart";
import "package:dpip/app/page/map/tsunami/tsunami.dart";
import "package:dpip/app/page/map/typhoon/typhoon.dart";
import "package:dpip/app/page/map/weather/humidity.dart";
import "package:dpip/app/page/map/weather/pressure.dart";
import "package:dpip/app/page/map/weather/temperature.dart";
import "package:dpip/app/page/map/weather/wind.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final controller = PageController();
  int currentIndex = 0;

  late final destinations = [
    NavigationDrawerDestination(
      icon: const Icon(Symbols.monitor_heart),
      selectedIcon: const Icon(Symbols.monitor_heart, fill: 1),
      label: Text(context.i18n.monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.radar_rounded),
      selectedIcon: const Icon(Symbols.radar_rounded, fill: 1),
      label: Text(context.i18n.radar_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.rainy_heavy_rounded),
      selectedIcon: const Icon(Symbols.rainy_heavy_rounded, fill: 1),
      label: Text(context.i18n.precipitation_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.thermometer_rounded),
      selectedIcon: const Icon(Symbols.thermometer_rounded, fill: 1),
      label: Text(context.i18n.temperature_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.humidity_percentage_rounded),
      selectedIcon: const Icon(Symbols.humidity_percentage_rounded, fill: 1),
      label: Text(context.i18n.humidity_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.blood_pressure_rounded),
      selectedIcon: const Icon(Symbols.blood_pressure_rounded, fill: 1),
      label: Text(context.i18n.pressure_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.wind_power_rounded),
      selectedIcon: const Icon(Symbols.wind_power_rounded, fill: 1),
      label: Text(context.i18n.wind_direction_and_speed_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.bolt_rounded),
      selectedIcon: const Icon(Symbols.bolt_rounded, fill: 1),
      label: Text(context.i18n.lightning),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.cyclone_rounded),
      selectedIcon: const Icon(Symbols.cyclone_rounded, fill: 1),
      label: Text(context.i18n.typhoon_monitor),
    ),
    NavigationDrawerDestination(
      icon: const Icon(Symbols.tsunami),
      selectedIcon: const Icon(Symbols.tsunami, fill: 1),
      label: Text(context.i18n.tsunami_info_monitor),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: destinations[currentIndex].label),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        children: [ListTileGroupHeader(title: context.i18n.monitor_list), ...destinations],
        onDestinationSelected: (value) {
          setState(() => currentIndex = value);
          controller.jumpToPage(value);
          Navigator.pop(context);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          MonitorPage(data: 0),
          RadarMap(),
          RainMap(),
          TemperatureMap(),
          HumidityMap(),
          PressureMap(),
          WindMap(),
          LightningMap(),
          TyphoonMap(),
          TsunamiMap(),
        ],
      ),
    );
  }
}
