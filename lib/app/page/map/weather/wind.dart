import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/weather/weather.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/legend.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class WindData {
  final double latitude;
  final double longitude;
  final int direction;
  final double speed;

  WindData({
    required this.latitude,
    required this.longitude,
    required this.direction,
    required this.speed,
  });
}

class WindMap extends StatefulWidget {
  const WindMap({super.key});

  @override
  State<WindMap> createState() => _WindMapState();
}

class _WindMapState extends State<WindMap> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;

  List<WindData> windDataList = [];

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
    await loadWindImage(_mapController);
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  void _loadMap() async {
    final isDark = context.theme.brightness == Brightness.dark;

    await _loadMapImages(isDark);

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    await _mapController.addSource(
        "wind-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    weather_list = await ExpTech().getWeatherList();

    List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    windDataList = weatherData
        .where((station) => station.data.wind.direction != -99 && station.data.wind.speed != -99)
        .map((station) => WindData(
            latitude: station.station.lat,
            longitude: station.station.lng,
            direction: (station.data.wind.direction + 180) % 360,
            speed: station.data.wind.speed))
        .toList();

    await addDynamicWindArrows(windDataList);

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
      final cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(userLat, userLon), 8);
      await _mapController.animateCamera(cameraUpdate, duration: const Duration(milliseconds: 1000));
    }

    await _addUserLocationMarker();

    setState(() {});
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

  Future<void> addDynamicWindArrows(List<WindData> windDataList) async {
    final features = windDataList
        .map((data) => {
              "type": "Feature",
              "properties": {
                "direction": data.direction,
                "speed": data.speed,
              },
              "geometry": {
                "type": "Point",
                "coordinates": [data.longitude, data.latitude]
              }
            })
        .toList();

    await _mapController.setGeoJsonSource("wind-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("wind-circles");
    await _mapController.addLayer(
      "wind-data",
      "wind-circles",
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
        ['get', 'speed'],
        0
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer("wind-speed-0-labels");
    await _mapController.addSymbolLayer(
      "wind-data",
      "wind-speed-0-labels",
      const SymbolLayerProperties(
        textField: [
          Expressions.format,
          ['get', 'speed']
        ],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 2,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
      ),
      filter: [
        '==',
        ['get', 'speed'],
        0
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer("wind-arrows");
    await _mapController.addLayer(
      "wind-data",
      "wind-arrows",
      const SymbolLayerProperties(
        iconSize: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          5,
          0.4,
          10,
          1.2,
        ],
        iconImage: [
          Expressions.step,
          [Expressions.get, "speed"],
          "wind-1",
          3.4,
          "wind-2",
          8,
          "wind-3",
          13.9,
          "wind-4",
          32.7,
          "wind-5"
        ],
        iconRotate: [Expressions.get, "direction"],
        textAllowOverlap: true,
        iconAllowOverlap: true,
      ),
      filter: [
        '!=',
        ['get', 'speed'],
        0
      ],
    );

    await _mapController.removeLayer("wind-speed-labels");
    await _mapController.addSymbolLayer(
      "wind-data",
      "wind-speed-labels",
      const SymbolLayerProperties(
        textField: [
          Expressions.format,
          ['get', 'speed']
        ],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 2,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2]
        ],
      ),
      filter: [
        '!=',
        ['get', 'speed'],
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
    return MapLegend(
      children: [
        _legendItem('wind-1', '0.1 - 3.3 m/s'),
        _legendItem('wind-2', '3.4 - 7.9 m/s'),
        _legendItem('wind-3', '8.0 - 13.8 m/s'),
        _legendItem('wind-4', '13.9 - 32.6 m/s'),
        _legendItem('wind-5', '≥ 32.7 m/s'),
      ],
    );
  }

  Widget _legendItem(String imageName, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset('assets/map/icons/$imageName.png', width: 24, height: 24),
          const SizedBox(width: 8),
          Text(label),
        ],
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
            color: context.colors.secondary,
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
                    color: context.colors.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (weather_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: weather_list,
              onTimeExpanded: () {
                _showLegend = false;
                setState(() {});
              },
              onTimeSelected: (time) async {
                List<WeatherStation> weatherData = await ExpTech().getWeather(time);

                windDataList = [];

                windDataList = weatherData
                    .where((station) => station.data.wind.direction != -99 && station.data.wind.speed != -99)
                    .map((station) => WindData(
                        latitude: station.station.lat,
                        longitude: station.station.lng,
                        direction: (station.data.wind.direction + 180) % 360,
                        speed: station.data.wind.speed))
                    .toList();

                await addDynamicWindArrows(windDataList);
                await _addUserLocationMarker();
                setState(() {});
                print("Selected time: $time");
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
