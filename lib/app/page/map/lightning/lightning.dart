import "dart:async";
import "dart:io";

import "package:dpip/api/exptech.dart";
import "package:dpip/model/weather/lightning.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/map_utils.dart";
import "package:dpip/widget/list/time_selector.dart";
import "package:dpip/widget/map/legend.dart";
import "package:dpip/widget/map/map.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";

import "../../../../core/ios_get_location.dart";
import "../../../../global.dart";

class LightningData {
  final double latitude;
  final double longitude;
  final int type;
  final int time;

  LightningData({
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.time,
  });
}

class LightningMap extends StatefulWidget {
  const LightningMap({Key? key}) : super(key: key);

  @override
  State<LightningMap> createState() => _LightningMapState();
}

class _LightningMapState extends State<LightningMap> {
  late MapLibreMapController _mapController;
  List<String> lightningTimeList = [];
  List<LightningData> lightningDataList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  int selectTime = 0;

  @override
  void initState() {
    super.initState();
  }

  void _initMap(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    await _loadMapImages();
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;
    await _mapController.addSource(
      "lightning-data",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );
    lightningTimeList = await ExpTech().getLightningList();
    if (lightningTimeList.isNotEmpty) {
      selectTime = int.parse(lightningTimeList.last);
      await _loadLightningData(lightningTimeList.last);
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

  Future<void> _loadMapImages() async {
    await loadGPSImage(_mapController);
    await loadLightningImage(_mapController);
  }

  Future<void> _loadLightningData(String time) async {
    List<Lightning> lightningData = await ExpTech().getLightning(time);
    lightningDataList = lightningData
        .map((lightning) => LightningData(
              latitude: lightning.loc.lat,
              longitude: lightning.loc.lng,
              type: lightning.type,
              time: lightning.time,
            ))
        .toList();

    await _addLightningMarkers();
  }

  Future<void> _addLightningMarkers() async {
    final features = lightningDataList.map((data) {
      final timeDiff = selectTime - data.time;
      int level;
      if (timeDiff < 5 * 60 * 1000) {
        level = 5;
      } else if (timeDiff < 10 * 60 * 1000) {
        level = 10;
      } else if (timeDiff < 30 * 60 * 1000) {
        level = 30;
      } else {
        level = 60;
      }

      return {
        "type": "Feature",
        "properties": {
          "type": "${data.type}-$level",
        },
        "geometry": {
          "type": "Point",
          "coordinates": [data.longitude, data.latitude]
        }
      };
    }).toList();

    await _mapController.setGeoJsonSource("lightning-data", {"type": "FeatureCollection", "features": features});

    await _mapController.removeLayer("lightning-markers");
    await _mapController.addLayer(
      "lightning-data",
      "lightning-markers",
      const SymbolLayerProperties(
        iconSize: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          5,
          0.5,
          10,
          1.3,
        ],
        iconImage: [
          Expressions.match,
          ["get", "type"],
          "1-5",
          "lightning-1-5",
          "1-10",
          "lightning-1-10",
          "1-30",
          "lightning-1-30",
          "1-60",
          "lightning-1-60",
          "0-5",
          "lightning-0-5",
          "0-10",
          "lightning-0-10",
          "0-30",
          "lightning-0-30",
          "lightning-0-60",
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );

    await _addUserLocationMarker();
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return MapLegend(
      label: "閃電圖例",
      children: [
        _legendItem("lightning-1-5", "5 分鐘內對地閃電"),
        _legendItem("lightning-1-10", "10 分鐘內對地閃電"),
        _legendItem("lightning-1-30", "30 分鐘內對地閃電"),
        _legendItem("lightning-1-60", "60 分鐘內對地閃電"),
        _legendItem("lightning-0-5", "5 分鐘內雲間閃電"),
        _legendItem("lightning-0-10", "10 分鐘內雲間閃電"),
        _legendItem("lightning-0-30", "30 分鐘內雲間閃電"),
        _legendItem("lightning-0-60", "60 分鐘內雲間閃電"),
      ],
    );
  }

  Widget _legendItem(String imageName, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset("assets/map/icons/$imageName.png", width: 24, height: 24),
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
        if (lightningTimeList.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: lightningTimeList,
              onTimeExpanded: () {
                _showLegend = false;
                setState(() {});
              },
              onTimeSelected: (time) async {
                selectTime = int.parse(time);
                await _loadLightningData(time);
                setState(() {});
              },
            ),
          ),
        if (_showLegend)
          Positioned(
            left: 6,
            bottom: 50,
            child: _buildLegend(),
          ),
      ],
    );
  }
}
