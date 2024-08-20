import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/api/exptech.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({Key? key}) : super(key: key);

  @override
  _RadarMapState createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  late MapLibreMapController _mapController;

  List<String> radar_list = [];

  String getTileUrl(String timestamp) {
    return "https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png";
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;

    radar_list = await ExpTech().getRadarList();

    String newTileUrl = getTileUrl(radar_list.last);

    _mapController.addSource(
        "radarSource",
        RasterSourceProperties(
          tiles: [newTileUrl],
          tileSize: 256,
        ));

    _mapController.addLayer("radarSource", "radarLayer", const RasterLayerProperties());

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(onMapCreated: _initMap),
        if (radar_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: radar_list,
              onTimeSelected: (time) {
                String newTileUrl = getTileUrl(time);

                _mapController.removeLayer("radarLayer");
                _mapController.removeSource("radarSource");

                _mapController.addSource(
                    "radarSource",
                    RasterSourceProperties(
                      tiles: [newTileUrl],
                      tileSize: 256,
                    ));

                _mapController.addLayer("radarSource", "radarLayer", const RasterLayerProperties());

                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
