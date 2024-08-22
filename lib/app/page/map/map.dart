import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/app/page/map/rain/rain.dart';
import 'package:dpip/app/page/map/tsunami/tsunami.dart';
import 'package:dpip/app/page/map/typhoon/typhoon.dart';
import 'package:dpip/app/page/map/weather/humidity.dart';
import 'package:dpip/app/page/map/weather/pressure.dart';
import 'package:dpip/app/page/map/weather/temperature.dart';
import 'package:dpip/app/page/map/weather/wind.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/list/tile_group_header.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/app/page/monitor/monitor.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final controller = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDrawerDestination(
        icon: const Icon(Symbols.monitor_heart),
        selectedIcon: const Icon(Symbols.monitor_heart, fill: 1),
        label: Text(context.i18n.monitor),
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
        icon: Icon(Symbols.temp_preferences_eco_rounded),
        selectedIcon: Icon(Symbols.temp_preferences_eco_rounded, fill: 1),
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
        icon: Icon(Symbols.rainy_light_rounded),
        selectedIcon: Icon(Symbols.rainy_light_rounded, fill: 1),
        label: Text('颱風'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Symbols.tsunami),
        selectedIcon: Icon(Symbols.tsunami, fill: 1),
        label: Text('海嘯資訊'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: destinations[currentIndex].label,
      ),
      drawer: NavigationDrawer(
        selectedIndex: currentIndex,
        children: [
          const ListTileGroupHeader(title: "地圖列表"),
          ...destinations,
        ],
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
          TyphoonMap(),
          TsunamiMap(),
        ],
      ),
    );
  }
}
