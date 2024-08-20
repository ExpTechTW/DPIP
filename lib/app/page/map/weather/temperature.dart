import 'dart:io';

import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:dpip/global.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/util/map_utils.dart';

class TemperatureData {
  final double latitude;
  final double longitude;
  final double temperature;

  TemperatureData({
    required this.latitude,
    required this.longitude,
    required this.temperature,
  });
}

class TemperatureMap extends StatefulWidget {
  const TemperatureMap({Key? key}) : super(key: key);

  @override
  _TemperatureMapState createState() => _TemperatureMapState();
}

class _TemperatureMapState extends State<TemperatureMap> {
  late MapLibreMapController _mapController;

  List<String> radar_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  Future<void> addTemperaturePoints(MapLibreMapController controller, List<TemperatureData> temperatureDataList) async {
    try {
      // 准备 GeoJSON 数据
      final features = temperatureDataList
          .map((data) => {
                "type": "Feature",
                "properties": {
                  "temperature": data.temperature,
                },
                "geometry": {
                  "type": "Point",
                  "coordinates": [data.longitude, data.latitude]
                }
              })
          .toList();

      // 添加 GeoJSON 源
      await controller.addSource(
        "temperature-data",
        GeojsonSourceProperties(
          data: {
            "type": "FeatureCollection",
            "features": features,
          },
        ),
      );

      // 添加圆形图层
      await controller.addLayer(
        "temperature-data",
        "temperature-points",
        CircleLayerProperties(
            circleRadius: 10,
            circleColor: [
              Expressions.interpolate,
              ["linear"],
              [Expressions.get, "temperature"],
              0, "#0000FF", // 蓝色为冷
              15, "#FFFF00", // 黄色为温和
              30, "#FF0000" // 红色为热
            ],
            circleOpacity: 0.7,
            circleStrokeWidth: 2,
            circleStrokeColor: "#FFFFFF"),
      );

      // 添加温度标签图层
      await controller.addLayer(
        "temperature-data",
        "temperature-labels",
        SymbolLayerProperties(
          textField: [
            Expressions.concat,
            [
              Expressions.round,
              [Expressions.get, "temperature"]
            ],
            "°C"
          ],
          textSize: 12,
          textOffset: [0, 0],
          textAnchor: "center",
          textColor: "#FFFFFF",
          textHaloColor: "#000000",
          textHaloWidth: 1,
        ),
      );

      print("Temperature points added successfully");
    } catch (e) {
      print("Error adding temperature points: $e");
    }
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await _loadMapImages(isDark);

    List<TemperatureData> temperatureDataList = [
      TemperatureData(latitude: 25.0330, longitude: 121.5654, temperature: 25.5),
      TemperatureData(latitude: 24.0330, longitude: 121.5654, temperature: 18.3),
      TemperatureData(latitude: 23.0330, longitude: 121.5654, temperature: 30.1),
    ];

    await addTemperaturePoints(_mapController, temperatureDataList);

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (isUserLocationValid) {
      await _mapController.addSource(
          "markers-geojson", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
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
                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
