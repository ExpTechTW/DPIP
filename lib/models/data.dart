import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:dpip/api/model/station.dart';
import 'package:dpip/api/model/weather/lightning.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:geojson_vi/geojson_vi.dart';

class _DpipDataModel extends ChangeNotifier {
  Map<String, Station> _station = {};

  UnmodifiableMapView<String, Station> get station =>
      UnmodifiableMapView(_station);

  void setStation(Map<String, Station> station) {
    _station = station;
    notifyListeners();
  }

  Rts? _rts;

  Rts? get rts => _rts;
  int _rtsTime = 0;

  List<Eew> _eew = [
    // dummy data
    /* Eew(
      agency: 'cwa',
      id: '1140907',
      serial: 4,
      status: 0,
      isFinal: false,
      info: EewInfo(
        time: DateTime.now().millisecondsSinceEpoch,
        longitude: 120.48,
        latitude: 23.22,
        depth: 10,
        magnitude: 4.7,
        location: '臺南市楠西區',
        max: 4,
      ),
    ), */
  ];

  UnmodifiableListView<Eew> get eew => UnmodifiableListView(_eew);

  int _eewHash = 0;

  void setEew(List<Eew> eew) {
    // Calculate hash from EEW id and serial
    final newHash = Object.hashAll(eew.map((e) => Object.hash(e.id, e.serial)));

    // Only notify if EEW data actually changed
    if (_eewHash != newHash) {
      _eewHash = newHash;
      _eew = eew;
      TalkerManager.instance.debug('[setEew] notify: hash=$newHash');
      notifyListeners();
    }
  }

  List<PartialEarthquakeReport> _partialReport = [];

  UnmodifiableListView<PartialEarthquakeReport> get partialReport =>
      UnmodifiableListView(_partialReport);

  void setPartialReport(List<PartialEarthquakeReport> partialReport) {
    _partialReport = partialReport;
    notifyListeners();
  }

  void appendPartialReport(List<PartialEarthquakeReport> partialReport) {
    final existingIds = _partialReport.map((r) => r.id).toSet();
    final newReports = partialReport
        .where((r) => !existingIds.contains(r.id))
        .toList();
    if (newReports.isNotEmpty) {
      _partialReport = [..._partialReport, ...newReports];
      notifyListeners();
    }
  }

  Map<String, EarthquakeReport> _report = {};

  UnmodifiableMapView<String, EarthquakeReport> get report =>
      UnmodifiableMapView(_report);

  void setReport(String id, EarthquakeReport report) {
    _report[id] = report;
    notifyListeners();
  }

  void setReports(Map<String, EarthquakeReport> report) {
    _report = report;
    notifyListeners();
  }

  List<String> _radar = [];

  UnmodifiableListView<String> get radar => UnmodifiableListView(_radar);

  void setRadar(List<String> radar) {
    _radar = radar;
    notifyListeners();
  }

  List<String> _temperature = [];

  UnmodifiableListView<String> get temperature =>
      UnmodifiableListView(_temperature);

  void setTemperature(List<String> temperature) {
    _temperature = temperature;
    notifyListeners();
  }

  final Map<String, List<WeatherStation>> _weatherData = {};

  UnmodifiableMapView<String, List<WeatherStation>> get weatherData =>
      UnmodifiableMapView(_weatherData);

  void setWeatherData(String time, List<WeatherStation> weather) {
    _weatherData[time] = weather;
    notifyListeners();
  }

  List<String> _precipitation = [];

  UnmodifiableListView<String> get precipitation =>
      UnmodifiableListView(_precipitation);

  void setPrecipitation(List<String> precipitation) {
    _precipitation = precipitation;
    notifyListeners();
  }

  final Map<String, List<RainStation>> _rainData = {};

  UnmodifiableMapView<String, List<RainStation>> get rainData =>
      UnmodifiableMapView(_rainData);

  void setRainData(String time, List<RainStation> rain) {
    _rainData[time] = rain;
    notifyListeners();
  }

  List<String> _wind = [];

  UnmodifiableListView<String> get wind => UnmodifiableListView(_wind);

  void setWind(List<String> wind) {
    _wind = wind;
    notifyListeners();
  }

  List<String> _lightning = [];

  UnmodifiableListView<String> get lightning =>
      UnmodifiableListView(_lightning);

  void setLightning(List<String> lightning) {
    _lightning = lightning;
    notifyListeners();
  }

  final Map<String, List<Lightning>> _lightningData = {};

  UnmodifiableMapView<String, List<Lightning>> get lightningData =>
      UnmodifiableMapView(_lightningData);

  void setLightningData(String time, List<Lightning> lightning) {
    _lightningData[time] = lightning;
    notifyListeners();
  }

  int _timeOffset = 0;

  int get timeOffset => _timeOffset;

  void setTimeOffset(int timeOffset) {
    _timeOffset = timeOffset;
    notifyListeners();
  }
}

class DpipDataModel extends _DpipDataModel {
  static const int _eewActiveWindow =
      4 * 60 * 1000; // 4 minutes in milliseconds
  static const double _rtsCoordinateOffset =
      0.00009; // ~5m displacement for privacy

  Timer? _secondTimer;
  Timer? _minuteTimer;
  bool _isInForeground = true;
  bool _isReplayMode = false;
  int? _replayTimestamp;
  int? _replayStartTime;
  final Random _random = Random();
  int? _syncDistance;
  int _lastSyncTime = 0;

  int get currentTime {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _isReplayMode && _replayTimestamp != null && _replayStartTime != null
        ? _replayTimestamp! + (now - _replayStartTime!)
        : now + timeOffset;
  }

  UnmodifiableListView<Eew> get activeEew {
    final cutoffTime = currentTime - _eewActiveWindow;
    return UnmodifiableListView(
      _eew.where((eew) => eew.info.time >= cutoffTime).toList(),
    );
  }

  void setRts(Rts rts) {
    final incoming = rts.time;
    if (!_isReplayMode && incoming <= _rtsTime) return;
    _rtsTime = incoming;
    _rts = rts;
    notifyListeners();
  }

  int? get syncTime {
    if (_rts != null) return _rts!.time;
    if (_isReplayMode) return currentTime;

    return null;
  }

  void setReplayMode(bool isReplay, [int? timestamp]) {
    _isReplayMode = isReplay;
    if (isReplay) {
      if (timestamp == null) {
        throw ArgumentError('Timestamp must be provided in replay mode');
      }
      _replayTimestamp = timestamp;
      _replayStartTime = DateTime.now().millisecondsSinceEpoch;
      _rtsTime = timestamp - 1;
    } else {
      _replayTimestamp = null;
      _replayStartTime = null;
      _rtsTime = 0;
    }
    notifyListeners();
  }

  void _updateRtsData(Rts? rts, List<Eew> eew) {
    if (rts != null) {
      _syncDistance = currentTime - rts.time;
      setRts(rts);
    }
    setEew(eew);
  }

  Future<(Rts?, List<Eew>)> _fetchRtsData() async {
    try {
      final data = _isReplayMode
          ? await Future.wait([
        ExpTech().getRts(currentTime),
        ExpTech().getEew(currentTime),
      ])
          : await Future.wait([ExpTech().getRts(), ExpTech().getEew()]);

      return (data[0] as Rts, data[1] as List<Eew>);
    } on Rtsnodata {
      final eew =
      _isReplayMode ? await ExpTech().getEew(currentTime) : <Eew>[];
      return (null, eew);
    }
  }

  Future<void> fetchRtsImmediately() async {
    if (!_isInForeground) return;
    try {
      final (rts, eew) = await _fetchRtsData();
      _updateRtsData(rts, eew);
    } catch (e, s) {
      TalkerManager.instance.error('fetchRtsImmediately', e, s);
    }
  }

  void startFetching() {
    if (_secondTimer != null) return;

    Future<void> fetchCallback() async {
      if (!_isInForeground) return;
      try {
        final (rts, eew) = await _fetchRtsData();
        _updateRtsData(rts, eew);
      } catch (e, s) {
        TalkerManager.instance.error('fetchCallback', e, s);
      }
    }

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isInForeground) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastSync = now - _lastSyncTime;
      final shouldSync = timeSinceLastSync >= 10000;

      await fetchCallback();

      if (shouldSync && _syncDistance != null) {
        _lastSyncTime = now;

        final serverMs =
            (currentTime % 1000 - _syncDistance! % 1000 + 1000) % 1000;
        final delayToNextSecond = serverMs == 0 ? 1000 : (1000 - serverMs);

        Timer(Duration(milliseconds: delayToNextSecond), () async {
          if (!_isInForeground) return;
          try {
            final (rts, eew) = await _fetchRtsData();
            _updateRtsData(rts, eew);
          } catch (e, s) {
            TalkerManager.instance.error('syncCallback', e, s);
          }
        });
      }
    });

    _lastSyncTime = DateTime.now().millisecondsSinceEpoch;
    fetchCallback();

    Future<void> everyMinuteCallback() async {
      if (!_isInForeground) return;

      try {
        final data = await Future.wait(
          [ExpTech().getNtp(), ExpTech().getStations()],
          cleanUp: (successValue) {
            switch (successValue) {
              case int():
                setTimeOffset(
                  successValue - DateTime.now().millisecondsSinceEpoch,
                );
              case Map<String, Station>():
                setStation(successValue);
            }
          },
        );

        final [ntp as int, stations as Map<String, Station>] = data;
        setTimeOffset(ntp - DateTime.now().millisecondsSinceEpoch);
        setStation(stations);
      } catch (e, s) {
        TalkerManager.instance.error('everyMinuteCallback', e, s);
      }
    }

    everyMinuteCallback();
    _minuteTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => everyMinuteCallback(),
    );
  }

  void stopFetching() {
    _secondTimer?.cancel();
    _secondTimer = null;
    _minuteTimer?.cancel();
    _minuteTimer = null;
    _lastSyncTime = 0;
  }

  int? get lastRtsPing => _syncDistance;

  void onAppLifecycleStateChanged(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    if (_isInForeground) {
      startFetching();
    } else {
      stopFetching();
    }
  }

  @override
  void dispose() {
    stopFetching();
    super.dispose();
  }

  Map<String, dynamic> getRtsGeoJson() {
    final rts = this.rts;
    final builder = GeoJsonBuilder();

    for (final MapEntry(key: id, value: s) in station.entries) {
      if (!s.work) continue;

      final baseCoordinates = s.info.last.latlng.asGeoJsonCooridnate;
      final offsetLng = (_random.nextDouble() - 0.5) * _rtsCoordinateOffset;
      final offsetLat = (_random.nextDouble() - 0.5) * _rtsCoordinateOffset;
      final displacedCoordinates = [
        baseCoordinates[0] + offsetLng,
        baseCoordinates[1] + offsetLat,
      ];

      final feature = GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        ..setGeometry(displacedCoordinates)
        ..setId(int.parse(id))
        ..setProperty('id', id)
        ..setProperty('net', s.net)
        ..setProperty('code', s.info.last.code);

      if (rts != null) {
        final data = rts.station[id];
        if (data != null) {
          feature
            ..setProperty('i', data.i)
            ..setProperty('I', data.I)
            ..setProperty('pga', data.pga)
            ..setProperty('pgv', data.pgv);
        }
      }

      final location = Global.location['${s.info.last.code}'];
      if (location != null) {
        feature
          ..setProperty('city', location.cityWithLevel)
          ..setProperty('town', location.townWithLevel);
      }

      builder.addFeature(feature);
    }

    return builder.build();
  }

  Map<String, dynamic> getEewGeoJson() {
    final eew = activeEew;
    if (eew.isEmpty) return GeoJsonBuilder().build();

    final builder = GeoJsonBuilder();
    final now = currentTime;

    for (final e in eew) {
      final radius = calcWaveRadius(e.info.depth, e.info.time, now);
      final center = e.info.latlng;

      if (radius.p > 0) {
        builder.addFeature(
          circleFeature(center: center, radius: radius.p)
            ..setProperty('type', 'p'),
        );
      }

      if (radius.s > 0) {
        builder.addFeature(
          circleFeature(center: center, radius: radius.s)
            ..setProperty('type', 's'),
        );
      }

      builder.addFeature(
        GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
          ..setGeometry(center.asGeoJsonCooridnate)
          ..setProperty('type', 'x'),
      );
    }

    return builder.build();
  }

  Map<String, dynamic> getIntensityGeoJson() {
    final rts = this.rts;
    final builder = GeoJsonBuilder();

    for (final MapEntry(key: id, value: s) in station.entries) {
      if (!s.work) continue;

      final feature = GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        ..setGeometry(s.info.last.latlng.asGeoJsonCooridnate)
        ..setId(int.parse(id))
        ..setProperty('net', s.net)
        ..setProperty('code', s.info.last.code);

      if (rts != null) {
        final data = rts.station[id];
        if (data != null) {
          final isAlert = data.alert ?? false;
          feature
            ..setProperty(
              'intensity',
              intensityFloatToInt(isAlert ? data.I : data.i),
            )
            ..setProperty('alert', isAlert ? 1 : 0);
        }
      }

      builder.addFeature(feature);
    }

    return builder.build();
  }

  Map<String, dynamic> getBoxGeoJson() {
    final rts = this.rts;
    if (rts == null || rts.box.isEmpty) return GeoJsonBuilder().build();

    final builder = GeoJsonBuilder();
    final now = currentTime;
    final activeEew = eew;

    // Precompute EEW data if needed
    Map<String, Eew>? eewMap;
    Map<String, double>? eewDistMap;
    if (activeEew.isNotEmpty) {
      eewMap = {for (final e in activeEew) e.id: e};
      eewDistMap = {
        for (final e in activeEew)
          e.id: calcWaveRadius(e.info.depth, e.info.time, now).s * 1000,
      };
    }

    for (final area in Global.boxGeojson.features) {
      if (area == null) continue;

      final id = area.properties!['ID'].toString();
      if (!rts.box.containsKey(id)) continue;

      final coordinates = (area.geometry! as GeoJSONPolygon).coordinates[0];

      if (eewMap != null &&
          eewDistMap != null &&
          checkBoxSkip(eewMap, eewDistMap, coordinates)) {
        continue;
      }

      builder.addFeature(
        GeoJsonFeatureBuilder(GeoJsonFeatureType.Polygon)
          ..setGeometry(coordinates)
          ..setProperty('i', rts.box[id]),
      );
    }

    return builder.build();
  }
}
