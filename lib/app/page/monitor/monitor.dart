import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/rts.dart';
import 'package:dpip/global.dart';
import 'package:dpip/model/eew.dart';
import 'package:dpip/model/rts/rts.dart';
import 'package:dpip/model/station.dart';
import 'package:dpip/model/station_info.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/instrumental_intensity_color.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/util/map_utils.dart';
import 'package:dpip/widget/map/map.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key, required this.data});

  final int data;

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> with SingleTickerProviderStateMixin {
  late MapLibreMapController _mapController;
  late Map<String, Station> _stations;

  Timer? _dataUpdateTimer;
  Timer? _eewUpdateTimer;
  Timer? _blinkTimer;
  int _timeOffset = 0;
  int _ping = 0;
  final List<String> _eewIdList = [];
  List<Eew> _eewData = [];
  Map<String, double> _eewDist = {};
  Rts? _rtsData;
  int _lsatGetRtsDataTime = 0;
  int _replayTimeStamp = 0;
  int _timeReplay = 0;
  final Map<String, dynamic> _eewIntensityArea = {};
  bool _isMarkerVisible = true;
  bool _isBoxVisible = true;
  int _isTsunamiVisible = 0;
  final sheetController = DraggableScrollableController();
  final sheetInitialSize = 0.2;
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    _initTimeOffset();
    _timeReplay = widget.data;
  }

  void _initTimeOffset() async {
    final data = await ExpTech().getNtp();
    setState(() => _timeOffset = DateTime.now().millisecondsSinceEpoch - data);
  }

  void _initMap(MapLibreMapController controller) async {
    _mapController = controller;
    _initStations();
  }

  void _initStations() async {
    final data = await ExpTech().getStations();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await _loadMapImages(isDark);
    _setupStationSource(data);
    _startDataUpdates();

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
          "cross",
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      _isMarkerVisible = !_isMarkerVisible;
      _isBoxVisible = !_isBoxVisible;
      await _updateCrossMarker();
      await _updateTsunamiLine();
      await _updateBoxLine();
    });
  }

  Future<void> _loadMapImages(bool isDark) async {
    await loadIntensityImage(_mapController, isDark);
    await loadCrossImage(_mapController);
  }

  void _setupStationSource(Map<String, Station> data) async {
    setState(() => _stations = data);
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
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRtsData();
      _updateEewData();
      setState(() {});
    });
  }

  bool _dataStatus() {
    bool status = (((_timeReplay == 0) ? _getCurrentTime() : _timeReplay) - _lsatGetRtsDataTime) < 3000;
    if (!status && _rtsData != null) {
      _rtsData = null;
      _mapController.setGeoJsonSource("station-geojson", _generateStationGeoJson(_rtsData));
      _mapController.setGeoJsonSource("station-geojson-intensity-0", _generateStationGeoJsonIntensity0(_rtsData));
    }
    return status;
  }

  void _updateRtsData() async {
    try {
      int t = DateTime.now().millisecondsSinceEpoch;
      final data = await ExpTech().getRts(_timeReplay);
      _ping = DateTime.now().millisecondsSinceEpoch - t;
      _rtsData = data;
      _lsatGetRtsDataTime = (_timeReplay == 0) ? _getCurrentTime() : _timeReplay;
      _updateReplayTime();
      _updateMarkers();
    } catch (err) {
      print(err);
    }
  }

  void _updateMarkers() async {
    await _mapController.setGeoJsonSource("station-geojson", _generateStationGeoJson(_rtsData));
    await _mapController.setGeoJsonSource("station-geojson-intensity-0", _generateStationGeoJsonIntensity0(_rtsData));
  }

  void _updateReplayTime() {
    if (_timeReplay != 0) {
      _timeReplay += (_replayTimeStamp == 0) ? 0 : DateTime.now().millisecondsSinceEpoch - _replayTimeStamp;
      _replayTimeStamp = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void _updateEewData() async {
    try {
      final data = await ExpTech().getEew(_timeReplay);
      _eewData = data;
      _processEewData(data);
      _updateEewVisuals();
    } catch (err) {
      print(err);
    }
  }

  Future<void> _updateCrossMarker() async {
    List markers_features = [];

    if (_isMarkerVisible) {
      for (var eew in _eewData) {
        markers_features.add({
          "type": "Feature",
          "properties": {
            "intensity": 10, // 10 is for classifying epicenter cross
          },
          "geometry": {
            "coordinates": [eew.eq.lon, eew.eq.lat],
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
    List<String> boxSkipList = [];
    for (var area in Global.box["features"]) {
      int id = area["properties"]["ID"];
      bool skip = checkBoxSkip(_eewData, _eewDist, area["geometry"]["coordinates"][0]);
      if (skip) {
        boxSkipList.add(id.toString());
      }
    }
    await _mapController.setLayerProperties(
      "box",
      LineLayerProperties(
        lineColor: (_rtsData!.box.keys.isEmpty || !_isBoxVisible)
            ? "#000000"
            : [
                'match',
                ['get', 'ID'],
                ..._rtsData!.box.entries.expand((entry) => [
                      int.parse(entry.key),
                      (entry.value > 3)
                          ? "#FF0000"
                          : (entry.value > 1)
                              ? "#EAC100"
                              : "#00DB00",
                    ]),
                "#000000",
              ],
        lineOpacity: (_rtsData!.box.keys.isEmpty || !_isBoxVisible)
            ? 0
            : [
                'match',
                ['get', 'ID'],
                ..._rtsData!.box.entries.expand((entry) => [
                      int.parse(entry.key),
                      (boxSkipList.contains(entry.key)) ? 0 : 1,
                    ]),
                0,
              ],
      ),
    );
  }

  void _processEewData(List<Eew> data) {
    for (var eew in data) {
      if (!_eewIdList.contains(eew.id)) {
        _eewIdList.add(eew.id);
        _addEewCircle(eew);
        _updateEewIntensityArea(eew);
        _updateMarkers();
      }
    }
    _updateMapArea();
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

  void _updateEewVisuals() {
    _eewUpdateTimer ??= Timer.periodic(const Duration(milliseconds: 100), (_) => _updateEewCircles());
    _removeOldEews();
  }

  void _updateEewCircles() async {
    _updateReplayTime();
    for (var eew in _eewData) {
      final dist = psWaveDist(eew.eq.depth, eew.eq.time, _getCurrentTime());
      _eewDist[eew.id] = dist["s_dist"]!;
      final circleData = circle(LatLng(eew.eq.lat, eew.eq.lon), dist["s_dist"]!, steps: 256);
      await _mapController.setGeoJsonSource("${eew.id}-circle", {
        "type": "FeatureCollection",
        "features": [circleData]
      });
      final circleDataP = circle(LatLng(eew.eq.lat, eew.eq.lon), dist["p_dist"]!, steps: 256);
      await _mapController.setGeoJsonSource("${eew.id}-circle-p", {
        "type": "FeatureCollection",
        "features": [circleDataP]
      });
    }
  }

  int _getCurrentTime() => (_timeReplay != 0) ? _timeReplay : DateTime.now().millisecondsSinceEpoch + _timeOffset;

  void _removeOldEews() {
    final currentEewIds = _eewData.map((e) => e.id).toSet();
    _eewIdList.removeWhere((id) {
      if (!currentEewIds.contains(id)) {
        _removeEewLayers(id);
        _eewIntensityArea.remove(id);
        _eewDist.remove(id);
        _updateMapArea();
        _updateMarkers();
        return true;
      }
      return false;
    });
  }

  void _removeEewLayers(String id) async {
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
          fillColor: Theme.of(context).colorScheme.surfaceVariant.toHexStringRGB(),
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
          Theme.of(context).colorScheme.surfaceVariant.toHexStringRGB(),
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
      if (_eewData.isNotEmpty) return false;
      return true;
    }).map((e) {
      Map<String, dynamic> properties = {};
      if (_rtsData!.box.keys.isNotEmpty && rtsData.station[e.key]?.alert == true) {
        properties = {"i": rtsData.station[e.key]?.I};
      } else {
        properties = {"i": rtsData.station[e.key]?.i};
      }

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
    sheetController.addListener(() {
      final newSize = sheetController.size;
      final scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);
      animController.animateTo(scrollPosition, duration: Duration.zero);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.16;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.i18n.monitor),
      ),
      body: Stack(
        children: [
          DpipMap(onMapCreated: _initMap),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: sheetInitialSize,
              minChildSize: sheetInitialSize,
              controller: sheetController,
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
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black12.withOpacity(0.5),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss').format((!_dataStatus())
                        ? DateTime.fromMillisecondsSinceEpoch(_lsatGetRtsDataTime)
                        : (_timeReplay == 0)
                            ? DateTime.fromMillisecondsSinceEpoch(_getCurrentTime())
                            : DateTime.fromMillisecondsSinceEpoch(_timeReplay)),
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
            left: 10,
            top: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black12.withOpacity(0.5),
                  ),
                  child: Text(
                    (!_dataStatus()) ? "999+ms" : "${_ping}ms",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: (!_dataStatus())
                            ? Colors.red
                            : (_ping > 250)
                                ? Colors.orange
                                : Colors.green),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
