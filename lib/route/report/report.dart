import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:intl/intl.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:dpip/widget/map/marker/custom_marker.dart';
import 'package:dpip/widget/map/marker/intensity_marker.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
      color: context.colors.surface,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      color: context.colors.surface,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.2;
    final sheetController = DraggableScrollableController();
    final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    sheetController.addListener(() {
      final newSize = sheetController.size;
      final scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);
      animController.animateTo(scrollPosition, duration: Duration.zero);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("地震報告")),
      body: Stack(children: [
        DpipMap(
          key: mapKey,
          onMapCreated: (controller) {
            mapController.complete(controller);

            ExpTech().getReport(widget.report.id).then((data) async {
              setState(() {
                report = data;
              });

              for (var MapEntry(key: _, value: area) in data.list.entries) {
                for (var MapEntry(key: _, value: town) in area.town.entries) {
                  map.addMarker(CustomMarker(
                    zIndex: town.intensity,
                    coordinate: LatLng(town.lat, town.lon),
                    child: IntensityMarker(
                      intensity: town.intensity,
                    ),
                  ));
                }
              }
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
                  child: report == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: scrollController,
                          children: [
                            const BottomSheetDragHandle(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IntensityBox(intensity: report!.getMaxIntensity()),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.report.hasNumber ? "編號 ${widget.report.number} 顯著有感地震" : "小區域有感地震",
                                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                                          ),
                                          Text(
                                            report!.getLocation(),
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "發震時間",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('yyyy/MM/dd HH:mm:ss').format(
                                            tz.TZDateTime.fromMillisecondsSinceEpoch(
                                                tz.getLocation("Asia/Taipei"), report!.time)),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "位於",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        report!.convertLatLon(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "地震規模",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: context.colors.onSurfaceVariant,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "M ",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      "${report!.mag}",
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "震源深度",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: context.colors.onSurfaceVariant,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      "${report!.depth}",
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Text(
                                                      " km",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Text(
                                        "各地震度",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                      for (final MapEntry(key: areaName, value: area) in report!.list.entries)
                                        Column(
                                          children: [
                                            for (final MapEntry(key: townName, value: town) in area.town.entries)
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                margin: EdgeInsets.symmetric(vertical: 4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      townName,
                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      '${town.intensity}',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                  ],
                                                ),
                                              )
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
