import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/model/weather/rain.dart';

class RainData {
  final double latitude;
  final double longitude;
  final double rainfall;
  final String stationName;
  final String county;
  final String town;

  RainData({
    required this.latitude,
    required this.longitude,
    required this.rainfall,
    required this.stationName,
    required this.county,
    required this.town,
  });
}

class RainMap extends StatefulWidget {
  const RainMap({Key? key}) : super(key: key);

  @override
  _RainMapState createState() => _RainMapState();
}

class _RainMapState extends State<RainMap> {
  late MapLibreMapController _mapController;

  List<String> rainTimeList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  List<RainData> rainDataList = [];

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  void _loadMap() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await _loadMapImages(isDark);

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (isUserLocationValid) {
      await _addUserLocationMarker();
    }

    await _mapController.addSource(
        "rain-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    rainTimeList = await ExpTech().getRainList();

    List<RainStation> rainData = await ExpTech().getRain(rainTimeList.last);

    rainDataList = rainData
        .map((station) => RainData(
              latitude: station.station.lat,
              longitude: station.station.lng,
              rainfall: station.data.twentyFourHours,
              stationName: station.station.name,
              county: station.station.county,
              town: station.station.town,
            ))
        .toList();

    await addRainCircles(rainDataList);
    setState(() {});
  }

  Future<void> _addUserLocationMarker() async {
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

  Future<void> addRainCircles(List<RainData> rainDataList) async {
    final features = rainDataList
        .map((data) => {
              "type": "Feature",
              "properties": {
                "rainfall": data.rainfall,
              },
              "geometry": {
                "type": "Point",
                "coordinates": [data.longitude, data.latitude]
              }
            })
        .toList();

    await _mapController.setGeoJsonSource("rain-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("rain-0-circles");
    await _mapController.addLayer(
      "rain-data",
      "rain-0-circles",
      const CircleLayerProperties(
        circleRadius: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          5,
          3,
          10,
          6,
        ],
        circleColor: "#808080",
        circleStrokeWidth: 0.8,
        circleStrokeColor: "#FFFFFF",
      ),
      filter: [
        '==',
        ['get', 'rainfall'],
        0
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer("rain-0-labels");
    await _mapController.addSymbolLayer(
      "rain-data",
      "rain-0-labels",
      const SymbolLayerProperties(
        textField: ['get', 'rainfall'],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 1,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
      ),
      filter: [
        '==',
        ['get', 'rainfall'],
        0
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer("rain-circles");
    await _mapController.addLayer(
      "rain-data",
      "rain-circles",
      const CircleLayerProperties(
        circleRadius: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          7,
          5,
          12,
          15,
        ],
        circleColor: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.get, "rainfall"],
          0,
          "#FFFFFF",
          10,
          "#AAAAFF",
          50,
          "#5555FF",
          100,
          "#0000FF",
          200,
          "#FF00FF",
        ],
        circleOpacity: 0.7,
      ),
      filter: [
        '!=',
        ['get', 'rainfall'],
        0
      ],
    );

    await _mapController.removeLayer("rain-labels");
    await _mapController.addSymbolLayer(
      "rain-data",
      "rain-labels",
      const SymbolLayerProperties(
        textField: ['get', 'rainfall'],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 1,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
      ),
      filter: [
        '!=',
        ['get', 'rainfall'],
        0
      ],
      minzoom: 9,
    );
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
        if (rainTimeList.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: rainTimeList,
              onTimeSelected: (time) async {
                List<RainStation> rainData = await ExpTech().getRain(time);

                rainDataList = rainData
                    .map((station) => RainData(
                          latitude: station.station.lat,
                          longitude: station.station.lng,
                          rainfall: station.data.twentyFourHours,
                          stationName: station.station.name,
                          county: station.station.county,
                          town: station.station.town,
                        ))
                    .toList();

                await addRainCircles(rainDataList);
                setState(() {});
                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
