import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/route/report/report_sheet_content.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../util/intensity_color.dart';

class RadarRoute extends StatefulWidget {
  const RadarRoute({super.key});

  @override
  State<RadarRoute> createState() => _RadarRouteState();
}

class _RadarRouteState extends State<RadarRoute> with TickerProviderStateMixin {
  EarthquakeReport? report;
  final mapController = Completer<MapLibreMapController>();

  @override
  void initState() {
    super.initState();
  }

  void addTileLayer(MapLibreMapController controller) async {
    try {
      await controller.addSource(
        "tile_source",
        const RasterSourceProperties(
          tiles: ["https://api-1.exptech.dev/api/v1/tiles/radar/{z}/{x}/{y}.png"],
          tileSize: 256,
        ),
      );
      await controller.addLayer(
        "tile_source",
        "tile_layer",
        const RasterLayerProperties(rasterOpacity: 1),
      );
      print("Tile layer added successfully");
    } catch (e) {
      print("Error adding tile layer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.i18n.report),
      ),
      body: Stack(children: [
        DpipMap(
          onMapCreated: (controller) async {
            mapController.complete(controller);
            await controller.setSymbolIconAllowOverlap(true);
            await controller.setSymbolIconIgnorePlacement(true);
            addTileLayer(controller);
          },
        ),
      ]),
    );
  }
}
