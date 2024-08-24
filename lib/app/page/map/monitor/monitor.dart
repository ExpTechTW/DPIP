import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/core/rts.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/eew.dart';
import 'package:dpip/model/rts/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/model/station_info.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/util/need_location.dart';
import 'package:dpip/widget/map/legend.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'eew_info.dart';

typedef PositionUpdateCallback = void Function();

class MonitorPage extends StatefulWidget {
  final Function()? onPositionUpdate;
  const MonitorPage({Key? key, required this.data, this.onPositionUpdate}) : super(key: key);

  final int data;

  @override
  State<MonitorPage> createState() => _MonitorPageState();

  static PositionUpdateCallback? _activeCallback;

  static void setActiveCallback(PositionUpdateCallback callback) {
    _activeCallback = callback;
  }

  static void clearActiveCallback() {
    _activeCallback = null;
  }

  static void updatePosition() {
    _activeCallback?.call();
  }
}

class _MonitorPageState extends State<MonitorPage> with SingleTickerProviderStateMixin {
  late MapLibreMapController _mapController;
  late Map<String, Station> _stations;

  Timer? _dataUpdateTimer;
  Timer? _eewUpdateTimer;
  Timer? _blinkTimer;
  int _timeOffset = 0;
  int _lsatGetRtsDataTime = 0;
  int _replayTimeStamp = 0;
  int _timeReplay = 0;
  double userLat = 0;
  double userLon = 0;
  double _ping = 0;
  String _formattedPing = '';
  Map<String, double> _eewDist = {};
  Map<String, int> _eewUpdateList = {};
  Map<String, Map<String, int>> _userEewArriveTime = {};
  Map<String, int> _userEewIntensity = {};
  Map<String, Eew> _eewLastInfo = {};
  Rts? _rtsData;
  bool _isMarkerVisible = true;
  bool _isBoxVisible = true;
  bool _isEewBoxVisible = true;
  bool isUserLocationValid = false;
  int _isTsunamiVisible = 0;
  final Map<String, dynamic> _eewIntensityArea = {};
  final DraggableScrollableController sheetController = DraggableScrollableController();
  final sheetInitialSize = 0.2;
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late ScrollController scrollController;
  List<Widget> _eewUI = [];
  List<Widget> _rtsUI = [];
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    _initTimeOffset();
    _timeReplay = widget.data;

    sheetController.addListener(() {
      final newSize = sheetController.size;
      final scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);
      animController.animateTo(scrollPosition, duration: Duration.zero);
    });
    MonitorPage.setActiveCallback(sendpositionUpdate);
  }

  void sendpositionUpdate() {
    if (mounted) {
      userLocation();
      widget.onPositionUpdate?.call();
    }
  }

  void _initTimeOffset() async {
    final data = await ExpTech().getNtp();
    _timeOffset = DateTime.now().millisecondsSinceEpoch - data;
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  void userLocation() async {
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;

    if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
      await showLocationDialog(context);
    }

    _updateCrossMarker();
  }

  void _loadMap() async {
    _initStations();

    userLocation();

    _eewUI.add(Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Text(
        context.i18n.earthquake_warning_error,
        textAlign: TextAlign.left,
        style: TextStyle(fontSize: 20, color: context.colors.error),
      ),
    ));
  }

  void _initStations() async {
    final data = await ExpTech().getStations();
    final isDark = context.theme.brightness == Brightness.dark;

    await _loadMapImages(isDark);
    _setupStationSource(data);
    _startDataUpdates();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!mounted) return;
      _isMarkerVisible = !_isMarkerVisible;
      _isBoxVisible = !_isBoxVisible;
      await _updateBoxLine();
      await _updateTsunamiLine();
      await _updateCrossMarker();
    });
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadIntensityImage(_mapController, isDark);
    await loadCrossImage(_mapController);
    await loadGPSImage(_mapController);
  }

  void _setupStationSource(Map<String, Station> data) async {
    _stations = data;
    await _mapController.addSource(
        "station-geojson", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
    await _mapController.addSource("station-geojson-intensity-0",
        const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
    await _mapController.addSource(
        "markers-geojson", const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
    _addStationLayer();
  }

  void _addStationLayer() async {
    await _mapController.addCircleLayer(
        "station-geojson",
        "station",
        CircleLayerProperties(
          circleColor: _getStationColorExpression(),
          circleRadius: _getStationRadiusExpression(),
        ));
    await _mapController.addCircleLayer(
        "station-geojson-intensity-0",
        "station-intensity-0",
        CircleLayerProperties(
          circleColor: "#7B7B7B",
          circleRadius: _getStationRadiusExpression(),
        ));

    await _mapController.addLayer(
      "markers-geojson",
      "markers",
      const SymbolLayerProperties(
        symbolSortKey: [Expressions.get, "intensity"],
        symbolZOrder: "source",
        iconSize: [
          Expressions.interpolate,
          ["linear"],
          [Expressions.zoom],
          5,
          0.5,
          10,
          1.5,
        ],
        iconImage: [
          Expressions.match,
          [Expressions.get, "intensity"],
          1,
          "intensity-1",
          2,
          "intensity-2",
          3,
          "intensity-3",
          4,
          "intensity-4",
          5,
          "intensity-5",
          6,
          "intensity-6",
          7,
          "intensity-7",
          8,
          "intensity-8",
          9,
          "intensity-9",
          10,
          "cross",
          "gps"
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );

    await _mapController.addGeoJsonSource(
      "box-geojson",
      {
        "type": "FeatureCollection",
        "features": [],
      },
    );

    await _mapController.addLayer(
        "box-geojson",
        "box-geojson",
        const LineLayerProperties(lineWidth: 2, lineColor: [
          'match',
          ['get', 'i'],
          9,
          "#FF0000",
          8,
          "#FF0000",
          7,
          "#FF0000",
          6,
          "#FF0000",
          5,
          "#FF0000",
          4,
          "#FF0000",
          3,
          "#EAC100",
          2,
          "#EAC100",
          1,
          "#00DB00",
          "#00DB00"
        ]));
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRtsData();
      _updateEewData();
      setState(() {});
    });
    _eewUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _updateEewCircles();
      if (_timeReplay != 0) {
        _timeReplay += (_replayTimeStamp == 0) ? 0 : DateTime.now().millisecondsSinceEpoch - _replayTimeStamp;
        _replayTimeStamp = DateTime.now().millisecondsSinceEpoch;
      }
    });
  }

  bool _dataStatus() {
    bool status = (((_timeReplay == 0) ? _getCurrentTime() : _timeReplay) - _lsatGetRtsDataTime) < 3000;
    if (!status && _rtsData != null) {
      _rtsData = null;
      _mapController.setGeoJsonSource("station-geojson", _generateStationGeoJson(null));
      _mapController.setGeoJsonSource("station-geojson-intensity-0", _generateStationGeoJsonIntensity0(null));
    }
    return status;
  }

  void _updateRtsData() async {
    try {
      int t = DateTime.now().millisecondsSinceEpoch;
      final data = await ExpTech().getRts(_timeReplay);
      if (data.time < (_rtsData?.time ?? 0)) return;
      _ping = (DateTime.now().millisecondsSinceEpoch - t) / 1000;
      String formattedPing = _ping.toStringAsFixed(2);
      _formattedPing = formattedPing;
      _rtsData = data;
      _lsatGetRtsDataTime = (_timeReplay == 0) ? _getCurrentTime() : _timeReplay;
    } catch (err) {
      print(err);
    } finally {
      await _updateMarkers();
    }
  }

  Future<void> _updateMarkers() async {
    await _mapController.setGeoJsonSource("station-geojson", _generateStationGeoJson(_rtsData));
    await _mapController.setGeoJsonSource("station-geojson-intensity-0", _generateStationGeoJsonIntensity0(_rtsData));
  }

  void _updateEewData() async {
    try {
      final data = await ExpTech().getEew(_timeReplay);
      _processEewData(data);
      _removeOldEews(data);
    } catch (err) {
      print(err);
    }
  }

  Future<void> _updateCrossMarker() async {
    List markers_features = [];

    if (_isMarkerVisible) {
      for (var id in _eewLastInfo.keys) {
        markers_features.add({
          "type": "Feature",
          "properties": {
            "intensity": 10,
          },
          "geometry": {
            "coordinates": [_eewLastInfo[id]!.eq.lon, _eewLastInfo[id]!.eq.lat],
            "type": "Point"
          }
        });
      }
    }

    _rtsData?.station.forEach((key, value) {
      int intensity = intensityFloatToInt(value.I);
      if (value.alert == true && intensity > 0) {
        StationInfo info = findAppropriateItem(_stations[key]!.info, _timeReplay);
        markers_features.add({
          "type": "Feature",
          "properties": {
            "intensity": intensity, // 10 is for classifying epicenter cross
          },
          "geometry": {
            "coordinates": [info.lon, info.lat],
            "type": "Point"
          }
        });
      }
    });

    if (isUserLocationValid) {
      markers_features.add({
        "type": "Feature",
        "properties": {
          "intensity": 11,
        },
        "geometry": {
          "coordinates": [userLon, userLat],
          "type": "Point"
        }
      });
    }

    await _mapController.setGeoJsonSource(
      "markers-geojson",
      {
        "type": "FeatureCollection",
        "features": markers_features,
      },
    );
  }

  Future<void> _updateTsunamiLine() async {
    // await _mapController.setLayerProperties(
    //     "tsunami",
    //     LineLayerProperties(lineColor: [
    //       "match",
    //       ["get", "AREANAME"],
    //       "東部沿海地區",
    //       "#FF0000",
    //       "#EAC100"
    //     ], lineOpacity: (_isTsunamiVisible < 6) ? 1 : 0));
    // _isTsunamiVisible++;
    // if (_isTsunamiVisible >= 8) _isTsunamiVisible = 0;
  }

  Future<void> _updateBoxLine() async {
    if (_rtsData == null) return;
    List features = [];
    List<Widget> rtsUI = [];
    if (_rtsData!.box.keys.isNotEmpty) {
      if (_isBoxVisible) {
        for (var area in Global.box["features"]) {
          int id = area["properties"]["ID"];
          if (_rtsData!.box[id.toString()] == null) continue;
          bool skip = checkBoxSkip(_eewLastInfo, _eewDist, area["geometry"]["coordinates"][0]);
          if (!skip) {
            features.add({
              "type": "Feature",
              "properties": {
                "i": _rtsData!.box[id.toString()], // 10 is for classifying epicenter cross
              },
              "geometry": {"coordinates": area["geometry"]["coordinates"], "type": "Polygon"}
            });
          }
        }
      }

      int count = 0;
      for (var area in _rtsData!.intensity) {
        rtsUI.add(Chip(
          padding: const EdgeInsets.all(4),
          side: BorderSide(color: IntensityColor.intensity(area.i)),
          backgroundColor: IntensityColor.intensity(area.i).withOpacity(0.16),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: IntensityColor.intensity(area.i),
              ),
              child: Center(
                child: Text(
                  area.i.asIntensityDisplayLabel,
                  style: TextStyle(
                    height: 1,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: IntensityColor.onIntensity(area.i),
                  ),
                ),
              ),
            ),
          ),
          label: Text(Global.location[area.code.toString()]!.city + Global.location[area.code.toString()]!.town),
        ));
        rtsUI.add(const SizedBox(height: 5));
        count++;
        if (count == 3) break;
      }
    }
    await _mapController.setGeoJsonSource("box-geojson", {
      "type": "FeatureCollection",
      "features": features,
    });
    _rtsUI = rtsUI;
  }

  void _processEewData(List<Eew> data) async {
    List<Widget> eewUI = [];
    for (var eew in data) {
      if ((_eewUpdateList[eew.id] ?? 0) < eew.serial) {
        if (_eewUpdateList[eew.id] == null) {
          _addEewCircle(eew);
          _updateMarkers();
        }
        _eewUpdateList[eew.id] = eew.serial;
        await _updateCrossMarker();
        _eewLastInfo[eew.id] = eew;
        _updateEewIntensityArea(eew);
        _updateMapArea();

        Map<String, dynamic> info = eewLocationInfo(eew.eq.mag, eew.eq.depth, eew.eq.lat, eew.eq.lon, userLat, userLon);
        _userEewIntensity[eew.id] = intensityFloatToInt(info["i"]);
        _userEewArriveTime[eew.id] = {
          "s": (eew.eq.time + sWaveTimeByDistance(eew.eq.depth, info["dist"])).floor(),
          "p": (eew.eq.time + pWaveTimeByDistance(eew.eq.depth, info["dist"])).floor(),
        };
      }

      eewUI.add(Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !_isEewBoxVisible
                      ? Colors.grey
                      : _eewLastInfo[eew.id]?.status == 1
                          ? const Color(0xFFC80000)
                          : const Color(0xFFFFC800),
                  width: 3,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _eewLastInfo[eew.id]?.status == 1
                            ? context.i18n.emergency_earthquake_warning
                            : context.i18n.earthquake_warning,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.onSurface,
                        ),
                      ),
                      Text(
                        context.i18n.eew_no_x(_eewLastInfo[eew.id]?.serial.toString() ?? ''),
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _eewLastInfo[eew.id]!.eq.loc,
                              style: TextStyle(
                                fontSize: 24,
                                color: context.colors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${DateFormat('yyyy/MM/dd HH:mm:ss').format(tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation('Asia/Taipei'), _eewLastInfo[eew.id]!.eq.time))} 發震",
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "M ${_eewLastInfo[eew.id]?.eq.mag}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: context.colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_eewLastInfo[eew.id]?.eq.depth} km",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: context.colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: IntensityColor.intensity(_eewLastInfo[eew.id]!.eq.max),
                        ),
                        child: Center(
                          child: Text(
                            _eewLastInfo[eew.id]!.eq.max.asIntensityDisplayLabel,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: IntensityColor.onIntensity(_eewLastInfo[eew.id]!.eq.max)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: context.colors.onSurface, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (!isUserLocationValid || (_userEewIntensity[eew.id] ?? 0) == 0)
                              ? Colors.transparent
                              : IntensityColor.intensity(
                                  (_userEewIntensity[eew.id] ?? 0),
                                ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.i18n.location_estimate,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: (!isUserLocationValid || (_userEewIntensity[eew.id] ?? 0) == 0)
                                      ? context.colors.onSurface
                                      : IntensityColor.onIntensity(_userEewIntensity[eew.id] ?? 0)),
                            ),
                            Text(
                              (!isUserLocationValid) ? "?" : (_userEewIntensity[eew.id] ?? 0).asIntensityDisplayLabel,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                  color: (!isUserLocationValid || (_userEewIntensity[eew.id] ?? 0) == 0)
                                      ? context.colors.onSurface
                                      : IntensityColor.onIntensity(_userEewIntensity[eew.id] ?? 0)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 80,
                        width: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.i18n.seismic_waves,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            (!isUserLocationValid ||
                                    ((_userEewArriveTime[eew.id]!["s"]! - _getCurrentTime()) / 1000).floor() <= 0)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        (!isUserLocationValid)
                                            ? context.i18n.monitor_unknown
                                            : context.i18n.monitor_arrival,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 36, color: context.colors.onSurface),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        ((_userEewArriveTime[eew.id]!["s"]! - _getCurrentTime()) / 1000)
                                            .floor()
                                            .toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 36, color: context.colors.onSurface),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        context.i18n.monitor_after_seconds,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14, color: context.colors.onSurface),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    if (eewUI.isEmpty) {
      eewUI.add(Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Text(
          context.i18n.no_earthquake_warning,
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 20),
        ),
      ));
    } else {
      _isEewBoxVisible = !_isEewBoxVisible;
    }
    _eewUI = eewUI;
  }

  void _addEewCircle(Eew eew) async {
    final circleData = circle(LatLng(eew.eq.lat, eew.eq.lon), 0, steps: 256);
    await _mapController.addSource(
        "${eew.id}-circle",
        GeojsonSourceProperties(data: {
          "type": "FeatureCollection",
          "features": [circleData]
        }, tolerance: 1));
    await _mapController.addSource(
        "${eew.id}-circle-p",
        GeojsonSourceProperties(data: {
          "type": "FeatureCollection",
          "features": [circleData]
        }, tolerance: 1));
    _addEewLayers(eew);
  }

  void _addEewLayers(Eew eew) async {
    final color = (eew.status == 1) ? "#ff0000" : "#ffaa00";
    await _mapController.addLineLayer(
        "${eew.id}-circle", "${eew.id}-wave-outline", LineLayerProperties(lineColor: color, lineWidth: 2));
    await _mapController.addFillLayer(
        "${eew.id}-circle", "${eew.id}-wave-bg", FillLayerProperties(fillColor: color, fillOpacity: 0.25),
        belowLayerId: "county");
    await _mapController.addLineLayer("${eew.id}-circle-p", "${eew.id}-wave-outline-p",
        const LineLayerProperties(lineColor: "#00CACA", lineWidth: 2));
  }

  void _updateEewIntensityArea(Eew eew) {
    _eewIntensityArea[eew.id] = eewAreaPga(eew.eq.lat, eew.eq.lon, eew.eq.depth, eew.eq.mag, Global.location);
  }

  void _updateEewCircles() async {
    if (_eewLastInfo.keys.isEmpty) return;
    for (var id in _eewLastInfo.keys) {
      final dist = psWaveDist(_eewLastInfo[id]!.eq.depth, _eewLastInfo[id]!.eq.time, _getCurrentTime());
      _eewDist[id] = dist["s_dist"]!;
      final circleData =
          circle(LatLng(_eewLastInfo[id]!.eq.lat, _eewLastInfo[id]!.eq.lon), dist["s_dist"]!, steps: 256);
      await _mapController.setGeoJsonSource("${id}-circle", {
        "type": "FeatureCollection",
        "features": [circleData]
      });
      final circleDataP =
          circle(LatLng(_eewLastInfo[id]!.eq.lat, _eewLastInfo[id]!.eq.lon), dist["p_dist"]!, steps: 256);
      await _mapController.setGeoJsonSource("${id}-circle-p", {
        "type": "FeatureCollection",
        "features": [circleDataP]
      });
    }
  }

  int _getCurrentTime() => (_timeReplay != 0) ? _timeReplay : DateTime.now().millisecondsSinceEpoch + _timeOffset;

  void _removeOldEews(List<Eew> data) async {
    final currentEewIds = data.map((e) => e.id).toSet();
    final idsToRemove = _eewLastInfo.keys.where((id) => !currentEewIds.contains(id)).toList();

    for (var id in idsToRemove) {
      _eewLastInfo.remove(id);
      await _removeEewLayers(id);
      _eewIntensityArea.remove(id);
      _eewUpdateList.remove(id);
      _userEewArriveTime.remove(id);
      _userEewIntensity.remove(id);
      _eewDist.remove(id);
      _updateMapArea();
      _updateMarkers();
    }
  }

  Future<void> _removeEewLayers(String id) async {
    await _mapController.removeLayer("$id-wave-outline");
    await _mapController.removeLayer("$id-wave-outline-p");
    await _mapController.removeLayer("$id-wave-bg");
    await _mapController.removeSource("$id-circle");
    await _mapController.removeSource("$id-circle-p");
  }

  void _updateMapArea() async {
    Map<String, int> eewArea = {};
    _eewIntensityArea.forEach((String key, dynamic intensity) {
      intensity.forEach((name, value) {
        if (name != "max_i") {
          int I = intensityFloatToInt(value["i"]);
          if (eewArea[name] == null || eewArea[name]! < I) {
            eewArea[name] = I;
          }
        }
      });
    });

    if (eewArea.keys.isEmpty) {
      await _mapController.setLayerProperties(
        'town',
        FillLayerProperties(
          fillColor: context.colors.surfaceContainerHighest.toHexStringRGB(),
          fillOpacity: 1,
        ),
      );
      return;
    }

    await _mapController.setLayerProperties(
      'town',
      FillLayerProperties(
        fillColor: [
          'match',
          ['get', 'CODE'],
          ...eewArea.entries.expand((entry) => [
                int.parse(entry.key),
                IntensityColor.intensity(entry.value).toHexStringRGB(),
              ]),
          context.colors.surfaceContainerHighest.toHexStringRGB(),
        ],
        fillOpacity: 1,
      ),
    );
  }

  Map<String, dynamic> _generateStationGeoJsonIntensity0([Rts? rtsData]) {
    if (rtsData == null) {
      return {
        "type": "FeatureCollection",
        "features": [],
      };
    }

    final features = _stations.entries.where((e) {
      return rtsData.station.containsKey(e.key);
    }).where((e) {
      if (_rtsData!.box.keys.isNotEmpty) {
        return rtsData.station[e.key]?.alert == true && intensityFloatToInt(rtsData.station[e.key]!.I) < 1;
      }
      return false;
    }).map((e) {
      StationInfo info = findAppropriateItem(e.value.info, _timeReplay);
      return {
        "type": "Feature",
        "properties": {},
        "id": e.key,
        "geometry": {
          "coordinates": [info.lon, info.lat],
          "type": "Point"
        }
      };
    }).toList();

    return {
      "type": "FeatureCollection",
      "features": features,
    };
  }

  Map<String, dynamic> _generateStationGeoJson([Rts? rtsData]) {
    if (rtsData == null) {
      return {
        "type": "FeatureCollection",
        "features": [],
      };
    }

    final features = _stations.entries.where((e) {
      return rtsData.station.containsKey(e.key);
    }).where((e) {
      if (_eewLastInfo.keys.isNotEmpty || (_rtsData!.box.keys.isNotEmpty && rtsData.station[e.key]?.alert == true))
        return false;
      return true;
    }).map((e) {
      Map<String, dynamic> properties = {"i": rtsData.station[e.key]?.i};

      StationInfo info = findAppropriateItem(e.value.info, _timeReplay);
      return {
        "type": "Feature",
        "properties": properties,
        "id": e.key,
        "geometry": {
          "coordinates": [info.lon, info.lat],
          "type": "Point"
        }
      };
    }).toList();

    return {
      "type": "FeatureCollection",
      "features": features,
    };
  }

  dynamic _getStationColorExpression() {
    return [
      Expressions.interpolate,
      ["linear"],
      ["get", "i"],
      -3,
      InstrumentalIntensityColor.intensity_3.toHexStringRGB(),
      -2,
      InstrumentalIntensityColor.intensity_2.toHexStringRGB(),
      -1,
      InstrumentalIntensityColor.intensity_1.toHexStringRGB(),
      0,
      InstrumentalIntensityColor.intensity0.toHexStringRGB(),
      1,
      InstrumentalIntensityColor.intensity1.toHexStringRGB(),
      2,
      InstrumentalIntensityColor.intensity2.toHexStringRGB(),
      3,
      InstrumentalIntensityColor.intensity3.toHexStringRGB(),
      4,
      InstrumentalIntensityColor.intensity4.toHexStringRGB(),
      5,
      InstrumentalIntensityColor.intensity5.toHexStringRGB(),
      6,
      InstrumentalIntensityColor.intensity6.toHexStringRGB(),
      7,
      InstrumentalIntensityColor.intensity7.toHexStringRGB(),
    ];
  }

  dynamic _getStationRadiusExpression() {
    return [
      Expressions.interpolate,
      ["linear"],
      [Expressions.zoom],
      4,
      2,
      12,
      8
    ];
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _eewUpdateTimer?.cancel();
    _blinkTimer?.cancel();
    MonitorPage.clearActiveCallback();
    super.dispose();
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return MapLegend(
      label: "預估震度圖例",
      children: [
        _buildColorBar(),
        const SizedBox(height: 8),
        _buildColorBarLabels(),
        Text("僅用於地震速報時", style: context.theme.textTheme.labelMedium),
      ],
    );
  }

  Widget _buildColorBar() {
    final intensities = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    return SizedBox(
      height: 20,
      width: 300,
      child: Row(
        children: intensities.map((intensity) {
          return Expanded(
            child: Container(
              color: IntensityColor.intensity(intensity),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorBarLabels() {
    final labels = ['1', '2', '3', '4', '5弱', '5強', '6弱', '6強', '7'];
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: labels.map((label) {
          return SizedBox(
            width: 300 / 9,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _timeReplay != 0
          ? AppBar(
              title: Text(context.i18n.monitor),
            )
          : null,
      body: Stack(
        children: [
          DpipMap(
            onMapCreated: _initMap,
            onStyleLoadedCallback: _loadMap,
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: context.colors.secondary,
              elevation: 4.0,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _toggleLegend,
                child: Tooltip(
                  message: '圖例',
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    child: Icon(
                      _showLegend ? Icons.close : Icons.info_outline,
                      size: 20,
                      color: context.colors.onSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('yyyy/MM/dd HH:mm:ss').format((!_dataStatus())
                        ? tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation('Asia/Taipei'), _lsatGetRtsDataTime)
                        : (_timeReplay == 0)
                            ? tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation('Asia/Taipei'), _getCurrentTime())
                            : tz.TZDateTime.fromMillisecondsSinceEpoch(tz.getLocation('Asia/Taipei'), _timeReplay)),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (!_dataStatus())
                            ? Colors.red
                            : (_timeReplay == 0)
                                ? context.colors.onSurface
                                : Colors.orangeAccent),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withOpacity(0.5),
                  ),
                  child: Text(
                    (!_dataStatus()) ? "2+s" : "${_formattedPing}s",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (!_dataStatus())
                            ? Colors.red
                            : (_ping > 1)
                                ? Colors.orange
                                : Colors.green),
                  ),
                ),
              ),
            ),
          ),
          if (_rtsUI.isNotEmpty)
            Positioned(
              left: 4,
              top: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [..._rtsUI],
              ),
            ),
          Positioned.fill(
            child: EewDraggableSheet(eewUI: _eewUI),
          ),
          if (_showLegend)
            Positioned(
              right: 6,
              top: 50, // Adjusted to be above the legend button
              child: _buildLegend(),
            ),
        ],
      ),
    );
  }
}
