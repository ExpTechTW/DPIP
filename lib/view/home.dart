import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:dpip/view/history.dart';
import 'package:flutter/material.dart';
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
  var loc_data;
  var loc_gps;

  List<Polygon> _cityBounds = [];
  final GlobalKey _globalKey = GlobalKey();

  Future<void> processData() async {
    geojson_data = await get(
        "https://cdn.jsdelivr.net/gh/ExpTechTW/API@master/resource/tw.json");
    if (geojson_data != false) {
      myGeoJson.parseGeoJsonAsString(jsonEncode(geojson_data));
      loadingData = false;
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
                borderStrokeWidth: 3,
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
        print(data);
      }
      if (_page == 0) {
        if (!focus_city && !loadingData) {
          LatLngBounds bounds =
              _selectCity(prefs.getString('loc-city') ?? "臺南市");
          if (mounted) {
            mapController.fitBounds(
              bounds,
              options: const FitBoundsOptions(
                padding: EdgeInsets.only(bottom: 350),
              ),
            );
            focus_city = true;
          }
        }
      } else {
        if (mounted && !focus_city) {
          mapController.move(
            const LatLng(21.6, 120.1),
            6.5,
          );
          focus_city = true;
        }
      }
      if (data == null || data == false || data["info"] == null) {
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
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff333439),
                borderRadius: BorderRadius.circular(10),
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
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white),
                            ),
                            Text(
                              "濕度",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${data["info"]["rainfall"]}",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            Text(
                              "${data["info"]["humidity"]}",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "mm",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white),
                            ),
                            Text(
                              "%",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white),
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
            _List_children.add(const Padding(
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
          _List_children.add(const Padding(
            padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "全國",
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ));
          if (data["all"].length == 0) {
            _List_children.add(const Padding(
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
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              if (_page == 0) {
                focus_city = false;
                _page = 1;
                setState(() {});
              }
            } else if (details.primaryVelocity! < 0) {
              if (_page == 1) {
                focus_city = false;
                _page = 0;
                setState(() {});
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
                      child: RepaintBoundary(
                        key: _globalKey,
                        child: FlutterMap(
                          key: ValueKey(_page),
                          mapController: mapController,
                          options: MapOptions(
                            center: const LatLng(23.4, 120.1),
                            zoom: 6.5,
                            minZoom: 6,
                            maxZoom: 10,
                          ),
                          children: [
                            PolygonLayer(polygons: myGeoJson.polygons),
                            PolylineLayer(polylines: myGeoJson.polylines),
                            if (_page == 0) PolygonLayer(polygons: _cityBounds),
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
                            OverlayImageLayer(
                              overlayImages: [
                                OverlayImage(
                                  bounds: LatLngBounds(
                                    const LatLng(17.88, 115),
                                    const LatLng(28.8925, 126.5125),
                                  ),
                                  imageProvider: NetworkImage(
                                    'https://api.exptech.com.tw/file/radar1.png',
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
                initialChildSize: 0.45,
                minChildSize: 0.45,
                maxChildSize: 1.0,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    color: Colors.black.withOpacity(0.8),
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
      ),
    );
  }
}
