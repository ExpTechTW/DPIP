import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
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
        ],
      ),
    );
  }
}
