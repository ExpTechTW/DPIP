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
        styleString: "https://demotiles.maplibre.org/style.json", // 替換為可用的樣式URL
      ),
    );
  }

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
    addTileLayer();
  }

  void addTileLayer() {
    // 添加雷達瓦片源
    mapController.addSource(
        "radar-source",
        const RasterSourceProperties(
            tiles: [
              "https://api-1.exptech.dev/api/v1/tiles/radar/{z}/{x}/{y}.png"
            ],
            tileSize: 256));

    // 在地圖上添加圖層以展示雷達數據
    mapController.addLayer(
        "radar-layer",
        "radar-source",
        const RasterLayerProperties());
  }
}