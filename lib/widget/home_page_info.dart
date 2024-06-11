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
                width: MediaQuery.of(context).size.width * 0.92,
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
                          width: MediaQuery.of(context).size.width * 0.02,
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
                        padding: EdgeInsets.only(
                          left: calculator.percentToPixel(5, context),
                          right: calculator.percentToPixel(5, context),
                          top: calculator.percentToPixel(1, context),
                          bottom: calculator.percentToPixel(1.5, context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: calculator.percentToPixel(1, context),
                                bottom: calculator.percentToPixel(1, context),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eqReport.loc.substring(0, eqReport.loc.length - 1).split("位於")[1],
                                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
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
                                        fontSize: 32),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                    style: const TextStyle(fontSize: 36, letterSpacing: 2),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: MediaQuery.of(context).size.width * 0.12,
                                  height: MediaQuery.of(context).size.width * 0.12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
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
                                // cityIntRefreshing == true
                                //     ? Container(
                                //         alignment: Alignment.center,
                                //         width: calculator.percentToPixel(8, context),
                                //         height: calculator.percentToPixel(8, context),
                                //         decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //             color: const Color(0xFF202020)),
                                //         child: Text(
                                //           "--",
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(0),
                                //           ),
                                //         ),
                                //       )
                                //     : Container(
                                //         alignment: Alignment.center,
                                //         width: MediaQuery.of(context).size.width * 0.08,
                                //         height: MediaQuery.of(context).size.width * 0.08,
                                //         decoration: BoxDecoration(
                                //           borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //           color: cityMaxInt[eqReport.id] == 0
                                //               ? const Color(0xFF202020)
                                //               : context.colors.intensity(cityMaxInt[eqReport.id]),
                                //         ),
                                //         child: Text(
                                //           intensityToNumberString(cityMaxInt[eqReport.id]),
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(cityMaxInt[eqReport.id]),
                                //           ),
                                //         ),
                                //       ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
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
                width: MediaQuery.of(context).size.width * 0.92,
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
                          width: MediaQuery.of(context).size.width * 0.02,
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
                        padding: EdgeInsets.only(
                          left: calculator.percentToPixel(5, context),
                          right: calculator.percentToPixel(5, context),
                          top: calculator.percentToPixel(1, context),
                          bottom: calculator.percentToPixel(2, context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: calculator.percentToPixel(1, context),
                                bottom: calculator.percentToPixel(2, context),
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
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: MediaQuery.of(context).size.width * 0.15,
                                  height: MediaQuery.of(context).size.width * 0.15,
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
                                // cityIntRefreshing == true
                                //     ? Container(
                                //         alignment: Alignment.center,
                                //         width: calculator.percentToPixel(8, context),
                                //         height: calculator.percentToPixel(8, context),
                                //         decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //             color: const Color(0xFF202020)),
                                //         child: Text(
                                //           "--",
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(0),
                                //           ),
                                //         ),
                                //       )
                                //     : Container(
                                //         alignment: Alignment.center,
                                //         width: MediaQuery.of(context).size.width * 0.08,
                                //         height: MediaQuery.of(context).size.width * 0.08,
                                //         decoration: BoxDecoration(
                                //           borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //           color: cityMaxInt[eqReport.id] == 0
                                //               ? const Color(0xFF202020)
                                //               : context.colors.intensity(cityMaxInt[eqReport.id]),
                                //         ),
                                //         child: Text(
                                //           intensityToNumberString(cityMaxInt[eqReport.id]),
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(cityMaxInt[eqReport.id]),
                                //           ),
                                //         ),
                                //       ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
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
              width: calculator.percentToPixel(90, context),
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
                        width: calculator.percentToPixel(2, context),
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
                      padding: EdgeInsets.only(
                        left: calculator.percentToPixel(5, context),
                        right: calculator.percentToPixel(2, context),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: calculator.percentToPixel(1, context),
                              bottom: calculator.percentToPixel(2, context),
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
                            padding: EdgeInsets.only(
                              top: calculator.percentToPixel(1, context),
                              bottom: calculator.percentToPixel(1, context),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  width: calculator.percentToPixel(15, context),
                                  height: calculator.percentToPixel(15, context),
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
                                // SizedBox(
                                //   height: calculator.percentToPixel(1, context),
                                // ),
                                // cityIntRefreshing == true
                                //     ? Container(
                                //         alignment: Alignment.center,
                                //         width: calculator.percentToPixel(8, context),
                                //         height: calculator.percentToPixel(8, context),
                                //         decoration: BoxDecoration(
                                //             borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //             color: const Color(0xFF202020)),
                                //         child: Text(
                                //           "--",
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(0),
                                //           ),
                                //         ),
                                //       )
                                //     : Container(
                                //         alignment: Alignment.center,
                                //         width: calculator.percentToPixel(8, context),
                                //         height: calculator.percentToPixel(8, context),
                                //         decoration: BoxDecoration(
                                //           borderRadius: BorderRadius.circular(calculator.percentToPixel(8, context)),
                                //           color: cityMaxInt[eqReport.id] == 0
                                //               ? const Color(0xFF202020)
                                //               : context.colors.intensity(cityMaxInt[eqReport.id]),
                                //         ),
                                //         child: Text(
                                //           intensityToNumberString(cityMaxInt[eqReport.id]),
                                //           style: TextStyle(
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.w900,
                                //             color: context.colors.onIntensity(cityMaxInt[eqReport.id]),
                                //           ),
                                //         ),
                                //       ),
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
          SizedBox(
            height: calculator.percentToPixel(2, context),
          ),
        ],
      );
    }
  }
}
