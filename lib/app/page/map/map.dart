import 'package:dpip/app/page/map/radar/radar.dart';
import 'package:dpip/app/page/map/tsunami/tsunami.dart';
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
        return RadarMap();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("地圖"),
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
