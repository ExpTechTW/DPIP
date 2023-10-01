import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dpip/core/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool init = false;
bool focus_city = false;
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
List<Polygon> polygons = [];
late GeoJsonParser myGeoJson = GeoJsonParser(
    defaultPolygonBorderColor: Colors.grey,
    defaultPolygonFillColor: const Color(0xff3F4045));
bool loadingData = false;
var geojson_data;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  int _page = 0;
  List<Widget> _List_children = <Widget>[];
  var data;
  var radar_data;
  MapController mapController = MapController();
  var pic_0;
  var pic_1;
  var loc_data;
  var loc_gps;

  List<Polygon> _cityBounds = [];
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _capturePng() async {
    if (_globalKey.currentContext == null) return;
    final boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    if (_page == 0) {
      pic_0 = Image.memory(pngBytes);
    } else {
      pic_1 = Image.memory(pngBytes);
    }
  }

  Future<void> processData() async {
    geojson_data = await get(
        "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/tw.json");
    if (geojson_data != false) {
      myGeoJson.parseGeoJsonAsString(jsonEncode(geojson_data));
      loadingData = false;
    }
  }

  void radar_f() async {
    var radar_get = await get("https://api.exptech.com.tw/file/test.json");
    if (radar_get == false) return;
    radar_data = List.from(radar_get);
    var startLat = 18.0;
    var startLon = 115.0;
    var contentIndex = 0;
    for (var y = 0; y < 881; y++) {
      var lat = startLat + y * 0.0125;
      for (var x = 0; x < 921; x++) {
        var lon = startLon + x * 0.0125;
        var dBZ = radar_data[contentIndex++];
        if (dBZ != 0) {
          List<LatLng> loc = [
            LatLng(lat, lon),
            LatLng(lat + 0.0125, lon),
            LatLng(lat + 0.0125, lon + 0.0125),
            LatLng(lat, lon + 0.0125),
          ];
          // if (bounds != null && !isPolygonInBounds(loc, bounds)) continue;
          if (dBZ < 0) dBZ = 0;
          polygons.add(
            Polygon(
              points: loc,
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
        List Coord = feature['geometry']['coordinates'];
        List coordinates = [];
        for (var i = 0; i < Coord.length; i++) {
          for (var I = 0; I < Coord[i].length; I++) {
            if (Coord[i][I].length == 2) {
              coordinates.add(Coord[i][I]);
              List<LatLng> _bounds = List<LatLng>.from(
                  Coord[i].map((coord) => LatLng(coord[1], coord[0])));
              _cityBounds.add(Polygon(
                points: _bounds,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ));
            } else {
              for (var _I = 0; _I < Coord[i][I].length; _I++) {
                coordinates.add(Coord[i][I][_I]);
              }
              List<LatLng> _bounds = List<LatLng>.from(
                  Coord[i][I].map((coord) => LatLng(coord[1], coord[0])));
              _cityBounds.add(Polygon(
                points: _bounds,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ));
            }
          }
        }

        var _Bounds =
            coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        double minLat = _Bounds.map((e) => e.latitude)
            .reduce((value, element) => value < element ? value : element);
        double maxLat = _Bounds.map((e) => e.latitude)
            .reduce((value, element) => value > element ? value : element);
        double minLng = _Bounds.map((e) => e.longitude)
            .reduce((value, element) => value < element ? value : element);
        double maxLng = _Bounds.map((e) => e.longitude)
            .reduce((value, element) => value > element ? value : element);
        return LatLngBounds(
          LatLng(minLat - 0.08, minLng - 0.08),
          LatLng(maxLat + 0.08, maxLng + 0.08),
        );
      }
    }
    return null;
  }

  @override
  void initState() {
    loadingData = true;
    processData();
    super.initState();
  }

  @override
  void dispose() {
    init = false;
    focus_city = false;
    pic_0 = null;
    pic_1 = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _List_children = <Widget>[];
      if (!init) {
        loc_data = await get(
            "https://cdn.jsdelivr.net/gh/ExpTechTW/TREM-Lite@Release/src/resource/data/region.json");
        var loc_info = loc_data[prefs.getString("loc-city") ?? "臺南市"]
            [prefs.getString("loc-town") ?? "歸仁區"];
        loc_gps = LatLng(loc_info["lat"], loc_info["lon"]);
        data = await get(
            "https://api.exptech.com.tw/api/v1/dpip/home?city=${prefs.getString('loc-city') ?? "臺南市"}&town=${prefs.getString('loc-town') ?? "歸仁區"}");
        if (data != false) init = true;
        radar_f();
        print(data);
      }
      if (_page == 0) {
        if (pic_0 == null) {
          if (!focus_city && !loadingData) {
            LatLngBounds bounds =
                _selectCity(prefs.getString('loc-city') ?? "臺南市");
            if (mounted) {
              mapController.fitBounds(bounds);
              focus_city = true;
            }
          }
        }
      } else {
        if (pic_1 == null) {
          if (mounted && !focus_city) {
            mapController.move(const LatLng(23.4, 120.1), 6.5);
            focus_city = true;
          }
        }
      }
      if (data == false || data["info"] == null) {
        focus_city = true;
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
          _List_children.add(Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      prefs.getString("loc-city") ?? "臺南市",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      prefs.getString("loc-town") ?? "歸仁區",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      data["info"]["str"],
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        size: 50),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "降雨機率 ${data["info"]["cor"]}%",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w100,
                              color: Colors.white),
                        ),
                        Text(
                          "預估氣溫 ${data["info"]["temp_l"]} ~ ${data["info"]["temp_h"]}°C",
                          style: const TextStyle(
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
                      data["loc"][i]["time"],
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
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
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
      if ((pic_0 == null || pic_1 == null) &&
          radar_data != null &&
          !loadingData &&
          focus_city) {
        _capturePng();
      }
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_page == 1)
                              ? Colors.blue[800]
                              : Colors.transparent,
                          elevation: 20,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          focus_city = false;
                          _page = 1;
                          setState(() {});
                        },
                        child: const Text(
                          "全國",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_page == 0)
                              ? Colors.blue[800]
                              : Colors.transparent,
                          elevation: 20,
                          splashFactory: NoSplash.splashFactory,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          focus_city = false;
                          _page = 0;
                          setState(() {});
                        },
                        child: const Text(
                          "所在地",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ((_page == 0 && pic_0 == null) ||
                            _page == 1 && pic_1 == null)
                        ? RepaintBoundary(
                            key: _globalKey,
                            child: FlutterMap(
                              key: ValueKey(_page),
                              mapController: mapController,
                              options: MapOptions(
                                center: const LatLng(23.4, 120.1),
                                zoom: 6.5,
                                interactiveFlags:
                                    InteractiveFlag.all - InteractiveFlag.all,
                              ),
                              children: [
                                PolygonLayer(polygons: myGeoJson.polygons),
                                PolylineLayer(polylines: myGeoJson.polylines),
                                if (_page == 0)
                                  PolygonLayer(polygons: _cityBounds),
                                PolygonLayer(polygons: polygons),
                                if (loc_gps != null)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        width: 15,
                                        height: 15,
                                        point: loc_gps,
                                        builder: (ctx) => const Icon(
                                          Icons.gps_fixed_outlined,
                                          size: 15,
                                          color: Colors.pinkAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          )
                        : (_page == 0)
                            ? pic_0
                            : pic_1,
                  ),
                ],
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.45,
              maxChildSize: 1.0,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  color: Colors.black.withOpacity(1),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(overscroll: false),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _List_children.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _List_children[index];
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
    );
  }
}
