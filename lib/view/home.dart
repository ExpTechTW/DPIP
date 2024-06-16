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
                            // interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
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
