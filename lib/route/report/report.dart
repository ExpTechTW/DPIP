import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/route/report/report_sheet_content.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/widget/map/marker/custom_marker.dart';
import 'package:dpip/widget/map/marker/intensity_marker.dart';
import 'package:flutter/material.dart';
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
  List<CustomMarker> mapMarkers = [];

  final mapKey = GlobalKey<DpipMapState>();

  DpipMapState get map => mapKey.currentState!;

  late final decorationTween = DecorationTween(
    begin: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      color: context.colors.surfaceContainer,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      color: context.colors.surfaceContainer,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  final sheetInitialSize = 0.2;
  final sheetController = DraggableScrollableController();

  bool refreshing = true;

  refreshReport() {
    setState(() {
      refreshing = true;
    });
    ExpTech().getReport(widget.report.id).then((data) async {
      setState(() {
        report = data;
        refreshing = false;
      });
    }).catchError((error) {
      setState(() {
        refreshing = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    refreshReport();
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
        title: Text(context.i18n.report),
      ),
      body: Stack(children: [
        DpipMap(
          key: mapKey,
          onMapCreated: (controller) async {
            mapController.complete(controller);
            await controller.setSymbolIconAllowOverlap(true);
            await controller.setSymbolIconIgnorePlacement(true);

            ExpTech().getReport(widget.report.id).then((data) async {
              setState(() {
                report = data;
              });

              Map<String, int> cityMaxIntensity = {};

              for (var MapEntry(key: city, value: area) in data.list.entries) {
                for (var MapEntry(key: _, value: town) in area.town.entries) {
                  map.addMarker(CustomMarker(
                    zIndex: town.intensity,
                    coordinate: LatLng(town.lat, town.lon),
                    child: IntensityMarker(
                      intensity: town.intensity,
                    ),
                  ));
                  if (cityMaxIntensity[city] == null || cityMaxIntensity[city]! < town.intensity) {
                    cityMaxIntensity[city] = town.intensity;
                  }
                }
              }

              controller.setLayerProperties(
                'county',
                FillLayerProperties(
                  fillColor: [
                    'match',
                    ['get', 'NAME_2014'],
                    ...cityMaxIntensity.entries.expand((entry) => [
                          entry.key,
                          IntensityColor.intensity(entry.value).toHexStringRGB(),
                        ]),
                    context.colors.outlineVariant.toHexStringRGB(),
                  ],
                  fillOpacity: 1,
                ),
              );
            });
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: sheetInitialSize,
            minChildSize: sheetInitialSize,
            controller: sheetController,
            snap: true,
            builder: (context, scrollController) {
              return DecoratedBoxTransition(
                decoration: animController.drive(decorationTween),
                child: Container(
                  child: refreshing == true
                      ? const Center(child: CircularProgressIndicator())
                      : report == null
                          ? Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  const Flexible(
                                    flex: 8,
                                    child: Text(
                                      "取得地震報告時發生錯誤，請檢查網路狀況後重試",
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
                          : ReportSheetContent(report: report!, controller: scrollController),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
