import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/util/depth_color.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/magnitude_color.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:dpip/widget/report/report_detail_field.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportSheetContent extends StatelessWidget {
  final ScrollController controller;
  final EarthquakeReport report;

  const ReportSheetContent({
    super.key,
    required this.report,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      controller: controller,
      children: [
        const BottomSheetDragHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              IntensityBox(intensity: report.getMaxIntensity()),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.hasNumber ? "編號 ${report.number} 顯著有感地震" : "小區域有感地震",
                    style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                  ),
                  Text(
                    report.getLocation(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Expanded(child: Container()),
              ActionChip(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                avatar: const Icon(Symbols.link),
                label: const Text("報告頁面"),
                onPressed: () {
                  launchUrl(Uri.parse(
                      "https://www.cwa.gov.tw/V8/C/E/EQ/EQ${report.id.substring(0, 6)}${report.id.substring(11)}.html"));
                },
              ),
            ],
          ),
        ),
        const Divider(),
        ReportDetailField(
          label: "發震時間",
          child: Text(
            DateFormat('yyyy/MM/dd HH:mm:ss').format(
              TZDateTime.fromMillisecondsSinceEpoch(
                getLocation("Asia/Taipei"),
                report.time,
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
            report.convertLatLon(),
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
                        color: MagnitudeColor.magnitude(report.mag),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "M ${report.mag}",
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
                        color: DepthColor.depth(report.depth),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      "${report.depth} km",
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
              for (final MapEntry(key: areaName, value: area) in report.list.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(areaName),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final MapEntry(key: townName, value: town) in area.town.entries)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: context.colors.outline),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            child: Text(townName),
                                          ),
                                          AspectRatio(
                                            aspectRatio: 1,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(6),
                                                color: IntensityColor.intensity(town.intensity),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  town.intensity.asIntensityDisplayLabel,
                                                  style: TextStyle(
                                                    height: 1,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: IntensityColor.onIntensity(town.intensity),
                                                  ),
                                                ),
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
                ),
            ],
          ),
        ),
      ],
    );
  }
}
