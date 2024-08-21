import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/map/tsunami/tsunami_estimate_list.dart';
import 'package:dpip/app/page/map/tsunami/tsunami_observed_list.dart';
import 'package:dpip/model/tsunami/tsunami.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dpip/model/tsunami/tsunami_actual.dart';
import 'package:dpip/model/tsunami/tsunami_estimate.dart';

class TsunamiMap extends StatefulWidget {
  const TsunamiMap({super.key});

  @override
  State<StatefulWidget> createState() => _TsunamiMapState();
}

class _TsunamiMapState extends State<TsunamiMap> {
  late MapLibreMapController _mapController;
  Tsunami? tsunami;
  String tsunamiStatus = "";
  bool refreshingTsunami = true;

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  void _loadMap() async {
    await refreshTsunami();
    await _mapController.addSource(
      "tsunami-data",
      const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}),
    );

    if (tsunami != null) {
      await addTsunamiObservationPoints(tsunami!);
    }
  }

  Future<void> addTsunamiObservationPoints(Tsunami tsunami) async {
    if (tsunami.info.type == "estimate") {
    } else {
      final features = tsunami.info.data.map((station) {
        var actualStation = station as TsunamiActual;
        return {
          "type": "Feature",
          "properties": {
            "name": actualStation.name,
            "id": actualStation.id,
            "waveHeight": actualStation.waveHeight,
            "arrivalTime": actualStation.arrivalTime,
            "isEstimate": false,
          },
          "geometry": {
            "type": "Point",
            "coordinates": [actualStation.lon ?? 0, actualStation.lat ?? 0]
          }
        };
      }).toList();

      await _mapController.setGeoJsonSource("tsunami-data", {"type": "FeatureCollection", "features": features});

      await _mapController.addLayer(
        "tsunami-data",
        "tsunami-actual-circles",
        const CircleLayerProperties(
          circleRadius: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            7,
            8,
            12,
            18,
          ],
          circleColor: [
            Expressions.step,
            [Expressions.get, "waveHeight"],
            "#606060",
            30,
            "#FFC900",
            100,
            "#C90000",
            300,
            "#E543FF",
          ],
          circleOpacity: 1,
          circleStrokeWidth: 0.2,
          circleStrokeColor: "#000000",
          circleStrokeOpacity: 0.7,
        ),
        filter: [
          '!=',
          ['get', 'isEstimate'],
          0
        ],
      );

      await _mapController.addSymbolLayer(
        "tsunami-data",
        "tsunami-actual-labels",
        const SymbolLayerProperties(
          textField: ['get', 'name'],
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
          '!',
          ['get', 'isEstimate']
        ],
        minzoom: 8,
      );
    }
  }

  Future<Tsunami?> refreshTsunami() async {
    refreshingTsunami = true;
    var idList = await ExpTech().getTsunamiList();
    var id = "";
    if (idList.isNotEmpty) {
      id = idList[0];
      tsunami = await ExpTech().getTsunami(id);
      (tsunami?.status == 0)
          ? tsunamiStatus = "發布"
          : (tsunami?.status == 1)
              ? tsunamiStatus = "更新"
              : tsunamiStatus = "解除";
    }
    setState(() {
      refreshingTsunami = false;
    });
    return tsunami;
  }

  String convertTimestamp(int timestamp) {
    var location = tz.getLocation('Asia/Taipei');
    DateTime dateTime = tz.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);

    DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }

  String getTime() {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    String formattedDate = formatter.format(now);
    return (formattedDate);
  }

  String convertLatLon(double lat, double lon) {
    var latFormat = "";
    var lonFormat = "";
    if (lat > 90) {
      lat = lat - 180;
    }
    if (lon > 180) {
      lat = lat - 360;
    }
    if (lat < 0) {
      latFormat = "南緯 ${lat.abs()} 度";
    } else {
      latFormat = "北緯 $lat 度";
    }
    if (lon < 0) {
      lonFormat = "西經 ${lon.abs()} 度";
    } else {
      lonFormat = "東經 $lon 度";
    }
    return "$latFormat　$lonFormat";
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.16;
    return Stack(children: [
      DpipMap(
        onMapCreated: _initMap,
        onStyleLoadedCallback: _loadMap,
        minMaxZoomPreference: const MinMaxZoomPreference(3, 12),
      ),
      Positioned.fill(
        child: DraggableScrollableSheet(
          initialChildSize: sheetInitialSize,
          minChildSize: sheetInitialSize,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              color: context.colors.surface.withOpacity(0.9),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: refreshingTsunami == true
                        ? Container()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tsunami == null ? "近期無海嘯資訊" : "海嘯警報",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: context.colors.onSurface,
                                ),
                              ),
                              tsunami != null
                                  ? Text(
                                      "${tsunami?.id}號 第${tsunami?.serial}報",
                                      style: TextStyle(
                                        fontSize: 14,
                                        letterSpacing: 1,
                                        color: context.colors.onSurface,
                                      ),
                                    )
                                  : Container(),
                              Text(
                                tsunami != null
                                    ? "${convertTimestamp(tsunami!.time)} $tsunamiStatus"
                                    : "${getTime()} 更新",
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 1,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              tsunami != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${tsunami?.content}",
                                          style: TextStyle(
                                            fontSize: 18,
                                            letterSpacing: 2,
                                            color: context.colors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        tsunami?.info.type == "estimate"
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "預估海嘯到達時間及波高",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  TsunamiEstimateList(tsunamiList: tsunami!.info.data),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "各地觀測到的海嘯",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  TsunamiObservedList(tsunamiList: tsunami!.info.data),
                                                ],
                                              ),
                                        const SizedBox(
                                          height: 15,
                                        ),
                                        Text(
                                          "地震資訊",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                            color: context.colors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "發生時間",
                                              style: TextStyle(
                                                fontSize: 18,
                                                letterSpacing: 2,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                            Text(
                                              convertTimestamp(tsunami!.eq.time),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "震央",
                                              style: TextStyle(
                                                fontSize: 18,
                                                letterSpacing: 2,
                                                color: context.colors.onSurface,
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  tsunami!.eq.loc,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  convertLatLon(tsunami!.eq.lat, tsunami!.eq.lon),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "規模",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${tsunami!.eq.mag}",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "深度",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${tsunami!.eq.depth}km",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 2,
                                                      color: context.colors.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}
