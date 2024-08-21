import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/weather/weather.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/list/time_selector.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class PressureData {
  final double latitude;
  final double longitude;
  final double pressure;
  final String stationName;
  final String county;
  final String town;

  PressureData({
    required this.latitude,
    required this.longitude,
    required this.pressure,
    required this.stationName,
    required this.county,
    required this.town,
  });
}

class PressureMap extends StatefulWidget {
  const PressureMap({Key? key}) : super(key: key);

  @override
  _PressureMapState createState() => _PressureMapState();
}

class _PressureMapState extends State<PressureMap> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  List<PressureData> pressureDataList = [];

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
        "pressure-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    weather_list = await ExpTech().getWeatherList();

    List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    pressureDataList = weatherData
        .where((station) => station.data.air.pressure != -99)
        .map((station) => PressureData(
              latitude: station.station.lat,
              longitude: station.station.lng,
              pressure: station.data.air.pressure,
              stationName: station.station.name,
              county: station.station.county,
              town: station.station.town,
            ))
        .toList();

    await addPressureCircles(pressureDataList);
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

  Future<void> addPressureCircles(List<PressureData> pressureDataList) async {
    final features = pressureDataList
        .map((data) => {
              "type": "Feature",
              "properties": {
                "pressure": data.pressure,
              },
              "geometry": {
                "type": "Point",
                "coordinates": [data.longitude, data.latitude]
              }
            })
        .toList();

    await _mapController.setGeoJsonSource("pressure-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("pressure-circles");
    await _mapController.addLayer(
      "pressure-data",
      "pressure-circles",
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
          [Expressions.get, "pressure"],
          950,
          "#0000FF",
          980,
          "#00FF00",
          1000,
          "#FFFF00",
          1020,
          "#FFA500",
          1050,
          "#FF0000",
        ],
        circleOpacity: 0.7,
        circleStrokeWidth: 0.2,
        circleStrokeColor: "#000000",
        circleStrokeOpacity: 0.7,
      ),
    );

    await _mapController.removeLayer("pressure-labels");
    await _mapController.addSymbolLayer(
      "pressure-data",
      "pressure-labels",
      const SymbolLayerProperties(
        textField: ['get', 'pressure'],
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
        if (weather_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: weather_list,
              onTimeSelected: (time) async {
                List<WeatherStation> weatherData = await ExpTech().getWeather(time);

                pressureDataList = [];

                pressureDataList = weatherData
                    .where((station) => station.data.air.pressure != -99)
                    .map((station) => PressureData(
                          latitude: station.station.lat,
                          longitude: station.station.lng,
                          pressure: station.data.air.pressure,
                          stationName: station.station.name,
                          county: station.station.county,
                          town: station.station.town,
                        ))
                    .toList();

                await addPressureCircles(pressureDataList);
                setState(() {});
                print("Selected time: $time");
              },
            ),
          ),
      ],
    );
  }
}
