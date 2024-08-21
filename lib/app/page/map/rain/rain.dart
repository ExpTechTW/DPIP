import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/weather/rain.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/rain_time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
  String selectedTimestamp = '';
  String selectedInterval = 'now'; // 默認選擇 'now'

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

    if (rainTimeList.isNotEmpty) {
      selectedTimestamp = rainTimeList.last;
      await updateRainData(selectedTimestamp, selectedInterval);
    }

    setState(() {});
  }

  Future<void> updateRainData(String timestamp, String interval) async {
    List<RainStation> rainData = await ExpTech().getRain(timestamp);

    rainDataList = rainData.map((station) {
      double rainfall;
      switch (interval) {
        case 'now':
          rainfall = station.data.now;
          break;
        case '10m':
          rainfall = station.data.tenMinutes;
          break;
        case '1h':
          rainfall = station.data.oneHour;
          break;
        case '3h':
          rainfall = station.data.threeHours;
          break;
        case '6h':
          rainfall = station.data.sixHours;
          break;
        case '12h':
          rainfall = station.data.twelveHours;
          break;
        case '24h':
          rainfall = station.data.twentyFourHours;
          break;
        case '2d':
          rainfall = station.data.twoDays;
          break;
        case '3d':
          rainfall = station.data.threeDays;
          break;
        default:
          rainfall = station.data.now; // 默認使用 'now'
      }
      return RainData(
        latitude: station.station.lat,
        longitude: station.station.lng,
        rainfall: rainfall,
        stationName: station.station.name,
        county: station.station.county,
        town: station.station.town,
      );
    }).toList();

    await addRainCircles(rainDataList);
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
        circleStrokeWidth: 0.2,
        circleStrokeColor: "#000000",
        circleStrokeOpacity: 0.7,
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
              onSelectionChanged: (timestamp, interval) async {
                print('Selected time: $timestamp, interval: $interval');
                selectedTimestamp = timestamp;
                selectedInterval = interval;
                await updateRainData(timestamp, interval);
                setState(() {});
              },
            ),
          ),
      ],
    );
  }
}
