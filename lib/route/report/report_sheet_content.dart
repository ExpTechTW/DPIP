import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/util/depth_color.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/magnitude_color.dart';
import 'package:dpip/widget/report/enlargeable_image.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:dpip/widget/report/report_detail_field.dart';
import 'package:dpip/widget/sheet/bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportSheetContent extends StatelessWidget {
  final ScrollController controller;
  final EarthquakeReport report;
  final void Function(LatLng target) focus;

  const ReportSheetContent({
    super.key,
    required this.report,
    required this.controller,
    required this.focus,
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
              Expanded(
                child: Column(
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
              ),
              IconButton(
                icon: const Icon(Symbols.open_in_new),
                tooltip: "報告頁面",
                onPressed: () {
                  launchUrl(report.cwaUrl);
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
                      height: 12,
                      width: 12,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: MagnitudeColor.magnitude(report.mag),
                      ),
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
                      height: 12,
                      width: 12,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: DepthColor.depth(report.depth),
                      ),
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
                            child: Text(
                              areaName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final MapEntry(key: townName, value: town) in area.town.entries)
                                  ActionChip(
                                    padding: const EdgeInsets.all(4),
                                    side: BorderSide(color: IntensityColor.intensity(town.intensity)),
                                    backgroundColor: IntensityColor.intensity(town.intensity).withOpacity(0.16),
                                    avatar: AspectRatio(
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
                                    label: Text(townName),
                                    onPressed: () => focus(LatLng(town.lat, town.lon)),
                                  )
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
        const Divider(),
        ReportDetailField(
          label: "地震報告圖",
          child: EnlargeableImage(
            aspectRatio: 4 / 3,
            heroTag: "report-image-${report.id}",
            imageUrl: report.reportImageUrl,
            imageName: report.reportImageName,
          ),
        ),
        if (report.hasNumber)
          ReportDetailField(
            label: "震度圖",
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: "intensity-image-${report.id}",
              imageUrl: report.intensityMapImageUrl!,
              imageName: report.intensityMapImageName!,
            ),
          ),
        if (report.hasNumber)
          ReportDetailField(
            label: "最大地動加速度圖",
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: "pga-image-${report.id}",
              imageUrl: report.pgaMapImageUrl!,
              imageName: report.pgaMapImageName!,
            ),
          ),
        if (report.hasNumber)
          ReportDetailField(
            label: "最大地動速度圖",
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: "pgv-image-${report.id}",
              imageUrl: report.pgvMapImageUrl!,
              imageName: report.pgvMapImageName!,
            ),
          )
      ],
    );
  }
}
