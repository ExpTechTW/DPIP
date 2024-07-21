import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
    print(rtsData == null ? {} : rtsData.station);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}
