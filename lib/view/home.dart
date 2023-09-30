import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;
bool focus_city = false;

dynamic convertIntsToDoubles(dynamic value) {
  if (value is int) {
    return value.toDouble();
  } else if (value is List) {
    return value.map(convertIntsToDoubles).toList();
  } else if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key, convertIntsToDoubles(value)),
    );
  } else {
    return value;
  }
}

LatLng _calculateCenter(List<LatLng> coordinates) {
  double minLat = coordinates[0].latitude;
  double maxLat = coordinates[0].latitude;
  double minLng = coordinates[0].longitude;
  double maxLng = coordinates[0].longitude;
  for (var coord in coordinates) {
    if (coord.latitude < minLat) {
      minLat = coord.latitude;
    } else if (coord.latitude > maxLat) {
      maxLat = coord.latitude;
    }
    if (coord.longitude < minLng) {
      minLng = coord.longitude;
    } else if (coord.longitude > maxLng) {
      maxLng = coord.longitude;
    }
  }
  return LatLng((maxLat + minLat) / 2, (maxLng + minLng) / 2);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  var data;
  late GeoJsonParser myGeoJson = GeoJsonParser(
      defaultPolygonBorderColor: Colors.grey,
      defaultPolygonFillColor: const Color(0xff3F4045));
  bool loadingData = false;
  var geojson_data;
  var radar_data;
  final MapController mapController = MapController();
  List<Polygon> polygons = [];

  List<LatLng> _cityBounds = [];

  Future<void> processData() async {
    geojson_data = await get(
        "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/tw.json");
    myGeoJson.parseGeoJsonAsString(jsonEncode(geojson_data));
    radar_data =
        List.from(await get("https://api.exptech.com.tw/file/test.json"));
    var startLat = 18.0;
    var startLon = 115.0;
    var contentIndex = 0;
    List<Color> radar_color = const [
      Color(0xFF00ffff),
      Color(0xFF00ecff),
      Color(0xFF00daff),
      Color(0xFF00c8ff),
      Color(0xFF00b6ff),
      Color(0xFF00a3ff),
      Color(0xFF0091ff),
      Color(0xFF007fff),
      Color(0xFF006dff),
      Color(0xFF005bff),
      Color(0xFF0048ff),
      Color(0xFF0036ff),
      Color(0xFF0024ff),
      Color(0xFF0012ff),
      Color(0xFF0000ff),
      Color(0xFF00ff00),
      Color(0xFF00f400),
      Color(0xFF00e900),
      Color(0xFF00de00),
      Color(0xFF00d300),
      Color(0xFF00c800),
      Color(0xFF00be00),
      Color(0xFF00b400),
      Color(0xFF00aa00),
      Color(0xFF00a000),
      Color(0xFF009600),
      Color(0xFF33ab00),
      Color(0xFF66c000),
      Color(0xFF99d500),
      Color(0xFFccea00),
      Color(0xFFffff00),
      Color(0xFFfff400),
      Color(0xFFffe900),
      Color(0xFFffde00),
      Color(0xFFffd300),
      Color(0xFFffc800),
      Color(0xFFffb800),
      Color(0xFFffa800),
      Color(0xFFff9800),
      Color(0xFFff8800),
      Color(0xFFff7800),
      Color(0xFFff6000),
      Color(0xFFff4800),
      Color(0xFFff3000),
      Color(0xFFff1800),
      Color(0xFFff0000),
      Color(0xFFf40000),
      Color(0xFFe90000),
      Color(0xFFde0000),
      Color(0xFFd30000),
      Color(0xFFc80000),
      Color(0xFFbe0000),
      Color(0xFFb40000),
      Color(0xFFaa0000),
      Color(0xFFa00000),
      Color(0xFF960000),
      Color(0xFFab0033),
      Color(0xFFc00066),
      Color(0xFFd50099),
      Color(0xFFea00cc),
      Color(0xFFff00ff),
      Color(0xFFea00ff),
      Color(0xFFd500ff),
      Color(0xFFc000ff),
      Color(0xFFab00ff),
      Color(0xFF9600ff)
    ];

    for (var y = 0; y < 881; y++) {
      var lat = startLat + y * 0.0125;

      for (var x = 0; x < 921; x++) {
        var lon = startLon + x * 0.0125;
        var dBZ = radar_data[contentIndex++];
        if (dBZ != 0) {
          if (dBZ < 0) dBZ = 0;
          polygons.add(
            Polygon(
              points: [
                LatLng(lat, lon),
                LatLng(lat + 0.0125, lon),
                LatLng(lat + 0.0125, lon + 0.0125),
                LatLng(lat, lon + 0.0125),
              ],
              color: radar_color[int.parse(dBZ.toStringAsFixed(0))],
              isFilled: true,
            ),
          );
        }
      }
    }
  }

  _selectCity(String cityName) {
    for (var feature in geojson_data["features"]) {
      if (feature['properties']['COUNTYNAME'] == cityName) {
        List coordinates = feature['geometry']['coordinates'][0];
        _cityBounds =
            coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        double minLat = _cityBounds
            .map((e) => e.latitude)
            .reduce((value, element) => value < element ? value : element);
        double maxLat = _cityBounds
            .map((e) => e.latitude)
            .reduce((value, element) => value > element ? value : element);
        double minLng = _cityBounds
            .map((e) => e.longitude)
            .reduce((value, element) => value < element ? value : element);
        double maxLng = _cityBounds
            .map((e) => e.longitude)
            .reduce((value, element) => value > element ? value : element);
        return LatLngBounds(
          LatLng(minLat - 0.05, minLng - 0.05),
          LatLng(maxLat + 0.05, maxLng + 0.05),
        );
      }
    }
    return null;
  }

  @override
  void initState() {
    loadingData = true;
    processData().then((_) {
      loadingData = false;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    init = false;
    focus_city = false;
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
      }
      _List_children = <Widget>[];
      if (_page == 0) {
        _List_children.add(
          SizedBox(
            height: 400,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: const LatLng(23.6, 120.1),
                zoom: 7,
                minZoom: 6,
                maxZoom: 10,
                interactiveFlags: InteractiveFlag.all - InteractiveFlag.all,
              ),
              children: [
                PolygonLayer(polygons: myGeoJson.polygons),
                PolylineLayer(polylines: myGeoJson.polylines),
                PolygonLayer(polygons: polygons),
                PolygonLayer(polygons: [
                  Polygon(
                    points: _cityBounds,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2.0,
                  )
                ]),
              ],
            ),
          ),
        );
        if (!focus_city && !loadingData) {
          if (prefs.getString('loc-city') != null &&
              prefs.getString('loc-town') != null) {
            focus_city = true;
            Future.delayed(const Duration(seconds: 1), () {
              mapController
                  .fitBounds(_selectCity(prefs.getString('loc-city') ?? ""));
            });
          }
        }
      } else {
        _List_children.add(
          SizedBox(
            height: 400,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: const LatLng(23.6, 120.1),
                zoom: 7,
                minZoom: 6,
                maxZoom: 10,
              ),
              children: [
                PolygonLayer(polygons: myGeoJson.polygons),
                PolylineLayer(polylines: myGeoJson.polylines),
                PolygonLayer(polygons: polygons),
              ],
            ),
          ),
        );
        if (!focus_city) {
          focus_city = true;
          mapController.move(const LatLng(23.6, 120.1), 7);
        }
      }
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
                  Row(
                    children: [
                      Text(
                        prefs.getString("loc-city") ?? "",
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        prefs.getString("loc-town") ?? "",
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ));
            _List_children.add(Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff333439),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sunny, color: Colors.white, size: 50),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "40",
                              style: TextStyle(
                                fontSize: 50,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              ".1°C",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "降雨機率 10%",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w100,
                                color: Colors.white),
                          ),
                          Text(
                            "預估氣溫 28 ~ 36°C",
                            style: TextStyle(
                                fontSize: 16,
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
                    ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data["all"][i]["title"],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red[900],
                            borderRadius: BorderRadius.circular(5), // 設置圓角
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Text(
                              "最大震度 6強",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      data["all"][i]["body"],
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
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
                        (_page == 1) ? Colors.blue[800] : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      focus_city = false;
                      _page = 1;
                    });
                  },
                  child: const Text(
                    "全國",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_page == 0) ? Colors.blue[800] : Colors.transparent,
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    setState(() {
                      focus_city = false;
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
