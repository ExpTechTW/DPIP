import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../model/eew.dart';
import '../../../model/location/location.dart';
import '../../../util/intensity_color.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> with SingleTickerProviderStateMixin {
  late MapLibreMapController controller;
  late Map<String, Station> stations;
  Timer? timer;
  Timer? eewTimer;
  int timeOffset = 0;
  List<String> eewIdList = [];
  List<Eew> eewData = [];
  int replayTimeStamp = 0;
  int timeReplay = 1721770570342;
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<String, dynamic> eewIntensityArea = {};

  Map<String, dynamic> generateStationGeoJson([Rts? rtsData]) {
    if (rtsData == null) {
      return {
        "type": "FeatureCollection",
        "features": [],
      };
    }

    final features = stations.entries.where((e) {
      return rtsData.station.containsKey(e.key);
    }).map((e) {
      return {
        "type": "Feature",
        "properties": rtsData.station[e.key] ?? {},
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
      updateEewData();
    });
  }

  void updateRtsData() async {
    final data = await ExpTech().getRts(timeReplay);
    controller.setGeoJsonSource("station-geojson", generateStationGeoJson(data));

    if (timeReplay != 0) {
      timeReplay += (replayTimeStamp == 0) ? 0 : DateTime.now().millisecondsSinceEpoch - replayTimeStamp;
      replayTimeStamp = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void updateMapArea() async {
    Map<String, int> eewArea = {};
    eewIntensityArea.forEach((String key, intensity) {
      intensity.forEach((name, value) {
        if (name != "max_i") {
          int I = intensityFloatToInt(value["i"]);
          if (eewArea[name] == null || eewArea[name]! < I) {
            eewArea[name] = I;
          }
        }
      });
    });

    await controller.setLayerProperties(
      'town',
      FillLayerProperties(
        fillColor: [
          'match',
          ['get', 'CODE'],
          ...eewArea.entries.expand((entry) => [
                int.parse(entry.key),
                IntensityColor.intensity(entry.value).toHexStringRGB(),
              ]),
          context.colors.surfaceVariant.toHexStringRGB(),
        ],
        fillOpacity: 1,
      ),
    );
  }

  void updateEewData() async {
    final data = await ExpTech().getEew(timeReplay);
    eewData = data;
    if (data.isNotEmpty) {
      for (var i = 0; i < data.length; i++) {
        var json = data[i];

        if (!eewIdList.contains(json.id)) {
          eewIdList.add(json.id);
          final c = circle(LatLng(json.eq.lat, json.eq.lon), /* 384.63 */ 0, steps: 256);

          controller.addSource(
            "${json.id}-circle",
            GeojsonSourceProperties(
              data: {
                "type": "FeatureCollection",
                "features": [c],
              },
              tolerance: 1,
            ),
          );

          controller.addLineLayer(
            "${json.id}-circle",
            "${json.id}-wave-outline",
            LineLayerProperties(lineColor: (json.status == 1) ? "#ff0000" : "#ffaa00", lineWidth: 2),
          );

          controller.addFillLayer(
            "${json.id}-circle",
            "${json.id}-wave-bg",
            FillLayerProperties(
              fillColor: (json.status == 1) ? "#ff0000" : "#ffaa00",
              fillOpacity: 0.25,
            ),
            belowLayerId: "county",
          );

          eewIntensityArea[json.id] = eewAreaPga(json.eq.lat, json.eq.lon, 10, 6.8, Global.location);

          updateMapArea();
        }
      }

      eewTimer ??= Timer.periodic(const Duration(milliseconds: 100), (t) {
        for (var i = 0; i < eewData.length; i++) {
          var json = eewData[i];
          Map<String, double> dist = psWaveDist(json.eq.depth, json.eq.time,
              (timeReplay != 0) ? timeReplay : DateTime.now().millisecondsSinceEpoch + timeOffset);
          final c = circle(LatLng(json.eq.lat, json.eq.lon), /* 384.63 */ dist["s_dist"]!, steps: 256);
          controller.setGeoJsonSource("${json.id}-circle", {
            "type": "FeatureCollection",
            "features": [c],
          });
        }
      });
    } else {
      if (eewTimer != null) {
        eewTimer!.cancel();
      }

      await controller.setLayerProperties(
        'town',
        FillLayerProperties(
          fillColor: context.colors.surfaceVariant.toHexStringRGB(),
          fillOpacity: 1,
        ),
      );
    }

    Iterable<String> fetchEewIdList = data.map((e) => e.id);
    for (var i = 0; i < eewIdList.length; i++) {
      if (!fetchEewIdList.contains(eewIdList[i])) {
        controller.removeLayer("${eewIdList[i]}-wave-outline");
        controller.removeLayer("${eewIdList[i]}-wave-bg");
        controller.removeSource("${eewIdList[i]}-circle");
        eewIntensityArea.remove(eewIdList[i]);
        eewIdList.removeAt(i);

        updateMapArea();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    ExpTech().getNtp().then((data) {
      timeOffset = DateTime.now().millisecondsSinceEpoch - data;
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (timer != null) {
      timer!.cancel();
    }
    if (eewTimer != null) {
      eewTimer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(context.i18n.monitor),
            Visibility(
              visible: timeReplay != 0,
              maintainAnimation: true,
              maintainState: true,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  FadeTransition(
                    opacity: _animation,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                  const SizedBox(width: 5),
                  const Text('重播'),
                ],
              ),
            ),
          ],
        ),
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
