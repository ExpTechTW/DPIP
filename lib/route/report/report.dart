import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/widget/report/report_detail_field.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:intl/intl.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:dpip/widget/map/marker/custom_marker.dart';
import 'package:dpip/widget/map/marker/intensity_marker.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../util/intensity_color.dart';

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
                                  ReportDetailField(
                                    label: "發震時間",
                                    child: Text(
                                      DateFormat('yyyy/MM/dd HH:mm:ss').format(
                                        tz.TZDateTime.fromMillisecondsSinceEpoch(
                                          tz.getLocation("Asia/Taipei"),
                                          report!.time,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ReportDetailField(
                                    label: "位於",
                                    child: Text(
                                      report!.convertLatLon(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ReportDetailField(
                                          label: "地震規模",
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: report!.getMagnitudeColor(),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
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
                                        ),
                                      ),
                                      Expanded(
                                        child: ReportDetailField(
                                          label: "震源深度",
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: report!.getDepthColor(),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
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
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  ReportDetailField(
                                    label: "各地震度",
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        for (final MapEntry(key: areaName, value: area) in report!.list.entries)
                                          Column(
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 5),
                                                    child: Text(areaName),
                                                  ),
                                                  const SizedBox(
                                                    width: 20,
                                                  ),
                                                  Expanded(
                                                    child: Wrap(
                                                      children: [
                                                        for (final MapEntry(key: townName, value: town)
                                                            in area.town.entries)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                                            margin: const EdgeInsets.symmetric(
                                                              vertical: 2,
                                                              horizontal: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: Colors.grey),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: IntrinsicWidth(
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    townName,
                                                                    style: const TextStyle(
                                                                        fontSize: 16, fontWeight: FontWeight.bold),
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                                                    decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(10),
                                                                      color: IntensityColor.intensity(town.intensity),
                                                                    ),
                                                                    child: Text(
                                                                      '${town.intensity}',
                                                                      style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.bold,
                                                                        color:
                                                                            IntensityColor.onIntensity(town.intensity),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
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
