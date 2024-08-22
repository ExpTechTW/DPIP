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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selected = 7;

  @override
  void initState() {
    super.initState();
  }

  Widget _getContent(int value, context) {
    switch (value) {
      case 0:
        return const TsunamiMap();
      case 1:
        return const RadarMap();
      case 2:
        return const TemperatureMap();
      case 3:
        return const WindMap();
      case 4:
        return const HumidityMap();
      case 5:
        return const PressureMap();
      case 6:
        return const RainMap();
      case 7:
        return const MonitorPage(data: 0);
      default:
        return const TyphoonMap();
    }
  }

  String _getTitle(int value) {
    switch (value) {
      case 0:
        return '海嘯資訊';
      case 1:
        return '雷達回波';
      case 2:
        return '氣溫';
      case 3:
        return '風向/風速';
      case 4:
        return '濕度';
      case 5:
        return '氣壓';
      case 6:
        return '降水';
      case 7:
        return '強震監視器';
      default:
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
                child: PopupMenuButton<int>(
                  icon: const Icon(Symbols.menu),
                  onSelected: (value) {
                    setState(() {
                      selected = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(
                      value: 7,
                      child: ListTile(
                        leading: Icon(Symbols.monitor_heart),
                        title: Text('強震監視器'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 1,
                      child: ListTile(
                        leading: Icon(Symbols.radar),
                        title: Text('雷達回波'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 6,
                      child: ListTile(
                        leading: Icon(Symbols.rainy_heavy_rounded),
                        title: Text('降水'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 2,
                      child: ListTile(
                        leading: Icon(Symbols.temp_preferences_eco_rounded),
                        title: Text('氣溫'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 4,
                      child: ListTile(
                        leading: Icon(Symbols.humidity_high_rounded),
                        title: Text('濕度'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 5,
                      child: ListTile(
                        leading: Icon(Symbols.blood_pressure_rounded),
                        title: Text('氣壓'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 3,
                      child: ListTile(
                        leading: Icon(Symbols.wind_power_sharp),
                        title: Text('風向/風速'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 8,
                      child: ListTile(
                        leading: Icon(Symbols.rainy_light_rounded),
                        title: Text('颱風'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 0,
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
