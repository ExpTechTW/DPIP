import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({Key? key}) : super(key: key);

  @override
  _RadarMapState createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  late MapLibreMapController _mapController;

  List<String> radar_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  String getTileUrl(String timestamp) {
    return "https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png";
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _addUserLocationMarker() async {
    if (isUserLocationValid) {
      await _mapController.removeLayer("markers");
      await _mapController.addLayer(
        "markers-geojson",
        "markers",
        const SymbolLayerProperties(
          symbolZOrder: "source",
          iconSize: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.5,
          ],
          iconImage: "gps",
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    }
  }

  void _loadMap() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await _loadMapImages(isDark);

    radar_list = await ExpTech().getRadarList();

    String newTileUrl = getTileUrl(radar_list.last);

    _mapController.addSource(
        "radarSource",
        RasterSourceProperties(
          tiles: [newTileUrl],
          tileSize: 256,
        ));

    _mapController.addLayer("radarSource", "radarLayer", const RasterLayerProperties());

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (isUserLocationValid) {
      await _mapController.addSource(
          "markers-geojson", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
      await _mapController.setGeoJsonSource(
        "markers-geojson",
        {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {},
              "geometry": {
                "coordinates": [userLon, userLat],
                "type": "Point"
              }
            }
          ],
        },
      );
    }

    _addUserLocationMarker();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(
          onMapCreated: _initMap,
          onStyleLoadedCallback: _loadMap,
        ),
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

                _addUserLocationMarker();

                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
