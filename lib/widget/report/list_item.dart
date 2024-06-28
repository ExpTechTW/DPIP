import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class ReportListItem extends StatelessWidget {
  final PartialEarthquakeReport report;
  final double height;
  final bool showDate;

  const ReportListItem({
    super.key,
    required this.report,
    this.showDate = false,
    this.height = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: IntensityColor.intensity(report.intensity).withOpacity(0.16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              /**
               * 時間
               */
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showDate)
                      Text(
                        DateFormat("yyyy/MM/dd").format(
                          TZDateTime.fromMillisecondsSinceEpoch(
                            getLocation("Asia/Taipei"),
                            report.time,
                          ),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      DateFormat("HH:mm:ss").format(
                        TZDateTime.fromMillisecondsSinceEpoch(
                          getLocation("Asia/Taipei"),
                          report.time,
                        ),
                      ),
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 2,
                      height: height,
                      color: context.colors.outlineVariant, // Color of the vertical line
                    ),
                    IntensityBox(
                      intensity: report.intensity,
                      size: 36,
                      borderRadius: 36,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  // 16 for keeping 8 pixel as vertical paddings
                  height: height - 16,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        IntensityColor.intensity(report.intensity).withOpacity(0),
                        IntensityColor.intensity(report.intensity).withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /**
                       * 位置
                       */
                      Text(
                        report.extractLocation(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      /**
                       * 規模、深度
                       */
                      Text(
                        "M ${report.mag.toStringAsFixed(1)}　深度 ${report.depth} km",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
