import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../core/utils.dart';
import '../model/partial_earthquake_report.dart';
import '../util/intensity_color.dart';
import '../view/home_page.dart';
import '../view/report.dart';

class HomePageInfo extends StatelessWidget {
  // final List eqReport;
  //
  // const HomePageInfo({Key? key, required this.eqReport}) : super(key: key);
  final PartialEarthquakeReport eqReport;

  final Map cityMaxInt;

  final bool cityIntRefreshing;

  HomePageInfo({super.key, required this.cityMaxInt, required this.eqReport, required this.cityIntRefreshing});

  Cal calculator = Cal();

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      bool isIpad = MediaQuery.of(context).size.shortestSide >= 600;
      if (isIpad) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ReportPage(report: eqReport),
                  ),
                );
              },
              child: Container(
                width: 1300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0x50808080),
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 12,
                          decoration: BoxDecoration(
                            color: eqReport.hasNumber ? const Color(0x99FFB400) : const Color(0x9919C8C8),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 30,
                          right: 25,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 3,
                                bottom: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                  Text(
                                    DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                      TZDateTime.fromMillisecondsSinceEpoch(
                                        getLocation("Asia/Taipei"),
                                        eqReport.time,
                                      ),
                                    ),
                                    // style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),
                                    style: TextStyle(
                                        color: Color.lerp(
                                            CupertinoColors.label.resolveFrom(context), const Color(0xFF808080), 0.5),
                                        fontSize: 30),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                    style: const TextStyle(fontSize: 34, letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                bottom: 2,
                              ),
                              child:Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: IntensityColor.intensity(eqReport.intensity),
                                    ),
                                    child: Text(
                                      intensityToNumberString(eqReport.intensity),
                                      style: TextStyle(
                                        fontSize: 76,
                                        fontWeight: FontWeight.w900,
                                        color: IntensityColor.onIntensity(eqReport.intensity),
                                      ),
                                    ),
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
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        );
      } else {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => ReportPage(report: eqReport),
                  ),
                );
              },
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0x50808080),
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 8,
                          decoration: BoxDecoration(
                            color: eqReport.hasNumber ? const Color(0x99FFB400) : const Color(0x9919C8C8),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 3,
                                bottom: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                  Text(
                                    DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                      TZDateTime.fromMillisecondsSinceEpoch(
                                        getLocation("Asia/Taipei"),
                                        eqReport.time,
                                      ),
                                    ),
                                    // style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),
                                    style: TextStyle(
                                        color: Color.lerp(
                                            CupertinoColors.label.resolveFrom(context), const Color(0xFF808080), 0.5),
                                        fontSize: 16),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                bottom: 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: IntensityColor.intensity(eqReport.intensity),
                                    ),
                                    child: Text(
                                      intensityToNumberString(eqReport.intensity),
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: IntensityColor.onIntensity(eqReport.intensity),
                                      ),
                                    ),
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
              ),
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        );
      }
    } else {
      return Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(report: eqReport),
                ),
              );
            },
            child: Container(
              // width: calculator.percentToPixel(90, context),
              // height: calculator.percentToPixel(25, context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0x30808080),
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 8,
                        decoration: BoxDecoration(
                          color: eqReport.hasNumber ? const Color(0x99FFB400) : const Color(0x9919C8C8),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 3,
                              bottom: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                                ),
                                Text(
                                  DateFormat("yyyy/MM/dd HH:mm:ss").format(
                                    TZDateTime.fromMillisecondsSinceEpoch(
                                      getLocation("Asia/Taipei"),
                                      eqReport.time,
                                    ),
                                  ),
                                  // style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),

                                  style: TextStyle(
                                      color: Color.lerp(context.colors.onSurface, const Color(0xFF808080), 0.5),
                                      fontSize: 16),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                  style: const TextStyle(fontSize: 18, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 2,
                              bottom: 2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: IntensityColor.intensity(eqReport.intensity),
                                  ),
                                  child: Text(
                                    intensityToNumberString(eqReport.intensity),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: IntensityColor.onIntensity(eqReport.intensity),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      );
    }
  }
}
