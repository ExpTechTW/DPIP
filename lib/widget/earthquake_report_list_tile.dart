import 'dart:io';

import 'package:dpip/core/utils.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/magnitude_color.dart';
import 'package:dpip/view/report.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:timezone/timezone.dart';

class EarthquakeReportListTile extends StatelessWidget {
  final PartialEarthquakeReport report;

  const EarthquakeReportListTile({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoListTile(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        leading: Icon(
          report.hasNumber ? CupertinoIcons.tag : CupertinoIcons.info_circle,
          color: report.hasNumber
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        title: Text(report.getLocation()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat("yyyy/MM/dd HH:mm:ss").format(
                TZDateTime.fromMillisecondsSinceEpoch(
                  getLocation("Asia/Taipei"),
                  report.time,
                ),
              ),
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 13,
              ),
            ),
            Text(
              "深度 ${report.depth} km",
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        additionalInfo: Row(
          children: [
            Text(
              "M ${report.mag}", // 顯示地震規模
              style: TextStyle(
                fontSize: 18,
                color: context.colors.magnitude(context, report.mag),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox.square(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: IntensityColor.intensity(report.intensity),
                ),
                child: Center(
                  child: Text(
                    intensityToNumberString(report.intensity),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: IntensityColor.onIntensity(report.intensity),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ReportPage(report: report),
            ),
          );
        },
      );
    } else {
      return ListTile(
        isThreeLine: true,
        titleAlignment: ListTileTitleAlignment.center,
        leading: Icon(
          report.hasNumber ? Symbols.sell_rounded : Symbols.info_rounded,
          weight: report.hasNumber ? 700 : 400,
        ),
        iconColor: report.hasNumber ? context.colors.onSurfaceVariant : context.colors.outline,
        title: Text(
          report.hasNumber ? "第 ${report.number!.substring(3)} 號有感地震" : report.getLocation(),
          style: TextStyle(fontWeight: report.hasNumber ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(
          "${DateFormat("yyyy/MM/dd HH:mm:ss").format(
            TZDateTime.fromMillisecondsSinceEpoch(
              getLocation("Asia/Taipei"),
              report.time,
            ),
          )}\n深度 ${report.depth} km",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "M ${report.mag}", // 顯示地震規模
              style: TextStyle(
                fontSize: 18,
                color: context.colors.magnitude(context, report.mag),
              ),
            ),
            const SizedBox(width: 16),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: IntensityColor.intensity(report.intensity),
                ),
                child: Center(
                  child: Text(
                    intensityToNumberString(report.intensity),
                    style: TextStyle(
                      height: 1,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: IntensityColor.onIntensity(report.intensity),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportPage(report: report),
            ),
          );
        },
      );
    }
  }
}
