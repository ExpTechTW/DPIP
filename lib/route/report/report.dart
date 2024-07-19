import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/map/map.dart';
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
      appBar: AppBar(
        title: Text(widget.report.hasNumber ? "編號 ${widget.report.number}" : "小區域有感地震"),
      ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  IntensityBox(intensity: report!.getMaxIntensity()),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report!.getLocation(),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
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
