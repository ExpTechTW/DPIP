import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(23.8, 120.8),
          initialZoom: 7,
          minZoom: 7,
          maxZoom: 12,
          backgroundColor: Colors.transparent,
        ),
        children: [
          TileLayer(
            urlTemplate: "http://api-1.exptech.dev/api/v1/tiles/radar/{z}/{x}/{y}.png",
            userAgentPackageName: "tw.com.exptech.dpip",
          )
        ],
      ),
    );
  }
}
