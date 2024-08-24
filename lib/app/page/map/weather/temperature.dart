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

class TemperatureData {
  final double latitude;
  final double longitude;
  final double temperature;
  final String stationName;
  final String county;
  final String town;

  TemperatureData({
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.stationName,
    required this.county,
    required this.town,
  });
}

class TemperatureMap extends StatefulWidget {
  const TemperatureMap({super.key});

  @override
  State<TemperatureMap> createState() => _TemperatureMapState();
}

class _TemperatureMapState extends State<TemperatureMap> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;

  List<TemperatureData> temperatureDataList = [];

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
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
        "temperature-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    weather_list = await ExpTech().getWeatherList();

    List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    temperatureDataList = weatherData
        .where((station) => station.data.air.temperature != -99)
        .map((station) => TemperatureData(
              latitude: station.station.lat,
              longitude: station.station.lng,
              temperature: station.data.air.temperature,
              stationName: station.station.name,
              county: station.station.county,
              town: station.station.town,
            ))
        .toList();

    await addTemperatureCircles(temperatureDataList);

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

  Future<void> addTemperatureCircles(List<TemperatureData> temperatureDataList) async {
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

    await _mapController.setGeoJsonSource("temperature-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("temperature-circles");
    await _mapController.addLayer(
      "temperature-data",
      "temperature-circles",
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
          [Expressions.get, "temperature"],
          -20,
          "#4d4e51",
          -10,
          "#0000FF",
          0,
          "#6495ED",
          10,
          "#95d07e",
          20,
          "#f6e78b",
          30,
          "#FF4500",
          40,
          "#8B0000",
        ],
        circleOpacity: 0.7,
        circleStrokeWidth: 0.2,
        circleStrokeColor: "#000000",
        circleStrokeOpacity: 0.7,
      ),
    );

    await _mapController.removeLayer("temperature-labels");
    await _mapController.addSymbolLayer(
      "temperature-data",
      "temperature-labels",
      const SymbolLayerProperties(
        textField: ['get', 'temperature'],
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

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return MapLegend(
      children: [
        _buildColorBar(),
        const SizedBox(height: 8),
        _buildColorBarLabels(),
        const SizedBox(height: 12),
        Text(context.i18n.unit_degrees_c, style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildColorBar() {
    return Container(
      height: 20,
      width: 300,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        gradient: LinearGradient(
          colors: [
            Color(0xFF4d4e51),
            Color(0xFF0000FF),
            Color(0xFF6495ED),
            Color(0xFF95d07e),
            Color(0xFFf6e78b),
            Color(0xFFFF4500),
            Color(0xFF8B0000),
          ],
          stops: [0.0, 0.1667, 0.3333, 0.5, 0.6667, 0.8333, 1.0],
        ),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = ['-20', '-10', '0', '10', '20', '30', '40'];
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels
            .map((label) => Text(
                  label,
                  style: const TextStyle(fontSize: 12),
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

                temperatureDataList = [];

                temperatureDataList = weatherData
                    .where((station) => station.data.air.temperature != -99)
                    .map((station) => TemperatureData(
                          latitude: station.station.lat,
                          longitude: station.station.lng,
                          temperature: station.data.air.temperature,
                          stationName: station.station.name,
                          county: station.station.county,
                          town: station.station.town,
                        ))
                    .toList();

                await addTemperatureCircles(temperatureDataList);

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
