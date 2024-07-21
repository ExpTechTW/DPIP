import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/util/extension/build_context.dart';
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

  void setupStation() async {
    final data = await ExpTech().getStations();

    setState(() => stations = data);

    final features = data.entries.map((e) {
      return {
        "type": "Feature",
        "properties": {},
        "id": e.key,
        "geometry": {
          "coordinates": [e.value.info[0].lon, e.value.info[0].lat],
          "type": "Point"
        }
      };
    }).toList();

    final geojson = {
      "type": "FeatureCollection",
      "features": features,
    };

    controller.addSource(
      "station-geojson",
      GeojsonSourceProperties(
        data: geojson,
      ),
    );

    controller.addCircleLayer(
      "station-geojson",
      "station",
      CircleLayerProperties(
        circleColor:  [
          Expressions.interpolate,
          ["linear"],
          ["get", "i"],
          -3,
          Color(0xff0005d0).toHexStringRGB(),
          -2,
          Color(0xff004bf8).toHexStringRGB(),
          -1,
          Color(0xff009EF8).toHexStringRGB(),
          0,
          Color(0xff79E5FD).toHexStringRGB(),
          1,
          Color(0xff49E9AD).toHexStringRGB(),
          2,
          Color(0xff44fa34).toHexStringRGB(),
          3,
          Color(0xffbeff0c).toHexStringRGB(),
          4,
          Color(0xfffff000).toHexStringRGB(),
          5,
          Color(0xffff9300).toHexStringRGB(),
          6,
          Color(0xfffc5235).toHexStringRGB(),
          7,
          Color(0xffb720e9).toHexStringRGB(),
        ],
        circleRadius: 4,
      ),
    );
  }

  void updateRtsData() async {
    final data = await ExpTech().getRts();

    for (final MapEntry(key: key, value: value) in data.station.entries) {
      controller.state
    }
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
