import "package:dpip/api/model/report/partial_earthquake_report.dart";
import "package:dpip/route/report/report.dart";
import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/intensity_color.dart";
import "package:dpip/widgets/report/intensity_box.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

class ReportListItem extends StatelessWidget {
  final PartialEarthquakeReport report;
  final double height;
  final bool showDate;
  final bool first;
  final Function refreshReportList;

  const ReportListItem({
    super.key,
    required this.report,
    required this.refreshReportList,
    this.showDate = false,
    this.height = 88,
    this.first = false,
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
                width: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showDate)
                      Text(
                        DateFormat(context.i18n.date_format).format(report.time),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      DateFormat(context.i18n.time_format).format(report.time),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (first)
                      Padding(
                        padding: EdgeInsets.only(top: height / 2),
                        child: Container(
                          width: 2,
                          height: first ? height / 2 : height,
                          color: context.colors.outlineVariant, // Color of the vertical line
                        ),
                      )
                    else
                      Container(
                        width: 2,
                        height: first ? height / 2 : height,
                        color: context.colors.outlineVariant, // Color of the vertical line
                      ),
                    IntensityBox(intensity: report.intensity, size: 36, borderRadius: 36, border: !report.hasNumber),
                  ],
                ),
              ),
              // Text(report.hasNumber ? report.number! : "小區域"),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /**
                     * 位置
                     */
                    Text(
                      report.extractLocation(),
                      style: TextStyle(
                        fontSize: report.hasNumber ? 20 : 18,
                        fontWeight: report.hasNumber ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    /**
                     * 規模、深度
                     */
                    Text(
                      context.i18n.report_list_item_subtitle(
                        report.magnitude.toStringAsFixed(1),
                        report.depth.toString(),
                      ),
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ReportRoute(id: report.id);
              },
            ),
          );
          refreshReportList();
        },
      ),
    );
  }
}
