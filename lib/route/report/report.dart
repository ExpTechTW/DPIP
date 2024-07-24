import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/route/report/report_sheet_content.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReportRoute extends StatefulWidget {
  final PartialEarthquakeReport report;

  const ReportRoute({super.key, required this.report});

  @override
  State<ReportRoute> createState() => _ReportRouteState();
}

class _ReportRouteState extends State<ReportRoute> with TickerProviderStateMixin {
  EarthquakeReport? report;
  final mapController = Completer<MapLibreMapController>();

  // FIXME: workaround waiting for upstream PR to merge
  // https://github.com/material-foundation/flutter-packages/pull/599
  late final backgroundColor = Color.lerp(context.colors.surface, context.colors.surfaceTint, 0.08);

  late final decorationTween = DecorationTween(
    begin: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      color: backgroundColor,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      color: backgroundColor,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  final sheetInitialSize = 0.2;
  final sheetController = DraggableScrollableController();
  late ScrollController scrollController;

  bool isLoading = true;

  void refreshReport() async {
    setState(() => isLoading = true);

    try {
      final data = await ExpTech().getReport(widget.report.id);
      final controller = await mapController.future;

      List features = [];

      for (var MapEntry(key: _, value: area) in data.list.entries) {
        for (var MapEntry(key: _, value: town) in area.town.entries) {
          features.add({
            "type": "Feature",
            "properties": {
              "intensity": town.intensity,
            },
            "geometry": {
              "coordinates": [town.lon, town.lat],
              "type": "Point"
            }
          });
        }
      }

      features.add({
        "type": "Feature",
        "properties": {
          "intensity": 10,
        },
        "geometry": {
          "coordinates": [data.lon, data.lat],
          "type": "Point"
        }
      });

      await controller.addGeoJsonSource(
        "markers-geojson",
        {
          "type": "FeatureCollection",
          "features": features,
        },
      );

      if (!mounted) return;

      final isDark = context.theme.brightness == Brightness.dark;

      for (var i = 1; i < 10; i++) {
        final path = "assets/map/icons/intensity-$i${isDark ? "" : "-dark"}.png";

        await controller.addImage("intensity-$i", Uint8List.sublistView(await rootBundle.load(path)));
      }

      await controller.addImage("cross", Uint8List.sublistView(await rootBundle.load("assets/map/icons/cross.png")));

      await controller.addLayer(
        "markers-geojson",
        "markers",
        const SymbolLayerProperties(
          symbolSortKey: [Expressions.get, "intensity"],
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
          iconImage: [
            Expressions.match,
            [Expressions.get, "intensity"],
            1,
            "intensity-1",
            2,
            "intensity-2",
            3,
            "intensity-3",
            4,
            "intensity-4",
            5,
            "intensity-5",
            6,
            "intensity-6",
            7,
            "intensity-7",
            8,
            "intensity-8",
            9,
            "intensity-9",
            "cross",
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );

      /* 
      await controller.setLayerProperties(
        'county',
        FillLayerProperties(
          fillColor: [
            'match',
            ['get', 'NAME_2014'],
            ...cityMaxIntensity.entries.expand((entry) => [
                  entry.key,
                  IntensityColor.intensity(entry.value).toHexStringRGB(),
                ]),
            context.colors.surfaceVariant.toHexStringRGB(),
          ],
          fillOpacity: 1,
        ),
      ); */

      setState(() {
        report = data;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  void focus(LatLng target) async {
    final controller = await mapController.future;
    sheetController.animateTo(sheetInitialSize, duration: Durations.short4, curve: Easing.standard);
    scrollController.jumpTo(0);
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(target.latitude - 0.03, target.longitude), 10),
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    sheetController.addListener(() {
      final newSize = sheetController.size;
      final scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);
      animController.animateTo(scrollPosition, duration: Duration.zero);
    });

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
            refreshReport();
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: sheetInitialSize,
            minChildSize: sheetInitialSize,
            controller: sheetController,
            snap: true,
            builder: (context, controller) {
              scrollController = controller;

              return DecoratedBoxTransition(
                decoration: animController.drive(decorationTween),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : report == null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                const Flexible(
                                  flex: 8,
                                  child: Text(
                                    "取得地震報告時發生錯誤，請檢查網路狀況後再試一次。",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  flex: 2,
                                  child: IconButton(
                                    icon: const Icon(Symbols.refresh),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: context.colors.onSurface,
                                    ),
                                    onPressed: () {
                                      refreshReport();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ReportSheetContent(report: report!, controller: controller, focus: focus),
              );
            },
          ),
        ),
      ]),
    );
  }
}
