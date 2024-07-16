import 'dart:ffi';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/page/map/tsunami_estimate_list.dart';
import 'package:dpip/app/page/map/tsunami_observed_list.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../model/tsunami/tsunami.dart';

class TsunamiMap extends StatefulWidget {
  const TsunamiMap({super.key});
  @override
  State<StatefulWidget> createState() => _TsunamiMapState();
}

class _TsunamiMapState extends State<TsunamiMap> {
  Tsunami? tsunami;
  String tsunamiStatus = "";
  bool refreshingTsunami = true;
  refreshTsunami() async {
    refreshingTsunami = true;
    var idList = await ExpTech().getTsunamiList();
    var id = "";
    if (idList.isNotEmpty) {
      id = idList[2];
      tsunami = await ExpTech().getTsunami(id);
      (tsunami?.status == 0)
          ? tsunamiStatus = "發布"
          : (tsunami?.status == 1)
              ? tsunamiStatus = "更新"
              : tsunamiStatus = "解除";
    }
    setState(() {
      refreshingTsunami = false;
    });
    return tsunami;
  }

  convertTimestamp(int timestamp) {
    var location = tz.getLocation('Asia/Taipei');
    DateTime dateTime = tz.TZDateTime.fromMillisecondsSinceEpoch(location, timestamp);

    DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm');
    String formattedDate = formatter.format(dateTime);
    return formattedDate;
  }

  convertLatLon(double lat, double lon) {
    var latFormat = "";
    var lonFormat = "";
    if (lat > 90) {
      lat = lat - 180;
    }
    if (lon > 180) {
      lat = lat - 360;
    }
    if (lat < 0) {
      latFormat = "南緯 ${lat.abs()} 度";
    } else {
      latFormat = "北緯 $lat 度";
    }
    if (lon < 0) {
      lonFormat = "西經 ${lon.abs()} 度";
    } else {
      lonFormat = "東經 $lon 度";
    }
    return "$latFormat　$lonFormat";
  }

  @override
  void initState() {
    super.initState();
    refreshTsunami();
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.2;
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: sheetInitialSize,
        minChildSize: sheetInitialSize,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            color: context.colors.surface.withOpacity(0.9),
            child: ListView(
              controller: scrollController,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: refreshingTsunami == true
                      ? Container()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tsunami == null ? "近期無海嘯資訊" : "海嘯警報",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: context.colors.onSurface,
                              ),
                            ),
                            tsunami != null
                                ? Text(
                                    "${tsunami?.id}號 第${tsunami?.serial}報",
                                    style: TextStyle(
                                      fontSize: 14,
                                      letterSpacing: 1,
                                      color: context.colors.onSurface,
                                    ),
                                  )
                                : Container(),
                            Text(
                              "2024/07/01 00:00 $tsunamiStatus",
                              style: TextStyle(
                                fontSize: 14,
                                letterSpacing: 1,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            tsunami != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${tsunami?.content}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          letterSpacing: 2,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      tsunami?.info.type == "estimate"
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "預估海嘯到達時間及波高",
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                TsunamiEstimateList(tsunamiList: tsunami!.info.data),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "各地觀測到的海嘯",
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                TsunamiObservedList(tsunamiList: tsunami!.info.data),
                                              ],
                                            ),
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        "地震資訊",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: context.colors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "發生時間",
                                            style: TextStyle(
                                              fontSize: 18,
                                              letterSpacing: 2,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                          Text(
                                            convertTimestamp(tsunami!.eq.time),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "震央",
                                            style: TextStyle(
                                              fontSize: 18,
                                              letterSpacing: 2,
                                              color: context.colors.onSurface,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                tsunami!.eq.loc,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                  color: context.colors.onSurface,
                                                ),
                                              ),
                                              Text(
                                                convertLatLon(tsunami!.eq.lat, tsunami!.eq.lon),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                  color: context.colors.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "規模",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  "${tsunami!.eq.mag}",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "深度",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  "${tsunami!.eq.depth}km",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                    color: context.colors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Container(),
                          ],
                        ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
