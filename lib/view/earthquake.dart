import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dpip/core/api.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/eew.dart';
import 'package:dpip/model/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/view/about_rts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/utils.dart';

class EarthquakePage extends StatefulWidget {
  const EarthquakePage({super.key});

  @override
  State<EarthquakePage> createState() => _EarthquakePage();
}

int randomNum(int max) {
  return Random().nextInt(max) + 1;
}

class _EarthquakePage extends State<EarthquakePage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  AppLifecycleState? _notification;
  late Timer clock;
  late Timer stationClock;
  late Timer ntpClock;
  int timeNtp = 0;
  int timeLocal = 0;

  Map<String, Station>? stations;
  Rts? rts;

  /// EEW 列表
  List<Eew> eewList = [];
  String eewTime = "";

  /// P 波抵達時間戳
  double pArrive = 0;

  /// S 波抵達時間戳
  double sArrive = 0;

  /// 使用者本地預估震度
  int userIntensity = 0;

  /// P 波速度，單位：公里/秒
  double waveSpeedP = 6.0;

  /// S 波速度，單位：公里/秒
  double waveSpeedS = 3.5;

  String? city = Global.preference.getString("loc-city");
  String? town = Global.preference.getString("loc-town");

  bool loading = true;

  void ntp() async {
    var ans = await get("https://lb-${randomNum(4)}.exptech.com.tw/ntp");
    if (ans != false) {
      timeNtp = ans - 1000;
      timeLocal = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<void> updateStations() async {
    final s = await Global.api.getStations();
    setState(() {
      stations = s;
    });
  }

  Future<void> updateImage() async {
    try {
      if (_notification != null && _notification != AppLifecycleState.resumed) return;

      final r = await Global.api.getRts();

      setState(() {
        rts = r;
      });
    } catch (e) {
      return;
    }
  }

  Future<void> updateEEW() async {
    if (_notification != null && _notification != AppLifecycleState.resumed) return;

    city = Global.preference.getString("loc-city");
    town = Global.preference.getString("loc-town");

    final newEewList = await Global.api.getEew(EewSource.cwa);

    try {
      if (newEewList.isEmpty) return;

      final data = newEewList[0];

      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(data.eq.time);
      DateFormat formatter = DateFormat('yyyy/MM/dd HH:mm:ss');
      eewTime = formatter.format(dateTime);

      final eewPga = eewAreaPga(data.eq.lat, data.eq.lon, data.eq.depth, data.eq.mag, Global.region);

      if (city != null && town != null) {
        userIntensity = intensityFloatToInt(eewPga["$city $town"]["i"]);
        final location = Global.region[city]![town]!;

        final waveTime =
            calculateWaveTime(data.eq.depth, distance(data.eq.lat, data.eq.lon, location.lat, location.lon));

        sArrive = data.eq.time + waveTime.s * 1000;
        pArrive = data.eq.time + waveTime.p * 1000;
      }
    } finally {
      eewList = newEewList;
    }
  }

  @override
  get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ntp();
    ntpClock = Timer.periodic(const Duration(seconds: 60), (timer) {
      ntp();
    });

    clock = Timer.periodic(const Duration(seconds: 1), (timer) async {
      updateImage();
      updateEEW();
    });

    updateStations();
    stationClock = Timer.periodic(const Duration(minutes: 1), (timer) async {
      updateStations();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
    });
  }

  @override
  void dispose() {
    clock.cancel();
    ntpClock.cancel();
    stationClock.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final geojson = Platform.isIOS
        ? GeoJsonParser(
            defaultPolygonFillColor: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
            defaultPolygonBorderColor: CupertinoColors.tertiaryLabel.resolveFrom(context),
          )
        : GeoJsonParser(
            defaultPolygonFillColor: context.colors.surfaceContainerHighest,
            defaultPolygonBorderColor: context.colors.outline,
          );

    String baseMap = Global.preference.getString("base_map") ?? "geojson";

    if (baseMap == "geojson") {
      geojson.parseGeoJsonAsString(Global.taiwanGeojsonString);
    }

    List<Marker> rtsMarkers = [];

    if (stations != null) {
      final stationList = stations!.entries.toList();

      if (rts != null) {
        stationList.sort((a, b) {
          final rtsA = rts!.station[a.key];
          final rtsB = rts!.station[b.key];

          if (rtsA == null) {
            return -1;
          }

          if (rtsB == null) {
            return 1;
          }

          return (rtsA.i - rtsB.i).sign.toInt();
        });
      }

      for (var MapEntry(key: key, value: value) in stationList) {
        rtsMarkers.add(Marker(
          height: 8,
          width: 8,
          point: LatLng(value.info[0].lat, value.info[0].lon),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rts != null ? InstrumentalIntensityColor.i(rts!.station[key]?.i) : Colors.transparent,
              border: Border.all(
                color: Colors.grey.withOpacity(0.6),
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
        ));
      }
    }

    List<CircleMarker> waveCircles = [];
    List<Marker> epicenterMarker = [];

    if (eewList.isNotEmpty) {
      final eew = eewList.first;

      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 計算P波和S波傳播半徑（單位：公里）
      double pRadius = (currentTime - eew.eq.time) / 1000 * waveSpeedP; // P 波速度，單位：公里/秒
      double sRadius = (currentTime - eew.eq.time) / 1000 * waveSpeedS; // S 波速度，單位：公里/秒

      // 添加 P 波圓圈
      waveCircles.add(CircleMarker(
        point: LatLng(eew.eq.lat, eew.eq.lon),
        radius: pRadius * 1000, // 將半徑轉換為米
        color: Colors.blue.withOpacity(0.2),
        borderStrokeWidth: 3,
        useRadiusInMeter: true,
      ));

      // 添加 S 波圓圈
      waveCircles.add(CircleMarker(
        point: LatLng(eew.eq.lat, eew.eq.lon),
        radius: sRadius * 1000, // 將半徑轉換為米
        color: Colors.red.withOpacity(0.3),
        borderStrokeWidth: 3,
        useRadiusInMeter: true,
      ));

      // 添加震央標記
      epicenterMarker.add(Marker(
        height: 40, // 調整震央標記的高度
        width: 40, // 調整震央標記的寬度
        point: LatLng(eew.eq.lat, eew.eq.lon),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.clear,
            color: Colors.red,
            size: 36,
          ),
        ),
      ));
    }

    final flutterMap = FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(23.8, 120.8),
        initialZoom: 7,
        minZoom: 7,
        maxZoom: 12,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchMove | InteractiveFlag.pinchZoom,
        ),
        backgroundColor: Colors.transparent,
      ),
      children: [
        baseMap == "geojson"
            ? PolygonLayer(
                polygons: geojson.polygons,
                polygonCulling: true,
                polygonLabels: false,
              )
            : TileLayer(
                urlTemplate: {
                  "googlemap": "http://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                  "googletrain": "http://mt1.google.com/vt/lyrs=r@221097413,bike,transit&x={x}&y={y}&z={z}",
                  "googlesatellite": "http://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
                  "openstreetmap": "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                }[baseMap],
                userAgentPackageName: 'com.exptech.dpip.dpip',
              ),
        MarkerLayer(
          markers: rtsMarkers,
        ),
        CircleLayer(
          circles: waveCircles,
        ),
        MarkerLayer(
          markers: epicenterMarker,
        ),
      ],
    );

    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text("強震監視器"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.question_circle),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return const AboutRts();
                  },
                ),
              );
            },
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.15)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "即時資料僅供參考\n實際請以中央氣象署的資料為主",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Flexible(child: flutterMap),
                  if (eewList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (eewList.first.eq.max > 4) ? Colors.red : Colors.orange,
                          width: 2.0,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Symbols.crisis_alert_rounded,
                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (eewList.first.eq.max > 4) ? "緊急地震速報" : "地震速報",
                                style: TextStyle(
                                    height: 1, color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "第 ${eewList.first.serial} 報",
                                style: TextStyle(
                                    height: 1, color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          eewList.first.eq.loc,
                                          style: TextStyle(
                                            color: CupertinoColors.label.resolveFrom(context),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "M ${eewList.first.eq.mag}",
                                          style: TextStyle(
                                            color: CupertinoColors.label.resolveFrom(context),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: IntensityColor.intensity(eewList.first.eq.max),
                                          ),
                                          child: Center(
                                            child: Text(
                                              intensityToNumberString(eewList.first.eq.max),
                                              style: TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: IntensityColor.onIntensity(eewList.first.eq.max),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("$eewTime 發生", style: const TextStyle(fontSize: 16)),
                                        Text("${eewList.first.eq.depth}km", style: const TextStyle(fontSize: 16)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  if (eewList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: city == null || town == null
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.pin_drop_rounded,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "尚未設定所在地",
                            style:
                            TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                          )
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Symbols.pin_drop_rounded,
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$city$town",
                                    style: TextStyle(
                                        color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: IntensityColor.intensity(userIntensity),
                                    ),
                                    child: Center(
                                      child: Text(
                                        intensityToNumberString(userIntensity),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: IntensityColor.onIntensity(userIntensity),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "P波",
                                                style: TextStyle(
                                                  height: 1,
                                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  ((pArrive <
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch - timeLocal)))
                                                      ? "抵達"
                                                      : ((pArrive -
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch -
                                                              timeLocal))) /
                                                      1000)
                                                      .toStringAsFixed(0)),
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "S波",
                                                style: TextStyle(
                                                  height: 1,
                                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  ((sArrive <
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch - timeLocal)))
                                                      ? "抵達"
                                                      : ((sArrive -
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch -
                                                              timeLocal))) /
                                                      1000)
                                                      .toStringAsFixed(0)),
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
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
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("強震監視器"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.help_outline_rounded,
              ),
              tooltip: "幫助",
              color: context.colors.onSurfaceVariant,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutRts()),
                );
              },
            ),
          ],
        ),
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.15)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Text(
                    "即時資料僅供參考\n實際請以中央氣象署的資料為主",
                    textAlign: TextAlign.center,
                  ),
                  Flexible(child: flutterMap),
                  if (eewList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (eewList.first.eq.max > 4) ? Colors.red : Colors.orange,
                          width: 2.0,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Symbols.crisis_alert_rounded,
                                color: context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (eewList.first.eq.max > 4) ? "緊急地震速報" : "地震速報",
                                style: TextStyle(height: 1, color: context.colors.onSurfaceVariant, fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "第 ${eewList.first.serial} 報",
                                style: TextStyle(height: 1, color: context.colors.onSurfaceVariant, fontSize: 18),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(eewList.first.eq.loc,
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                        Text("M ${eewList.first.eq.mag}",
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.0),
                                            color: IntensityColor.intensity(eewList.first.eq.max),
                                          ),
                                          child: Center(
                                            child: Text(
                                              intensityToNumberString(eewList.first.eq.max),
                                              style: TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: IntensityColor.onIntensity(eewList.first.eq.max),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("$eewTime 發生", style: const TextStyle(fontSize: 16)),
                                        Text("${eewList.first.eq.depth}km", style: const TextStyle(fontSize: 16)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  if (eewList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                      ),
                      child: city == null || town == null
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Symbols.pin_drop_rounded,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "尚未設定所在地",
                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 18),
                          )
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Symbols.pin_drop_rounded,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$city$town",
                                    style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      color: IntensityColor.intensity(userIntensity),
                                    ),
                                    child: Center(
                                      child: Text(
                                        intensityToNumberString(userIntensity),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          color: IntensityColor.onIntensity(userIntensity),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "P波",
                                                style: TextStyle(
                                                  height: 1,
                                                  color: context.colors.onSurfaceVariant,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  ((pArrive <
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch - timeLocal)))
                                                      ? "抵達"
                                                      : ((pArrive -
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch -
                                                              timeLocal))) /
                                                      1000)
                                                      .toStringAsFixed(0)),
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "S波",
                                                style: TextStyle(
                                                  height: 1,
                                                  color: context.colors.onSurfaceVariant,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Center(
                                                child: Text(
                                                  ((sArrive <
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch - timeLocal)))
                                                      ? "抵達"
                                                      : ((sArrive -
                                                      (timeNtp +
                                                          (DateTime.now().millisecondsSinceEpoch -
                                                              timeLocal))) /
                                                      1000)
                                                      .toStringAsFixed(0)),
                                                  style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
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
      );
    }
  }
}
