import 'dart:io';

import 'package:dpip/model/history.dart';
import 'package:flutter/material.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/global.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MapLibreMapController _mapController;
  List<History> historyList = [];
  final _scrollController = ScrollController();
  List<String> radar_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  Future<void> refreshHistoryList() async {
    historyList = await ExpTech().getHistory();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    refreshHistoryList();
  }

  String getTileUrl(String timestamp) {
    return "https://api-1.exptech.dev/api/v1/tiles/radar/$timestamp/{z}/{x}/{y}.png";
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadGPSImage(_mapController);
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
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

  void _loadMap() async {
    final isDark = context.theme.brightness == Brightness.dark;

    await _loadMapImages(isDark);

    radar_list = await ExpTech().getRadarList();

    String newTileUrl = getTileUrl(radar_list.last);

    _mapController.addSource(
        "radarSource",
        RasterSourceProperties(
          tiles: [newTileUrl],
          tileSize: 256,
        ));

    _mapController.addLayer("radarSource", "radarLayer", const RasterLayerProperties());

    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

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
      final cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(userLat, userLon), 10);
      await _mapController.animateCamera(cameraUpdate);
    }

    _addUserLocationMarker();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.home),
      ),
      body: Stack(
        children: [
          DpipMap(
            onMapCreated: _initMap,
            onStyleLoadedCallback: _loadMap,
            zoomGesturesEnabled: false,
            doubleClickZoomEnabled: false,
            scrollGesturesEnabled: false,
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.2,
              builder: (context, scrollController) {
                return Container(
                  color: context.colors.surface,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.colors.onSurfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          // color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '台北市 中正區',
                              style: TextStyle(
                                color: context.colors.secondary,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud,
                                  color: context.colors.secondary,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '27.0°C',
                                  style: TextStyle(
                                    color: context.colors.secondary,
                                    fontSize: 48,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '降水量: 0.56 mm\n濕度: 89.0 %\n體感: 31.4°C',
                              style: TextStyle(
                                color: context.colors.secondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '更新時間: 07/26 00:00',
                              style: TextStyle(
                                color: context.colors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              if (historyList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await refreshHistoryList();
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: _scrollController,
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    var showDate = false;
                    final current = historyList[index];

                    // if (index != 0) {
                    //   final prev = historyList[index - 1];
                    //   if (current.time.day != prev.time.day) {
                    //     showDate = true;
                    //   }
                    // } else {
                    //   showDate = true;
                    // }

                    // return SizedBox(
                    //   height: 15,
                    //   child: Text(current.id),
                    // );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(int index) {
    switch (index) {
      case 0:
      case 3:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 4:
      default:
        return Colors.red;
    }
  }
}
