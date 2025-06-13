import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/app_old/page/map/lightning/lightning.dart';
import 'package:dpip/app_old/page/map/radar/radar.dart';
import 'package:dpip/app_old/page/map/tsunami/tsunami.dart';
import 'package:dpip/app_old/page/map/typhoon/typhoon.dart';
import 'package:dpip/app_old/page/map/weather/humidity.dart';
import 'package:dpip/app_old/page/map/weather/pressure.dart';
import 'package:dpip/widgets/list/tile_group_header.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final controller = PageController();
  int currentIndex = 0;

  late final destinations = [
    const NavigationDrawerDestination(
      icon: Icon(Symbols.monitor_heart),
      selectedIcon: Icon(Symbols.monitor_heart, fill: 1),
      label: Text('強震監視器'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.radar_rounded),
      selectedIcon: Icon(Symbols.radar_rounded, fill: 1),
      label: Text('雷達回波'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.rainy_heavy_rounded),
      selectedIcon: Icon(Symbols.rainy_heavy_rounded, fill: 1),
      label: Text('降水'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.thermometer_rounded),
      selectedIcon: Icon(Symbols.thermometer_rounded, fill: 1),
      label: Text('氣溫'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.humidity_percentage_rounded),
      selectedIcon: Icon(Symbols.humidity_percentage_rounded, fill: 1),
      label: Text('濕度'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.blood_pressure_rounded),
      selectedIcon: Icon(Symbols.blood_pressure_rounded, fill: 1),
      label: Text('氣壓'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.wind_power_rounded),
      selectedIcon: Icon(Symbols.wind_power_rounded, fill: 1),
      label: Text('風向/風速'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.bolt_rounded),
      selectedIcon: Icon(Symbols.bolt_rounded, fill: 1),
      label: Text('閃電'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.cyclone_rounded),
      selectedIcon: Icon(Symbols.cyclone_rounded, fill: 1),
      label: Text('颱風'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Symbols.tsunami),
      selectedIcon: Icon(Symbols.tsunami, fill: 1),
      label: Text('海嘯資訊'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: destinations[currentIndex].label),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        children: [const ListTileGroupHeader(title: '地圖列表'), ...destinations],
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
          RadarMap(),
          HumidityMap(),
          PressureMap(),
          LightningMap(),
          TyphoonMap(),
          TsunamiMap(),
        ],
      ),
    );
  }
}
