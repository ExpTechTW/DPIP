import "dart:io";

import "package:dpip/api/exptech.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/model/weather/weather.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/map_utils.dart";
import "package:dpip/widget/list/time_selector.dart";
import "package:dpip/widget/map/legend.dart";
import "package:dpip/widget/map/map.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";

class HumidityData {
  final double latitude;
  final double longitude;
  final int humidity;
  final String stationName;
  final String county;
  final String town;

  HumidityData({
    required this.latitude,
    required this.longitude,
    required this.humidity,
    required this.stationName,
    required this.county,
    required this.town,
  });
}

class HumidityMap extends StatefulWidget {
  const HumidityMap({super.key});

  @override
  State<HumidityMap> createState() => _HumidityMapState();
}

class _HumidityMapState extends State<HumidityMap> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;

  List<HumidityData> humidityDataList = [];

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
        "humidity-data", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

    weather_list = await ExpTech().getWeatherList();

    List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    humidityDataList = weatherData
        .where((station) => station.data.air.relative_humidity != -99)
        .map((station) => HumidityData(
              latitude: station.station.lat,
              longitude: station.station.lng,
              humidity: station.data.air.relative_humidity,
              stationName: station.station.name,
              county: station.station.county,
              town: station.station.town,
            ))
        .toList();

    await addHumidityCircles(humidityDataList);

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

  Future<void> addHumidityCircles(List<HumidityData> humidityDataList) async {
    final features = humidityDataList
        .map((data) => {
              "type": "Feature",
              "properties": {
                "humidity": data.humidity,
              },
              "geometry": {
                "type": "Point",
                "coordinates": [data.longitude, data.latitude]
              }
            })
        .toList();

    await _mapController.setGeoJsonSource("humidity-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("humidity-circles");
    await _mapController.addLayer(
      "humidity-data",
      "humidity-circles",
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
          [Expressions.get, "humidity"],
          0,
          "#ffb63d",
          50,
          "#ffffff",
          100,
          "#0000FF",
        ],
        circleOpacity: 0.7,
        circleStrokeWidth: 0.2,
        circleStrokeColor: "#000000",
        circleStrokeOpacity: 0.7,
      ),
    );

    await _mapController.removeLayer("humidity-labels");
    await _mapController.addSymbolLayer(
      "humidity-data",
      "humidity-labels",
      const SymbolLayerProperties(
        textField: ["get", "humidity"],
        textSize: 12,
        textColor: "#ffffff",
        textHaloColor: "#000000",
        textHaloWidth: 1,
        textFont: ["Noto Sans Regular"],
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
        Text(context.i18n.unit_relative_humidity, style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildColorBar() {
    return Container(
      height: 20,
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFB63D), // 0% humidity
            Color(0xFFFFFFFF), // 50% humidity
            Color(0xFF0000FF), // 100% humidity
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = ["0%", "25%", "50%", "75%", "100%"];
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
                message: "圖例",
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

                humidityDataList = [];

                humidityDataList = weatherData
                    .where((station) => station.data.air.relative_humidity != -99)
                    .map((station) => HumidityData(
                          latitude: station.station.lat,
                          longitude: station.station.lng,
                          humidity: station.data.air.relative_humidity,
                          stationName: station.station.name,
                          county: station.station.county,
                          town: station.station.town,
                        ))
                    .toList();

                await addHumidityCircles(humidityDataList);
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
