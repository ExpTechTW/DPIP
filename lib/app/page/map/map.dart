import 'package:dpip/app/page/map/tsunami.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
        return TsunamiMap();
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
        title: Text("地圖"),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            minMaxZoomPreference: const MinMaxZoomPreference(0, 10),
            initialCameraPosition: const CameraPosition(target: LatLng(23.8, 120.1), zoom: 6),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.topRight,
              child: FloatingActionButton(
                onPressed: () {},
                child: PopupMenuButton<int>(
                  icon: const Icon(Icons.menu),
                  onSelected: (value) {
                    setState(() {
                      selected = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(
                      value: 0,
                      child: ListTile(
                        leading: Icon(Icons.tsunami),
                        title: Text('海嘯資訊'),
                      ),
                    ),
                    const PopupMenuItem<int>(
                      value: 1,
                      child: ListTile(
                        leading: Icon(Icons.radar),
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
