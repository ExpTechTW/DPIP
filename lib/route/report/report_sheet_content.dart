import 'package:dpip/app/page/monitor/monitor.dart';
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
      padding: EdgeInsets.only(bottom: context.padding.bottom).copyWith(left: 16, right: 16),
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
                      report.hasNumber
                          ? context.i18n.report_with_number(report.number!)
                          : context.i18n.report_without_number,
                      style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                    ),
                    Text(
                      report.getLocation(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Wrap(
          direction: Axis.horizontal,
          spacing: 8,
          children: [
            Visibility(
              visible: report.magnitude >= 6 && report.magnitude < 7 && report.getLocation().contains("海"),
              child: ActionChip(
                avatar: const Icon(Symbols.tsunami_rounded, color: Colors.white),
                label: const Text("可能引起若干海面變動"),
                backgroundColor: Colors.blue.withOpacity(0.16),
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                side: const BorderSide(color: Colors.blue),
                onPressed: () {},
              ),
            ),
            Visibility(
              visible: report.magnitude >= 7 && report.getLocation().contains("海"),
              child: ActionChip(
                avatar: const Icon(Symbols.tsunami_rounded, color: Colors.white),
                label: const Text("可能引起海嘯 應注意後續資訊"),
                backgroundColor: Colors.red.withOpacity(0.16),
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                side: const BorderSide(color: Colors.red),
                onPressed: () {},
              ),
            ),
          ],
        ),
        Wrap(
          direction: Axis.horizontal,
          spacing: 8,
          children: [
            ActionChip(
              avatar: Icon(Symbols.open_in_new, color: context.colors.onPrimary),
              label: Text(context.i18n.open_report_url),
              backgroundColor: context.colors.primary,
              labelStyle: TextStyle(color: context.colors.onPrimary),
              side: BorderSide(color: context.colors.primary),
              onPressed: () {
                launchUrl(report.reportUrl);
              },
            ),
            ActionChip(
              avatar: const Icon(Symbols.replay),
              label: const Text("重播"),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => MonitorPage(data: report.time.millisecondsSinceEpoch - 5000)),
                );
              },
            ),
          ],
        ),
        const Divider(),
        ReportDetailField(
          label: context.i18n.report_event_time,
          child: Text(
            DateFormat(context.i18n.datetime_format).format(report.time),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ReportDetailField(
          label: context.i18n.report_location,
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
                label: context.i18n.report_magnitude,
                child: Row(
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: MagnitudeColor.magnitude(report.magnitude),
                      ),
                    ),
                    Text(
                      "M ${report.magnitude}",
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
                label: context.i18n.report_depth,
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
          label: context.i18n.report_intensity,
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
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              areaName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final MapEntry(key: townName, value: town) in area.town.entries)
                                  ActionChip(
                                    padding: const EdgeInsets.all(4),
                                    side: BorderSide(color: IntensityColor.intensity(town.intensity)),
                                    backgroundColor: IntensityColor.intensity(town.intensity).withOpacity(0.16),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          label: context.i18n.report_image,
          child: EnlargeableImage(
            aspectRatio: 4 / 3,
            heroTag: "report-image-${report.id}",
            imageUrl: report.reportImageUrl,
            imageName: report.reportImageName,
          ),
        ),
        if (report.hasNumber)
          ReportDetailField(
            label: context.i18n.report_intensity_image,
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: "intensity-image-${report.id}",
              imageUrl: report.intensityMapImageUrl!,
              imageName: report.intensityMapImageName!,
            ),
          ),
        if (report.hasNumber)
          ReportDetailField(
            label: context.i18n.report_pga_image,
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: "pga-image-${report.id}",
              imageUrl: report.pgaMapImageUrl!,
              imageName: report.pgaMapImageName!,
            ),
          ),
        if (report.hasNumber)
          ReportDetailField(
            label: context.i18n.report_pgv_image,
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
