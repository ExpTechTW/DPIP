import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MapLibreMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: () async {

        },
        minMaxZoomPreference: const MinMaxZoomPreference(
          4,
          10,
        ),
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.6978, 120.9605),
          zoom: 6,
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
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        trackCameraPosition: true,
      ),
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    mapController = controller;
  }
}