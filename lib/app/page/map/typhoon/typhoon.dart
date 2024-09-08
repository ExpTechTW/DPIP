import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/log.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/typhoon_time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TyphoonMap extends StatefulWidget {
  const TyphoonMap({super.key});

  @override
  State<TyphoonMap> createState() => _TyphoonMapState();
}

class _TyphoonMapState extends State<TyphoonMap> {
  late MapLibreMapController _mapController;
  List typhoonImagesList = [];
  Map<String, dynamic> typhoonData = {};
  List<String> typhoonList = [];
  int selectedTyphoonId = -1;
  List<String> sourceList = [];
  List<String> layerList = [];
  List<String> typhoon_name_list = [];
  List<int> typhoon_id_list = [];
  String selectedTimestamp = "";
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _loadMap() async {
    try {
      typhoonImagesList = await ExpTech().getTyphoonImagesList();
      typhoonData = await ExpTech().getTyphoonGeojson();

      if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
        await getSavedLocation();
      }
      userLat = Global.preference.getDouble("user-lat") ?? 0.0;
      userLon = Global.preference.getDouble("user-lon") ?? 0.0;

      isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

      await loadGPSImage(_mapController);

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

      await _addUserLocationMarker();

      setState(() {});
    } catch (e) {
      TalkerManager.instance.error("加載颱風列表時出錯: $e");
    }
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(
          onMapCreated: _initMap,
          onStyleLoadedCallback: _loadMap,
          minMaxZoomPreference: const MinMaxZoomPreference(3, 12),
        ),
      ],
    );
  }
}
