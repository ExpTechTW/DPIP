import 'dart:io';

import 'package:dpip/model/weather/weather.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:dpip/global.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/api/exptech.dart';

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
  const WindMap({Key? key}) : super(key: key);

  @override
  _WindMapState createState() => _WindMapState();
}

class _WindMapState extends State<WindMap> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  List<WindData> windDataList = [];

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
    await loadWindImage(_mapController);
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

    weather_list = await ExpTech().getWeatherList();

    List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    windDataList.addAll(weatherData.map((station) {
      return WindData(
          latitude: station.station.lat,
          longitude: station.station.lng,
          direction: (station.data.wind.direction + 180) % 360,
          speed: station.data.wind.speed);
    }));

    await addDynamicWindArrows(windDataList);
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

    await _mapController.addSource(
        "wind-data", GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": features}));

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
          "wind-low",
          5,
          "wind-middle",
          10,
          "wind-high"
        ],
        iconRotate: [Expressions.get, "direction"],
        textAllowOverlap: true,
        iconAllowOverlap: true,
      ),
    );

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
      minzoom: 8,
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
        if (weather_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: weather_list,
              onTimeSelected: (time) async {
                List<WeatherStation> weatherData = await ExpTech().getWeather(time);

                windDataList = [];

                windDataList.addAll(weatherData.map((station) {
                  return WindData(
                      latitude: station.station.lat,
                      longitude: station.station.lng,
                      direction: station.data.wind.direction,
                      speed: station.data.wind.speed);
                }));

                await addDynamicWindArrows(windDataList);
                setState(() {});
                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
