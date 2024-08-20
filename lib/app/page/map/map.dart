import 'dart:async';

import 'package:dpip/app/page/map/tsunami.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../widget/map/map.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapController = Completer<MapLibreMapController>();

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
        return Container();
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
          DpipMap(
            onMapCreated: (controller) async {
              mapController.complete(controller);
              await controller.setSymbolIconAllowOverlap(true);
              await controller.setSymbolIconIgnorePlacement(true);
            },
          ),
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
          _getContent(selected, context),
        ],
      ),
    );
  }
}
