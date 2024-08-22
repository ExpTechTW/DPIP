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
  const RainMap({super.key});

  @override
  State<RainMap> createState() => _RainMapState();
}

class _RainMapState extends State<RainMap> {
  late MapLibreMapController _mapController;

  List<String> rainTimeList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;

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

    await _mapController.addSource(
        "rain-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    rainTimeList = await ExpTech().getRainList();

    if (rainTimeList.isNotEmpty) {
      selectedTimestamp = rainTimeList.last;
      await updateRainData(selectedTimestamp, selectedInterval);
    }

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
          "#c2c2c2",
          10,
          "#9cfcff",
          30,
          "#059bff",
          50,
          "#39ff03",
          100,
          "#fffb03",
          200,
          "#ff9500",
          300,
          "#ff0000",
          500,
          "#fb00ff",
          1000,
          "#960099",
          2000,
          "#000000"
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

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('降水量圖例', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildColorBar(),
          const SizedBox(height: 8),
          _buildColorBarLabels(),
          const SizedBox(height: 12),
          Text('單位：毫米 (mm)', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildColorBar() {
    return Container(
      height: 20,
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFC2C2C2),
            Color(0xFF9CFCFF),
            Color(0xFF059BFF),
            Color(0xFF39FF03),
            Color(0xFFFFFB03),
            Color(0xFFFF9500),
            Color(0xFFFF0000),
            Color(0xFFFB00FF),
            Color(0xFF960099),
            Color(0xFF000000),
          ],
          stops: [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = ['0', '10', '30', '50', '100', '200', '300', '500', '1000', '2000+'];
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map((label) => Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                ))
            .toList(),
      ),
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
        Positioned(
          left: 4,
          bottom: 4,
          child: Material(
            color: Theme.of(context).colorScheme.secondary,
            elevation: 4.0,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggleLegend,
              child: Tooltip(
                message: '圖例',
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: Icon(
                    _showLegend ? Icons.close : Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (rainTimeList.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: rainTimeList,
              onTimeExpanded: () {
                _showLegend = false;
                setState(() {});
              },
              onSelectionChanged: (timestamp, interval) async {
                print('Selected time: $timestamp, interval: $interval');
                selectedTimestamp = timestamp;
                selectedInterval = interval;
                await updateRainData(timestamp, interval);
                await _addUserLocationMarker();
                setState(() {});
              },
            ),
          ),
        if (_showLegend)
          Positioned(
            left: 6,
            bottom: 50, // Adjusted to be above the legend button
            child: _buildLegend(),
          ),
      ],
    );
  }
}
