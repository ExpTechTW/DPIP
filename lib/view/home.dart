import 'dart:convert';

import 'package:dpip/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

GlobalKey<HomePageState> homePageKey = GlobalKey();

var prefs;
var loc_data;
var loc_gps;
var data;
bool focus_map = false;
var img;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _page = 0;
  List<Widget> _listchildren = <Widget>[];
  MapController mapController = MapController();
  final GlobalKey _globalKey = GlobalKey();
  String url = "";

  @override
  void dispose() {
    data = null;
    img = null;
    super.dispose();
  }

  @override
  void initState() {
    render();
    super.initState();
  }

  LatLng offsetLatLng(LatLng original, double offset) {
    double newLatitude = original.latitude + offset;
    if (newLatitude > 90) {
      newLatitude = 90;
    } else if (newLatitude < -90) {
      newLatitude = -90;
    }
    return LatLng(newLatitude, original.longitude);
  }

  void render() async {
    prefs ??= await SharedPreferences.getInstance();
    data ??= await get(
        "https://api.exptech.com.tw/api/v1/dpip/home?city=${prefs.getString('loc-city') ?? "臺南市"}&town=${prefs.getString('loc-town') ?? "歸仁區"}");
    loc_data ??= json.decode(await rootBundle.loadString('assets/region.json'));
    var loc_info = loc_data[prefs.getString("loc-city") ?? "臺南市"][prefs.getString("loc-town") ?? "歸仁區"];
    loc_gps = LatLng(loc_info["lat"], loc_info["lon"]);
    focus_map = false;
    _listchildren = <Widget>[];
    if (data == null || data == false || data["info"] == null) {
      _listchildren.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              //滑動標示
              child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.5),
            ),
          )),
          const Text(
            "服務異常",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w100, color: Colors.red),
          ),
          const Text(
            "稍等片刻後重試 如持續異常 請回報開發人員",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ));
    } else {
      if (_page == 0) {
        _listchildren.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                //滑動標示
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    prefs.getString("loc-city") ?? "臺南市",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    prefs.getString("loc-town") ?? "歸仁區",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.grey),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    data["info"]["str"],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
        ));
        _listchildren.add(Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff333439),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                      (data["info"]["icon"] == 0)
                          ? Icons.sunny
                          : (data["info"]["icon"] == 1)
                              ? Icons.cloudy_snowing
                              : (data["info"]["icon"] == 2)
                                  ? Icons.sunny_snowing
                                  : Icons.cloud,
                      color: Colors.white,
                      size: 45),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          data["info"]["temp"].split(".")[0],
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          ".${data["info"]["temp"].split(".")[1]}°C",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "降水量",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: Colors.white),
                          ),
                          Text(
                            "濕度",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w100, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${data["info"]["rainfall"]}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            "${data["info"]["humidity"]}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "mm",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100, color: Colors.white),
                          ),
                          Text(
                            "%",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
        if (data["loc"].length == 0) {
          _listchildren.add(const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: double.infinity),
                Text(
                  "暫無 生效中的 防災資訊",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ));
        } else {
          for (var i = 0; i < data["loc"].length; i++) {
            DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(data["loc"][i]["time"], isUtc: true).add(const Duration(hours: 8));
            String formattedDate =
                '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
            _listchildren.add(Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  Row(
                    children: [
                      Icon(
                        (data["loc"][i]["type"] == 2)
                            ? Icons.warning_amber_outlined
                            : (data["loc"][i]["type"] == 1)
                                ? Icons.doorbell_outlined
                                : Icons.speaker_notes_outlined,
                        color: (data["loc"][i]["type"] == 2)
                            ? Colors.red
                            : (data["loc"][i]["type"] == 1)
                                ? Colors.amber
                                : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data["loc"][i]["title"],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    data["loc"][i]["body"],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          }
        }
      } else {
        _listchildren.add(Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  //滑動標示
                  child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              )),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "全國",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              )
            ],
          ),
        ));

        if (data["all"].length == 0) {
          _listchildren.add(const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: double.infinity),
                Text(
                  "暫無 生效中的 防災資訊",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ),
          ));
        } else {
          for (var i = 0; i < data["all"].length; i++) {
            DateTime dateTime =
                DateTime.fromMillisecondsSinceEpoch(data["all"][i]["time"], isUtc: true).add(const Duration(hours: 8));
            String formattedDate =
                '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
            _listchildren.add(Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: double.infinity),
                  Row(
                    children: [
                      Icon(
                        (data["all"][i]["type"] == 2)
                            ? Icons.warning_amber_outlined
                            : (data["all"][i]["type"] == 1)
                                ? Icons.doorbell_outlined
                                : Icons.speaker_notes_outlined,
                        color: (data["all"][i]["type"] == 2)
                            ? Colors.red
                            : (data["all"][i]["type"] == 1)
                                ? Colors.amber
                                : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data["all"][i]["title"],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    data["all"][i]["body"],
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!focus_map && loc_gps != null) {
        focus_map = true;
        if (mounted) {
          if (_page == 0) {
            mapController.move(
              offsetLatLng(loc_gps, -0.5),
              9,
            );
          } else {
            mapController.move(
              const LatLng(22, 120.5),
              7,
            );
          }
          setState(() {});
        }
      }
    });
    if (url == "") {
      String time_str = formatToUTC(adjustTime(TimeOfDay.now(), 10));
      url =
          "https://watch.ncdr.nat.gov.tw/00_Wxmap/7F13_NOWCAST/${time_str.substring(0, 6)}/${time_str.substring(0, 8)}/$time_str/nowcast_${time_str}_f00.png";
      if (TimeOfDay.now().minute % 10 > 5) url = url.replaceAll("f00", "f01");
      render();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              if (_page == 0) {
                _page = 1;
                render();
              }
            } else if (details.primaryVelocity! < 0) {
              if (_page == 1) {
                _page = 0;
                render();
              }
            }
          },
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_page == 1) ? Colors.blue[800] : Colors.transparent,
                            elevation: 20,
                            splashFactory: NoSplash.splashFactory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            _page = 1;
                            render();
                          },
                          child: const Text(
                            "全國",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_page == 0) ? Colors.blue[800] : Colors.transparent,
                            elevation: 20,
                            splashFactory: NoSplash.splashFactory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            _page = 0;
                            render();
                          },
                          child: const Text(
                            "所在地",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        key: _globalKey,
                        child: FlutterMap(
                          key: ValueKey(_page),
                          mapController: mapController,
                          options: const MapOptions(
                            initialCenter: LatLng(23.4, 120.1),
                            initialZoom: 7,
                            minZoom: 7,
                            maxZoom: 9,
                            interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://api.mapbox.com/styles/v1/whes1015/clne7f5m500jd01re1psi1cd2/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid2hlczEwMTUiLCJhIjoiY2xuZTRhbmhxMGIzczJtazN5Mzg0M2JscCJ9.BHkuZTYbP7Bg1U9SfLE-Cg",
                            ),
                            if (url != "")
                              OverlayImageLayer(
                                overlayImages: [
                                  OverlayImage(
                                    bounds: LatLngBounds(
                                      const LatLng(21.2446, 117.1595),
                                      const LatLng(26.5153, 123.9804),
                                    ),
                                    imageProvider: NetworkImage(url),
                                  ),
                                ],
                              ),
                            if (loc_gps != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 15,
                                    height: 15,
                                    point: loc_gps,
                                    child: const Icon(
                                      Icons.gps_fixed_outlined,
                                      size: 15,
                                      color: Colors.pinkAccent,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 1.0,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _listchildren.length,
                          itemBuilder: (BuildContext context, int index) {
                            return _listchildren[index];
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:dpip/view/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../core/utils.dart';
import '../global.dart';
import '../model/partial_earthquake_report.dart';
import '../util/dist_code.dart';
import '../util/intensity_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class Areas {
  static List<String> getOptions(currentArea) {
    return [currentArea, '花蓮縣 萬榮鄉', '臺北市 中正區']; // 鄉鎮列表
  }
}

class Cal {
  double percentToPixel(double percent, BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return percent / 100 * screenWidth;
  }
}

Future<int?> getZipCodeForArea(String area) async {
  final data = await DistCodeUtil.readJsonFile();
  return DistCodeUtil.getZipCode(area, data);
}
// class IntColor {
//   static const Map<int, Color> _colors = {
//     0: Color(0xff202020),
//     1: Color(0xff003264),
//     2: Color(0xff0064c8),
//     3: Color(0xff1e9632),
//     4: Color(0xffffc800),
//     5: Color(0xffff9600),
//     6: Color(0xffff6400),
//     7: Color(0xffff0000),
//     8: Color(0xffc00000),
//     9: Color(0xff9600c8),
//   };
//
//   Color intColor(int intensity) {
//     return _colors[intensity] ?? Color(0xFF202020);
//   }
// }

class TempColor {
  List<Color> tempColors = [
    const Color(0xFF006060),
    const Color(0xFF00AFAF),
    const Color(0xFF00FFFF),
    const Color(0xFF3AAA50),
    const Color(0xFFFFFF00),
    const Color(0xFFFF8A00),
    const Color(0xFFFF0000),
    const Color(0xFFFF00CA),
    const Color(0xFF6040B0),
  ];

  Color getColorForTemp(double temp) {
    const double minTemp = 0;
    const double maxTemp = 40;

    if (temp == -99.9) {
      return const Color(0xFF808080);
    } else if (temp <= minTemp) {
      return const Color(0xFF006060);
    } else if (temp >= maxTemp) {
      return const Color(0xFF6040B0);
    } else {
      double t = ((temp - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
      int index = (t * (tempColors.length - 1)).floor();
      double localT = (t * (tempColors.length - 1)) - index;

      return Color.lerp(tempColors[index], tempColors[index + 1 < tempColors.length ? index + 1 : index], localT)!;
    }
  }
}

class EqInfo extends StatelessWidget {
  // final List eqReport;
  //
  // const EqInfo({Key? key, required this.eqReport}) : super(key: key);
  final PartialEarthquakeReport eqReport;

  EqInfo({super.key, required this.eqReport});

  Cal calculator = Cal();

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
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
              width: MediaQuery.of(context).size.width * 0.9,
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
                        width: MediaQuery.of(context).size.width * 0.02,
                        decoration: BoxDecoration(
                          color: eqReport.hasNumber ? const Color(0xFFC09010) : const Color(0xFF20AAAA),
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
                          Column(
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
                                style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: context.colors.intensity(eqReport.intensity),
                            ),
                            child: Text(
                              intensityToNumberString(eqReport.intensity),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: CupertinoColors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.005,
          ),
        ],
      );
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
                          color: eqReport.hasNumber ? const Color(0xFFC09010) : const Color(0xFF20AAAA),
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
                          Column(
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
                                style: const TextStyle(color: Color(0xFFc9c9c9), fontSize: 16),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                "規模${eqReport.mag}　深度${eqReport.depth}公里",
                                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: calculator.percentToPixel(15, context),
                            height: calculator.percentToPixel(15, context),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: context.colors.intensity(eqReport.intensity),
                            ),
                            child: Text(
                              intensityToNumberString(eqReport.intensity),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: context.colors.onIntensity(eqReport.intensity),
                              ),
                            ),
                          )
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

class _HomePage extends State<HomePage> with AutomaticKeepAliveClientMixin<HomePage> {
  late String _selectedArea;
  List<PartialEarthquakeReport> reports = [];
  var weather = {
    'temp': "-99.9",
    'feel': "-99.9",
    'humidity': "-99.9",
    'precip': "-99.9",
    'update': 0.0,
    'isday': 1,
    'condition': 0,
  };
  List eqReport = [];
  bool weatherRefreshing = true;
  bool eqReportRefreshing = true;
  late Cal calculator;
  late TempColor tempToColor;
  final ScrollController _controller = ScrollController();
  var distCode = 100;
  String? currentCity = Global.preference.getString("loc-city");
  String? currentTown = Global.preference.getString("loc-town");
  String currentArea = "";

  Future<void> refreshWeather(context) async {
    weatherRefreshing = true;
    setState(() {});
    try {
      distCode = (await getZipCodeForArea(_selectedArea))!;
      final weatherData = await Global.api.getWeatherRealtime("$distCode");
      weather = {
        'temp': weatherData.temp.c.toString(),
        'feel': weatherData.feel.c.toString(),
        'humidity': weatherData.humidity.toString(),
        'precip': weatherData.precip.mm.toString(),
        'update': weatherData.update,
        'isday': weatherData.isday.round(),
        'condition': weatherData.condition.round(),
      };
    } catch (e) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const CupertinoAlertDialog(
              content: Center(
                child: Text(
                  "取得天氣資料時發生錯誤",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '取得天氣資料時發生錯誤\n$e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xAA202020),
          ),
        );
      }
    }
    weatherRefreshing = false;
    setState(() {});
  }

  Future<void> refreshEqReport(context) async {
    setState(() {});
    eqReportRefreshing = true;
    try {
      final eqReportData = await Global.api.getReportList(limit: 10);
      eqReport = eqReportData;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '取得地震資料時發生錯誤\n$e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xAA202020),
        ),
      );
    }
    eqReportRefreshing = false;
    setState(() {});
  }

  void updateArea() {
    if (currentCity != null) {
      currentArea = "$currentCity $currentTown";
    } else {
      currentArea = "臺北市 中正區";
    }
  }

  void scrollToTop() {
    _controller.animateTo(
      0,
      duration: const Duration(seconds: 2),
      curve: Easing.standard,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tempToColor = TempColor();
    calculator = Cal();
    updateArea();
    _selectedArea = Areas.getOptions(currentArea).toSet().first;
    refreshWeather(context);
    refreshEqReport(context);
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.minScrollExtent) {
        setState(() {
          weatherRefreshing = false;
        });
      } else {
        setState(() {
          weatherRefreshing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (Platform.isIOS) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(
            middle: Text("首頁"),
          ),
          child: SafeArea(
            child: CustomScrollView(controller: _controller, slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.wait([
                    refreshWeather(context),
                    refreshEqReport(context),
                  ]);
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CupertinoSegmentedControl<String>(
                        children: {
                          for (var item in Areas.getOptions(currentArea))
                            item: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                        },
                        onValueChanged: (String newArea) {
                          setState(() {
                            _selectedArea = newArea;
                          });
                        },
                        groupValue: _selectedArea,
                      ),
                      const Divider(color: Colors.white),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        if (weatherRefreshing && weather["temp"] != "-99.9")
                          const Positioned.fill(
                            child: Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                        if (weather["temp"] == "-99.9")
                          const Positioned.fill(
                            child: Center(
                              child: Text("天氣取得失敗"),
                            ),
                          ),
                        Container(),
                        Opacity(
                          opacity: weatherRefreshing || weather["temp"] == "-99.9" ? 0 : 1,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: calculator.percentToPixel(45, context),
                              ),
                              Positioned(
                                bottom: calculator.percentToPixel(0, context),
                                right: 0,
                                left: 0,
                                child: Column(
                                  children: [
                                    Container(
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.transparent,
                                            tempToColor.getColorForTemp(double.parse(weather["temp"] as String)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: calculator.percentToPixel(6, context),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          bottom: calculator.percentToPixel(2, context),
                                          left: calculator.percentToPixel(5, context),
                                          right: calculator.percentToPixel(5, context),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "更新時間：${DateFormat("MM/dd HH:mm").format(
                                                TZDateTime.fromMillisecondsSinceEpoch(
                                                  getLocation("Asia/Taipei"),
                                                  (weather["update"] as double).round() * 1000,
                                                ),
                                              )}",
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            const Text(
                                              "天氣資料來自 weather.com",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: calculator.percentToPixel(5, context),
                                      ),
                                      SizedBox(
                                        width: calculator.percentToPixel(35, context),
                                        child: Image.network(
                                          'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                                          width: calculator.percentToPixel(35, context),
                                          height: calculator.percentToPixel(35, context),
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(
                                              child: CupertinoActivityIndicator(),
                                            );
                                          },
                                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                            return Container();
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: calculator.percentToPixel(0, context),
                                      ),
                                      SizedBox(
                                        width: calculator.percentToPixel(55, context),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: calculator.percentToPixel(10, context),
                                                ),
                                                SizedBox(
                                                  width: calculator.percentToPixel(45, context),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text("降水量", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["precip"]} mm",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text("濕度", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["humidity"]} %",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          const Text("體感", style: TextStyle(fontSize: 20)),
                                                          Text(
                                                            "${weather["feel"]} ℃",
                                                            style: const TextStyle(
                                                                fontSize: 20, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  (weather["temp"] as String).split(".")[0],
                                                  style: const TextStyle(
                                                    fontSize: 96,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 5,
                                                    shadows: [
                                                      Shadow(
                                                        offset: Offset(5, 5),
                                                        blurRadius: 20,
                                                        color: Color.fromARGB(120, 0, 0, 0),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    const Text(
                                                      "℃",
                                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      ".${(weather["temp"] as String).split(".")[1]}",
                                                      style: const TextStyle(
                                                        fontSize: 48,
                                                        fontWeight: FontWeight.w900,
                                                        shadows: [
                                                          Shadow(
                                                            offset: Offset(5, 5),
                                                            blurRadius: 20,
                                                            color: Color.fromARGB(120, 0, 0, 0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: calculator.percentToPixel(4.5, context),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: calculator.percentToPixel(5, context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white),
                  ],
                ),
              ),
              eqReportRefreshing == false
                  ? eqReport.isEmpty
                  ? SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: calculator.percentToPixel(5, context),
                    right: calculator.percentToPixel(5, context),
                    top: calculator.percentToPixel(5, context),
                  ),
                  child: const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "近期設定區域無地震或警特報資訊",
                          style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    return EqInfo(eqReport: eqReport[index]);
                  },
                  childCount: eqReport.length,
                ),
              )
                  : const SliverFillRemaining(
                child: Center(
                  child: CupertinoActivityIndicator(),
                ),
              ),
            ]),
          ),
        ),
      );
    } else {
      return MediaQuery(
        // Set textScaleFactor to 1.0 to ignore system font size settings
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    "首頁",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedArea, // 當前選中的值
                    icon: const Icon(Icons.navigate_next), // 下拉箭頭圖標
                    onChanged: (String? newArea) {
                      setState(() {
                        _selectedArea = newArea!;
                      });
                      refreshWeather(context);
                      refreshEqReport(context);
                    },
                    items: Areas.getOptions(currentArea).toSet().map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
            body: Column(
              children: [
                Stack(
                  children: [
                    // height: calculator.percentToPixel(60, context),

                    weatherRefreshing == true
                        ? const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ))
                        : weather["temp"] == "-99.9"
                        ? const Positioned.fill(
                        child: Center(
                          child: Text("天氣取得失敗"),
                        ))
                        : Container(),
                    Opacity(
                      opacity: weatherRefreshing == true || weather["temp"] == "-99.9" ? 0 : 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: calculator.percentToPixel(45, context)),
                          Positioned(
                            bottom: calculator.percentToPixel(0, context),
                            right: 0,
                            left: 0,
                            child: Column(
                              children: [
                                Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        tempToColor.getColorForTemp(double.parse(weather["temp"] as String)),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: calculator.percentToPixel(6, context),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        bottom: calculator.percentToPixel(2, context),
                                        left: calculator.percentToPixel(5, context),
                                        right: calculator.percentToPixel(5, context)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "更新時間：${DateFormat("MM/dd HH:mm").format(
                                            TZDateTime.fromMillisecondsSinceEpoch(
                                              getLocation("Asia/Taipei"),
                                              (weather["update"] as double).round() * 1000,
                                            ),
                                          )}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const Text(
                                          "天氣資料來自 weather.com",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(height: calculator.percentToPixel(3, context)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: calculator.percentToPixel(5, context)),
                                  // Icon(
                                  //   weatherIcon.getWeatherIcon(weather["isday"], weather["condition"]),
                                  //   size: calculator.percentToPixel(35, context),
                                  // ),
                                  SizedBox(
                                    width: calculator.percentToPixel(35, context),
                                    child: Image.network(
                                      'https://cdn.weatherapi.com/weather/128x128/${weather["isday"] == 1 ? "day" : "night"}/${(weather["condition"] as int) - 887}.png',
                                      width: calculator.percentToPixel(35, context),
                                      height: calculator.percentToPixel(35, context),
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                        return Container();
                                      },
                                    ),
                                  ),
                                  SizedBox(width: calculator.percentToPixel(0, context)),
                                  SizedBox(
                                    width: calculator.percentToPixel(55, context),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: calculator.percentToPixel(10, context),
                                            ),
                                            SizedBox(
                                              width: calculator.percentToPixel(45, context),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("降水量", style: TextStyle(fontSize: 20)),
                                                      Text(
                                                        "${weather["precip"]} mm",
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("濕度", style: TextStyle(fontSize: 20)),
                                                      Text(
                                                        "${weather["humidity"]} %",
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text("體感", style: TextStyle(fontSize: 20)),
                                                      Text(
                                                        "${weather["feel"]} ℃",
                                                        style:
                                                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              (weather["temp"] as String).split(".")[0],
                                              style: const TextStyle(
                                                fontSize: 96,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 5,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(5, 5),
                                                    blurRadius: 20,
                                                    color: Color.fromARGB(120, 0, 0, 0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  "℃",
                                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  ".${(weather["temp"] as String).split(".")[1]}",
                                                  style: const TextStyle(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.w900,
                                                    shadows: [
                                                      Shadow(
                                                        offset: Offset(5, 5),
                                                        blurRadius: 20,
                                                        color: Color.fromARGB(120, 0, 0, 0),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: calculator.percentToPixel(4.5, context),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: calculator.percentToPixel(5, context)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1.5,
                  color: Colors.white,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: calculator.percentToPixel(5, context),
                      right: calculator.percentToPixel(5, context),
                      top: calculator.percentToPixel(5, context),
                    ),
                    child: eqReportRefreshing == false
                        ? eqReport.isEmpty
                        ? RefreshIndicator(
                      onRefresh: () async {
                        // 使用 Future.wait 來同時等待多個異步操作完成
                        await Future.wait([
                          refreshWeather(context),
                          refreshEqReport(context),
                        ]);
                      },
                      child: const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "近期設定區域無地震或警特報資訊",
                              style: TextStyle(fontSize: 16, letterSpacing: 2, color: Color(0xFFC9C9C9)),
                            ),
                          ],
                        ),
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: () async {
                        // 使用 Future.wait 來同時等待多個異步操作完成
                        await Future.wait([
                          refreshWeather(context),
                          refreshEqReport(context),
                        ]);
                      },
                      child: ListView.builder(
                        itemCount: eqReport.length,
                        itemBuilder: (context, index) {
                          return EqInfo(eqReport: eqReport[index]);
                        },
                        // shrinkWrap: true,
                      ),
                    )
                        : const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
