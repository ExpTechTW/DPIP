import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  late MapLibreMapController controller;
  late Map<String, Station> stations;
  Timer? timer;

  Map<String, dynamic> generateStationGeoJson([Rts? rtsData]) {
    final features = stations.entries.map((e) {
      return {
        "type": "Feature",
        "properties": rtsData == null ? {} : rtsData.station[e.key] ?? {},
        "id": e.key,
        "geometry": {
          "coordinates": [e.value.info[0].lon, e.value.info[0].lat],
          "type": "Point"
        }
      };
    }).toList();

    return {
      "type": "FeatureCollection",
      "features": features,
    };
  }

  void setupStation() async {
    final data = await ExpTech().getStations();

    Map<String, dynamic> latestStations = {};
    data.forEach((key, station) {
      if (station.work == true) {
        List<dynamic> info = station.info;
        info.sort((a, b) => DateTime.parse(b.time).compareTo(DateTime.parse(a.time)));
        Map<String, dynamic> stationData = {
          'latestTime': info.first.time // 存取 info 中第一個物件的 time 屬性
        };
        latestStations[key] = stationData;
      }
    });

    setState(() => stations = data);

    controller.addSource(
      "station-geojson",
      GeojsonSourceProperties(
        data: generateStationGeoJson(),
      ),
    );

    controller.addCircleLayer(
      "station-geojson",
      "station",
      CircleLayerProperties(
        circleColor: [
          Expressions.interpolate,
          ["linear"],
          ["get", "i"],
          -3,
          InstrumentalIntensityColor.intensity_3.toHexStringRGB(),
          -2,
          InstrumentalIntensityColor.intensity_2.toHexStringRGB(),
          -1,
          InstrumentalIntensityColor.intensity_1.toHexStringRGB(),
          0,
          InstrumentalIntensityColor.intensity0.toHexStringRGB(),
          1,
          InstrumentalIntensityColor.intensity1.toHexStringRGB(),
          2,
          InstrumentalIntensityColor.intensity2.toHexStringRGB(),
          3,
          InstrumentalIntensityColor.intensity3.toHexStringRGB(),
          4,
          InstrumentalIntensityColor.intensity4.toHexStringRGB(),
          5,
          InstrumentalIntensityColor.intensity5.toHexStringRGB(),
          6,
          InstrumentalIntensityColor.intensity6.toHexStringRGB(),
          7,
          InstrumentalIntensityColor.intensity7.toHexStringRGB(),
        ],
        circleRadius: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          4,
          2,
          12,
          8
        ],
      ),
    );

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateRtsData();
    });
  }

  void updateRtsData() async {
    final data = await ExpTech().getRts();
    controller.setGeoJsonSource("station-geojson", generateStationGeoJson(data));
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    if (testTimer != null) {
      testTimer!.cancel();
    }
    super.dispose();
  }

  double radius = 120;
  Timer? testTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.monitor),
        actions: [
          IconButton(
            onPressed: () {
              if (testTimer != null) {
                testTimer!.cancel();
              }

              testTimer = Timer.periodic(Duration(milliseconds: 100), (t) {
                radius += 0.1;
                final c = circle(const LatLng(25.299654949482424, 121.53697911932383), /* 384.63 */ radius, steps: 128);
                controller.setGeoJsonSource("circle", {
                  "type": "FeatureCollection",
                  "features": [c],
                });
              });
            },
            icon: const Icon(Symbols.update),
          ),
          IconButton(
            onPressed: () {
              final c = circle(const LatLng(25.299654949482424, 121.53697911932383), /* 384.63 */ radius, steps: 128);

              controller.addSource(
                "circle",
                GeojsonSourceProperties(
                  data: {
                    "type": "FeatureCollection",
                    "features": [c],
                  },
                  tolerance: 1,
                ),
              );

              controller.addLineLayer(
                "circle",
                "wave-outline",
                const LineLayerProperties(lineColor: "#fa0", lineWidth: 2),
              );

              controller.addFillLayer(
                "circle",
                "wave-bg",
                const FillLayerProperties(
                  fillColor: "#fa0",
                  fillOpacity: 0.25,
                ),
                belowLayerId: "county",
              );
            },
            icon: const Icon(Symbols.add),
          ),
        ],
      ),
      body: Stack(
        children: [
          DpipMap(
            onMapCreated: (c) {
              setState(() => controller = c);
              setupStation();
            },
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              builder: (context, scrollController) {
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
