import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/app/page/map/tsunami/tsunami.dart';
import 'package:dpip/app/page/map/weather/humidity.dart';
import 'package:dpip/app/page/map/weather/pressure.dart';
import 'package:dpip/app/page/map/weather/rain.dart';
import 'package:dpip/app/page/map/weather/temperature.dart';
import 'package:dpip/app/page/map/weather/wind.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int selected = 0;

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
      default:
        return const RainMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.map),
      ),
      body: Stack(
        children: [
          _getContent(selected, context),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.topRight,
              child: FloatingActionButton(
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
                      value: 0,
                      child: ListTile(
                        leading: Icon(Symbols.tsunami),
                        title: Text('海嘯資訊'),
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
                      value: 2,
                      child: ListTile(
                        leading: Icon(Symbols.temp_preferences_eco_rounded),
                        title: Text('氣溫'),
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
                      value: 6,
                      child: ListTile(
                        leading: Icon(Symbols.rainy_heavy_rounded),
                        title: Text('降水'),
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
