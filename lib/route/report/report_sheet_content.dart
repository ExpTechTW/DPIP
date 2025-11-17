import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/utils/depth_color.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:dpip/utils/magnitude_color.dart';
import 'package:dpip/widgets/list/detail_field_tile.dart';
import 'package:dpip/widgets/report/enlargeable_image.dart';
import 'package:dpip/widgets/report/intensity_box.dart';
import 'package:dpip/widgets/sheet/bottom_sheet_drag_handle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportSheetContent extends StatelessWidget {
  final ScrollController controller;
  final EarthquakeReport report;
  final void Function(LatLng target) focus;

  const ReportSheetContent({super.key, required this.report, required this.controller, required this.focus});

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
                      report.hasNumber ? '編號 ${report.number} 顯著有感地震' : '小區域有感地震',
                      style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                    ),
                    Text(report.getLocation(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              avatar: Icon(Symbols.open_in_new, color: context.colors.onPrimary),
              label: const Text('報告頁面'),
              backgroundColor: context.colors.primary,
              labelStyle: TextStyle(color: context.colors.onPrimary),
              side: BorderSide(color: context.colors.primary),
              onPressed: () {
                launchUrl(report.reportUrl);
              },
            ),
            /* ActionChip(
              avatar: const Icon(Symbols.replay),
              label: Text('重播'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapMonitorPage(data: report.time.millisecondsSinceEpoch - 5000),
                  ),
                );
              },
            ), */
          ],
        ),
        const Divider(),
        DetailFieldTile(
          label: '發震時間',
          child: Text(
            DateFormat('yyyy/MM/dd HH:mm:ss').format(report.time),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        DetailFieldTile(
          label: '位於',
          child: Text(report.convertLatLon(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(
              child: DetailFieldTile(
                label: '地震規模',
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
                    Text('M ${report.magnitude}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: DetailFieldTile(
                label: '震源深度',
                child: Row(
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: getDepthColor(report.depth),
                      ),
                    ),
                    Text('${report.depth} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Divider(),
        DetailFieldTile(
          label: '各地震度',
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
                            child: Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                    backgroundColor: IntensityColor.intensity(town.intensity).withValues(alpha: 0.16),
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
        const Divider(),
        DetailFieldTile(
          label: '地震報告圖',
          child: EnlargeableImage(
            aspectRatio: 4 / 3,
            heroTag: 'report-image-${report.id}',
            imageUrl: report.reportImageUrl,
            imageName: report.reportImageName,
          ),
        ),
        if (report.hasNumber)
          DetailFieldTile(
            label: '震度圖',
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: 'intensity-image-${report.id}',
              imageUrl: report.intensityMapImageUrl!,
              imageName: report.intensityMapImageName!,
            ),
          ),
        if (report.hasNumber)
          DetailFieldTile(
            label: '最大地動加速度圖',
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: 'pga-image-${report.id}',
              imageUrl: report.pgaMapImageUrl!,
              imageName: report.pgaMapImageName!,
            ),
          ),
        if (report.hasNumber)
          DetailFieldTile(
            label: '最大地動速度圖',
            child: EnlargeableImage(
              aspectRatio: 2334 / 2977,
              heroTag: 'pgv-image-${report.id}',
              imageUrl: report.pgvMapImageUrl!,
              imageName: report.pgvMapImageName!,
            ),
          ),
      ],
    );
  }
}
