import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/app/page/map/rain/rain.dart';
import 'package:dpip/app/page/map/tsunami/tsunami.dart';
import 'package:dpip/app/page/map/typhoon/typhoon.dart';
import 'package:dpip/app/page/map/weather/humidity.dart';
import 'package:dpip/app/page/map/weather/pressure.dart';
import 'package:dpip/app/page/map/weather/temperature.dart';
import 'package:dpip/app/page/map/weather/wind.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/app/page/monitor/monitor.dart';

enum DisplayMode {
  tsunami,
  radar,
  temperature,
  wind,
  humidity,
  pressure,
  rain,
  monitor,
  typhoon,
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  DisplayMode selected = DisplayMode.monitor;

  @override
  void initState() {
    super.initState();
  }

  Widget _getContent(DisplayMode mode, context) {
    switch (mode) {
      case DisplayMode.tsunami:
        return const TsunamiMap();
      case DisplayMode.radar:
        return const RadarMap();
      case DisplayMode.temperature:
        return const TemperatureMap();
      case DisplayMode.wind:
        return const WindMap();
      case DisplayMode.humidity:
        return const HumidityMap();
      case DisplayMode.pressure:
        return const PressureMap();
      case DisplayMode.rain:
        return const RainMap();
      case DisplayMode.monitor:
        return const MonitorPage(data: 0);
      case DisplayMode.typhoon:
        return const TyphoonMap();
    }
  }

  String _getTitle(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.tsunami:
        return '海嘯資訊';
      case DisplayMode.radar:
        return '雷達回波';
      case DisplayMode.temperature:
        return '氣溫';
      case DisplayMode.wind:
        return '風向/風速';
      case DisplayMode.humidity:
        return '濕度';
      case DisplayMode.pressure:
        return '氣壓';
      case DisplayMode.rain:
        return '降水';
      case DisplayMode.monitor:
        return '強震監視器';
      case DisplayMode.typhoon:
        return '颱風';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(selected)),
      ),
      body: Stack(
        children: [
          _getContent(selected, context),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Align(
              alignment: Alignment.topRight,
              child: FloatingActionButton.small(
                onPressed: () {},
                child: PopupMenuButton(
                  icon: const Icon(Symbols.menu),
                  onSelected: (value) {
                    setState(() {
                      selected = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: DisplayMode.monitor,
                      child: ListTile(
                        leading: Icon(Symbols.monitor_heart),
                        title: Text('強震監視器'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.radar,
                      child: ListTile(
                        leading: Icon(Symbols.radar),
                        title: Text('雷達回波'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.rain,
                      child: ListTile(
                        leading: Icon(Symbols.rainy_heavy_rounded),
                        title: Text('降水'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.temperature,
                      child: ListTile(
                        leading: Icon(Symbols.temp_preferences_eco_rounded),
                        title: Text('氣溫'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.humidity,
                      child: ListTile(
                        leading: Icon(Symbols.humidity_high_rounded),
                        title: Text('濕度'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.pressure,
                      child: ListTile(
                        leading: Icon(Symbols.blood_pressure_rounded),
                        title: Text('氣壓'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.wind,
                      child: ListTile(
                        leading: Icon(Symbols.wind_power_sharp),
                        title: Text('風向/風速'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.typhoon,
                      child: ListTile(
                        leading: Icon(Symbols.rainy_light_rounded),
                        title: Text('颱風'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: DisplayMode.tsunami,
                      child: ListTile(
                        leading: Icon(Symbols.tsunami),
                        title: Text('海嘯資訊'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
