import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  var data;
  late GeoJsonParser myGeoJson;
  bool loadingData = false;

  Future<void> processData() async {
    var geojson_data = await get(
        "https://raw.githubusercontent.com/ExpTechTW/TREM-Lite/Release/src/resource/maps/tw.json");
    myGeoJson.parseGeoJsonAsString(jsonEncode(geojson_data));
  }

  @override
  void initState() {
    loadingData = true;
    processData().then((_) {
      setState(() {
        loadingData = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    init = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!init) {
        data = await get(
            "https://exptech.com.tw/api/v1/dpip/alert?city=${prefs.getString('loc-city')}&town=${prefs.getString('loc-town')}");
        if (data != false) init = true;
        print(data);

        myGeoJson = GeoJsonParser(
            defaultPolygonBorderColor: Colors.red,
            defaultPolygonFillColor: Colors.red.withOpacity(0.1));
      }
      _List_children = <Widget>[];
      if (data == false) {
        _List_children.add(const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "服務異常",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w100, color: Colors.red),
            ),
            Text(
              "稍等片刻後重試 如持續異常 請回報開發人員",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ));
      } else {
        if (_page == 0) {
          if (prefs.getString('loc-town') == null) {
            _List_children.add(const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "服務區域外",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w100,
                      color: Colors.white),
                ),
                Text(
                  "無法取得相關資訊 可能是因為尚未設定所在地位置",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
              ],
            ));
          } else {
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${prefs.getString("loc-city")} ${prefs.getString("loc-town")}",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w100,
                        color: Colors.white),
                  )
                ],
              ),
            ));
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sunny, color: Colors.white, size: 60),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Text(
                          "40°C",
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "降水量 0.0mm",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Colors.white),
                          ),
                          Text(
                            "濕度 90%",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w100,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
            if (data["loc"].length == 0) {
              _List_children.add(const Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      "暫無生效中的防災資訊",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    )
                  ],
                ),
              ));
            } else {
              for (var i = 0; i < data["loc"].length; i++) {
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                        data["all"][i]["time"],
                        isUtc: true)
                    .add(const Duration(hours: 8));
                String formattedDate =
                    '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
                _List_children.add(Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: double.infinity),
                      Text(
                        data["all"][i]["title"],
                        style: TextStyle(
                            fontSize: 20,
                            color: (data["all"][i]["type"] == 2)
                                ? Colors.red
                                : (data["all"][i]["type"] == 1)
                                    ? Colors.amber
                                    : Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formattedDate,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        data["all"][i]["body"],
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      )
                    ],
                  ),
                ));
              }
            }
          }
        } else {
          _List_children.add(Container(
            color: Colors.black,
            child: FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                center: const LatLng(45.993807, 14.483972),
                zoom: 14,
              ),
              children: [
                PolygonLayer(
                  polygons: myGeoJson.polygons,
                ),
                PolylineLayer(polylines: myGeoJson.polylines),
              ],
            ),
          ));
          // _List_children.add(
          //     Image.network("https://exptech.com.tw/api/v1/weather/radar"));
          if (data["all"].length == 0) {
            _List_children.add(const Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: double.infinity),
                  Text(
                    "暫無生效中的防災資訊",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ],
              ),
            ));
          } else {
            for (var i = 0; i < data["all"].length; i++) {
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                      data["all"][i]["time"],
                      isUtc: true)
                  .add(const Duration(hours: 8));
              String formattedDate =
                  '${dateTime.year}年${formatNumber(dateTime.month)}月${formatNumber(dateTime.day)}日 ${formatNumber(dateTime.hour)}:${formatNumber(dateTime.minute)} 發布';
              _List_children.add(Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: double.infinity),
                    Text(
                      data["all"][i]["title"],
                      style: TextStyle(
                          fontSize: 20,
                          color: (data["all"][i]["type"] == 2)
                              ? Colors.red
                              : (data["all"][i]["type"] == 1)
                                  ? Colors.amber
                                  : Colors.white,
                          fontWeight: FontWeight.w600),
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
      if (!mounted) return;
      setState(() {});
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_page == 1) ? Colors.blueAccent : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      _page = 1;
                    });
                  },
                  child: const Text(
                    "全國",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 35),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_page == 0) ? Colors.blueAccent : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      _page = 0;
                    });
                  },
                  child: const Text(
                    "所在地",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                  padding: const EdgeInsets.all(0),
                  children: _List_children.toList()),
            ),
          ],
        ),
      ),
    );
  }
}
