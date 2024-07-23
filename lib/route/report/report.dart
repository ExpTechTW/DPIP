import 'dart:async';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/depth_color.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/magnitude_color.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:dpip/widget/map/marker/custom_marker.dart';
import 'package:dpip/widget/map/marker/intensity_marker.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:dpip/widget/report/report_detail_field.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:timezone/timezone.dart' as tz;

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
      appBar: AppBar(title: Text(context.i18n.report)),
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

              String getIntensityColor(int intensity) {
                switch (intensity) {
                  case 9:
                    return IntensityColor.intensity9.toHexStringRGB();
                  case 8:
                    return IntensityColor.intensity8.toHexStringRGB();
                  case 7:
                    return IntensityColor.intensity7.toHexStringRGB();
                  case 6:
                    return IntensityColor.intensity6.toHexStringRGB();
                  case 5:
                    return IntensityColor.intensity5.toHexStringRGB();
                  case 4:
                    return IntensityColor.intensity4.toHexStringRGB();
                  case 3:
                    return IntensityColor.intensity3.toHexStringRGB();
                  case 2:
                    return IntensityColor.intensity2.toHexStringRGB();
                  case 1:
                    return IntensityColor.intensity1.toHexStringRGB();
                  default:
                    return context.colors.surfaceContainerHighest.toHexStringRGB();
                }
              }

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
                      getIntensityColor(entry.value),
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
                                                  color: MagnitudeColor.magnitude(report!.mag),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "M ${report!.mag}",
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
                                                  color: DepthColor.depth(report!.depth),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "${report!.depth} km",
                                                style: const TextStyle(
                                                  fontSize: 18,
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
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      areaName,
                                                      style: const TextStyle(fontSize: 16),
                                                    ),
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
                                                                      town.intensity.asIntensityLabel,
                                                                      // "5+",
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
