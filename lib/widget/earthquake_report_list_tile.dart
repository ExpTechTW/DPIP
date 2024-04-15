import 'dart:io';

import 'package:dpip/core/utils.dart';
import 'package:dpip/model/partial_earthquake_report.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/mag_color.dart';
import 'package:dpip/view/report.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class EarthquakeReportListTile extends StatelessWidget {
  final PartialEarthquakeReport report;

  const EarthquakeReportListTile({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoListTile(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        leading: Icon(
          report.getNumber() != null ? CupertinoIcons.tag : CupertinoIcons.info_circle,
          color: report.getNumber() != null
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        title: Text(report.getLocation()),
        subtitle: Text(
          DateFormat("yyyy/MM/dd HH:mm:ss").format(
            TZDateTime.fromMillisecondsSinceEpoch(
              getLocation("Asia/Taipei"),
              report.time,
            ),
          ),
        ),
        additionalInfo: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: report.mag.getMagnitudeColor(),
              ),
              child: Center(
                child: Text(
                  "${report.mag}", // 顯示地震規模
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: report.mag.getMagColor(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: context.colors.intensity(report.intensity),
              ),
              child: Center(
                child: Text(
                  intensityToNumberString(report.intensity),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onIntensity(report.intensity),
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
        leading: Icon(report.getNumber() != null ? Icons.tag_rounded : Icons.info_outline_rounded),
        iconColor: report.getNumber() != null ? context.colors.onSurfaceVariant : context.colors.outline,
        title: Text(report.getLocation()),
        subtitle: Text(
          DateFormat("yyyy/MM/dd HH:mm:ss").format(
            TZDateTime.fromMillisecondsSinceEpoch(
              getLocation("Asia/Taipei"),
              report.time,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: report.mag.getMagnitudeColor(),
              ),
              child: Center(
                child: Text(
                  "${report.mag}", // 顯示地震規模
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: report.mag.getMagColor(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: context.colors.intensity(report.intensity),
              ),
              child: Center(
                child: Text(
                  intensityToNumberString(report.intensity),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onIntensity(report.intensity),
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
