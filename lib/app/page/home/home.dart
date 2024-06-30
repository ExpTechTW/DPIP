import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MaplibreMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaplibreMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.6978, 120.9605), // 台灣的經緯度
          zoom: 8,
        ),
        styleString: '''
        {
          "version": 8,
          "sources": {
            "radar-source": {
              "type": "raster",
              "tiles": ["https://api-1.exptech.dev/api/v1/tiles/radar/{z}/{x}/{y}.png"],
              "tileSize": 256
            }
          },
          "layers": [
            {
              "id": "background",
              "type": "background",
              "paint": {
                "background-color": "#0d1321"
              }
            },
            {
              "id": "radar-layer",
              "type": "raster",
              "source": "radar-source"
            }
          ]
        }
        ''',
      ),
    );
  }

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
  }
}