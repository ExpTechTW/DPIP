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
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        leading: Icon(
          report.hasNumber ? CupertinoIcons.tag : CupertinoIcons.info_circle,
          color: report.hasNumber
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
            Text(
              "M ${report.mag}", // 顯示地震規模
              style: TextStyle(
                fontSize: 20,
                color: context.colors.magnitude(context, report.mag),
              ),
            ),
            const SizedBox(width: 8),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: context.colors.intensity(report.intensity),
                ),
                child: Center(
                  child: Text(
                    intensityToNumberString(report.intensity),
                    style: TextStyle(
                      height: 1,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onIntensity(report.intensity),
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
          )}\n規模 ${report.mag}  深度 ${report.depth} km",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "M ${report.mag}", // 顯示地震規模
              style: TextStyle(
                fontSize: 20,
                color: context.colors.magnitude(context, report.mag),
              ),
            ),
            const SizedBox(width: 16),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: context.colors.intensity(report.intensity),
                ),
                child: Center(
                  child: Text(
                    intensityToNumberString(report.intensity),
                    style: TextStyle(
                      height: 1,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onIntensity(report.intensity),
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
