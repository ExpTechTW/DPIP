import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/weather/typhoon.dart';
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
  List<Typhoon>? typhoonData;
  List<String> typhoonList = [];
  String selectedTyphoonId = "";
  List<String> sourceList = [];
  List<String> layerList = [];
  List<String> typhoon_name_list = [];
  String selectedTimestamp = "";
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _loadMap() async {
    try {
      typhoonList = await ExpTech().getTyphoonList();
      if (typhoonList.isNotEmpty) {
        selectedTimestamp = typhoonList.last;
        await _loadTyphoonData(selectedTimestamp);
      }
      selectedTimestamp = typhoonList.last;

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

  Future<void> _loadTyphoonData(String time) async {
    try {
      typhoonData = await ExpTech().getTyphoon(time);
      if (typhoonData != null && typhoonData!.isNotEmpty) {
        typhoon_name_list = [];
        await _drawTyphoonPaths(typhoonData!);
      }
    } catch (e) {
      TalkerManager.instance.error("加載颱風數據時出錯: $e");
    }
  }

  void _onSelectionChanged(String timestamp, String typhoonId) async {
    selectedTimestamp = timestamp;
    await _loadTyphoonData(selectedTimestamp);
    if (selectedTyphoonId != typhoonId) {
      selectedTyphoonId = typhoonId;
      _zoomToSelectedTyphoon();
    }
    setState(() {});
  }

  Future<void> _zoomToSelectedTyphoon() async {
    if (typhoonData != null && selectedTyphoonId.isNotEmpty) {
      Typhoon? selectedTyphoon = typhoonData!.firstWhere((t) => t.name.zh == selectedTyphoonId);
      if (selectedTyphoon != null && selectedTyphoon.analysis.isNotEmpty) {
        LatLng center = LatLng(
          selectedTyphoon.analysis.last.lat,
          selectedTyphoon.analysis.last.lng,
        );
        double zoomLevel = 5;
        await _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(center, zoomLevel),
          duration: const Duration(milliseconds: 1000),
        );
      }
    }
  }

  Future<void> _drawTyphoonPaths(List<Typhoon> typhoons) async {
    for (String layerId in layerList) {
      await _mapController.removeLayer(layerId);
    }
    for (String sourceId in sourceList) {
      await _mapController.removeSource(sourceId);
    }
    layerList.clear();
    sourceList.clear();

    for (int i = 0; i < typhoons.length; i++) {
      Typhoon typhoon = typhoons[i];
      if (selectedTyphoonId == "") {
        selectedTyphoonId = typhoon.name.zh;
        _zoomToSelectedTyphoon();
      }
      typhoon_name_list.add(typhoon.name.zh);
      await _drawTyphoonPath(typhoon, i);
      await _draw15WindCircle(typhoon, i);
      await _drawForecastCircles(typhoon, i);
    }
  }

  Future<void> _drawTyphoonPath(Typhoon typhoon, int i) async {
    String sourceId = "typhoon-path-$i";
    String layerId = "typhoon-path-line-$i";
    String sourceId_forecast = "typhoon-path-$i-forecast";
    String layerId_forecast = "typhoon-path-line-$i-forecast";

    List<List<double>> coordinates = typhoon.analysis.map((a) => [a.lng, a.lat]).toList();
    List<List<double>> coordinates_forecast = typhoon.forecast.map((f) => [f.lng, f.lat]).toList();

    coordinates_forecast.insert(0, coordinates.last);

    await _mapController.addSource(
      sourceId,
      GeojsonSourceProperties(
        data: {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {},
              "geometry": {
                "type": "LineString",
                "coordinates": coordinates,
              }
            }
          ]
        },
      ),
    );
    await _mapController.addLineLayer(
      sourceId,
      layerId,
      const LineLayerProperties(
        lineColor: "#62abc7",
        lineWidth: 3,
      ),
    );

    await _mapController.addSource(
      sourceId_forecast,
      GeojsonSourceProperties(
        data: {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {},
              "geometry": {
                "type": "LineString",
                "coordinates": coordinates_forecast,
              }
            }
          ]
        },
      ),
    );
    await _mapController.addLineLayer(
      sourceId_forecast,
      layerId_forecast,
      const LineLayerProperties(
        lineColor: "#000000",
        lineWidth: 3,
      ),
    );

    layerList.addAll([layerId, layerId_forecast]);
    sourceList.addAll([sourceId, sourceId_forecast]);
  }

  Future<void> _draw15WindCircle(Typhoon typhoon, int i) async {
    String sourceId_15 = "typhoon-15-geojson-$i";
    String layerId_15 = "typhoon-15-circle-$i";
    String layerId_15_outline = "typhoon-15-circle-outline-$i";

    await _mapController.addGeoJsonSource(sourceId_15, {
      "type": "FeatureCollection",
      "features": [
        circle(LatLng(typhoon.analysis.last.lat, typhoon.analysis.last.lng),
            typhoon.analysis.last.circle["15"]?.toDouble() ?? 0.0,
            steps: 256)
      ]
    });

    await _mapController.addLayer(
        sourceId_15, layerId_15, const FillLayerProperties(fillColor: "#fbd745", fillOpacity: 0.6));

    await _mapController.addLayer(
        sourceId_15, layerId_15_outline, const LineLayerProperties(lineColor: "#d4af37", lineWidth: 2));

    sourceList.add(sourceId_15);
    layerList.addAll([layerId_15, layerId_15_outline]);
  }

  Future<void> _drawForecastCircles(Typhoon typhoon, int i) async {
    int I = 0;
    for (var forecast in typhoon.forecast) {
      String sourceId_radius_forecast = "typhoon-15-geojson-$i-$I";
      String layerId_radius_forecast = "typhoon-15-circle-$i-$I";
      String layerId_radius_forecast_outline = "typhoon-15-circle-outline-$i-$I";

      await _mapController.addGeoJsonSource(sourceId_radius_forecast, {
        "type": "FeatureCollection",
        "features": [circle(LatLng(forecast.lat, forecast.lng), forecast.radius.toDouble(), steps: 256)]
      });

      await _mapController.addLayer(sourceId_radius_forecast, layerId_radius_forecast,
          const FillLayerProperties(fillColor: "#83bca0", fillOpacity: 0.6));

      await _mapController.addLayer(sourceId_radius_forecast, layerId_radius_forecast_outline,
          const LineLayerProperties(lineColor: "#2e8b57", lineWidth: 2));

      sourceList.add(sourceId_radius_forecast);
      layerList.addAll([layerId_radius_forecast, layerId_radius_forecast_outline]);
      I++;
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
        if (typhoonList.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TyphoonTimeSelector(
              onSelectionChanged: _onSelectionChanged,
              onTimeExpanded: () {},
              timeList: typhoonList,
              typhoonList: typhoon_name_list,
              selectedTyphoonId: selectedTyphoonId,
            ),
          ),
      ],
    );
  }
}
