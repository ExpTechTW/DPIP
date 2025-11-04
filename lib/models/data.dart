import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:geojson_vi/geojson_vi.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:dpip/api/model/station.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';

class _DpipDataModel extends ChangeNotifier {
  Map<String, Station> _station = {};

  UnmodifiableMapView<String, Station> get station => UnmodifiableMapView(_station);

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

  void setEew(List<Eew> eew) {
    _eew = eew;
    notifyListeners();
  }

  List<PartialEarthquakeReport> _partialReport = [];

  UnmodifiableListView<PartialEarthquakeReport> get partialReport => UnmodifiableListView(_partialReport);

  void setPartialReport(List<PartialEarthquakeReport> partialReport) {
    _partialReport = partialReport;
    notifyListeners();
  }

  Map<String, EarthquakeReport> _report = {};

  UnmodifiableMapView<String, EarthquakeReport> get report => UnmodifiableMapView(_report);

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

  UnmodifiableListView<String> get temperature => UnmodifiableListView(_temperature);

  void setTemperature(List<String> temperature) {
    _temperature = temperature;
    notifyListeners();
  }

  final Map<String, List<WeatherStation>> _weatherData = {};

  UnmodifiableMapView<String, List<WeatherStation>> get weatherData => UnmodifiableMapView(_weatherData);

  void setWeatherData(String time, List<WeatherStation> weather) {
    _weatherData[time] = weather;
    notifyListeners();
  }

  List<String> _precipitation = [];

  UnmodifiableListView<String> get precipitation => UnmodifiableListView(_precipitation);

  void setPrecipitation(List<String> precipitation) {
    _precipitation = precipitation;
    notifyListeners();
  }

  final Map<String, List<RainStation>> _rainData = {};

  UnmodifiableMapView<String, List<RainStation>> get rainData => UnmodifiableMapView(_rainData);

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

  int _timeOffset = 0;

  int get timeOffset => _timeOffset;

  void setTimeOffset(int timeOffset) {
    _timeOffset = timeOffset;
    notifyListeners();
  }
}

class DpipDataModel extends _DpipDataModel {
  static const int _replayTimeWindow = 1000;
  Timer? _secondTimer;
  Timer? _minuteTimer;
  bool _isInForeground = true;
  bool _isReplayMode = false;
  int? _replayTimestamp;

  int get currentTime => _isReplayMode
      ? (_replayTimestamp ?? DateTime.now().millisecondsSinceEpoch)
      : DateTime.now().millisecondsSinceEpoch + timeOffset;

  /// Returns only active EEWs (within 3 minutes of current app time)
  UnmodifiableListView<Eew> get activeEew {
    final threeMinutesAgo = currentTime - (3 * 60 * 1000);

    return UnmodifiableListView(_eew.where((eew) => eew.info.time >= threeMinutesAgo).toList());
  }

  UnmodifiableListView<Eew> get cwaEew =>
      UnmodifiableListView(_eew.where((eew) => eew.agency.toLowerCase() == 'cwa').toList());

  /// Sets the RTS (Real-Time Shaking) data if it's newer than the current data.
  ///
  /// In replay mode, filters out RTS data that is more than 1 second ahead
  /// of the current replay timestamp to maintain temporal consistency and
  /// prevent displaying future data during replay.
  ///
  /// @param rts The new RTS data to set
  void setRts(Rts rts) {
    final incoming = rts.time;

    if (_isReplayMode && _replayTimestamp != null && incoming > _replayTimestamp! + _replayTimeWindow) {
      return;
    }

    if (incoming > _rtsTime) {
      _rtsTime = incoming;
      _rts = rts;
      notifyListeners();
    }
  }

  void setReplayMode(bool isReplay, [int? timestamp]) {
    _isReplayMode = isReplay;
    if (isReplay) {
      if (timestamp == null) {
        throw ArgumentError('Timestamp must be provided in replay mode');
      }
      _replayTimestamp = timestamp;
      _rtsTime = timestamp - 1;
    } else {
      _replayTimestamp = null;
      _rtsTime = 0;
    }
  }

  void startFetching() {
    if (_secondTimer != null) return;

    Future<void> everySecondCallback() async {
      if (!_isInForeground) return;

      try {
        final data = _isReplayMode
            ? await Future.wait(
                [ExpTech().getRts(_replayTimestamp), ExpTech().getEew(_replayTimestamp)],
                cleanUp: (successValue) {
                  switch (successValue) {
                    case Rts():
                      setRts(successValue);
                    case List<Eew>():
                      setEew(successValue);
                  }
                },
              )
            : await Future.wait(
                [ExpTech().getRts(), ExpTech().getEew()],
                cleanUp: (successValue) {
                  switch (successValue) {
                    case Rts():
                      setRts(successValue);
                    case List<Eew>():
                      setEew(successValue);
                  }
                },
              );

        final [rts as Rts, eew as List<Eew>] = data;
        setRts(rts);
        setEew(eew);

        if (_isReplayMode && _replayTimestamp != null) {
          _replayTimestamp = _replayTimestamp! + 1000;
        }
      } catch (e, s) {
        TalkerManager.instance.error('everySecondCallback', e, s);
      }
    }

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) => everySecondCallback());

    Future<void> everyMinuteCallback() async {
      if (!_isInForeground) return;

      try {
        final data = await Future.wait(
          [ExpTech().getNtp(), ExpTech().getStations()],
          cleanUp: (successValue) {
            switch (successValue) {
              case int():
                setTimeOffset(DateTime.now().millisecondsSinceEpoch - successValue);
              case Map<String, Station>():
                setStation(successValue);
            }
          },
        );

        final [ntp as int, stations as Map<String, Station>] = data;
        setTimeOffset(DateTime.now().millisecondsSinceEpoch - ntp);
        setStation(stations);
      } catch (e, s) {
        TalkerManager.instance.error('everyMinuteCallback', e, s);
      }
    }

    everyMinuteCallback();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) => everyMinuteCallback());
  }

  void stopFetching() {
    _secondTimer?.cancel();
    _secondTimer = null;
    _minuteTimer?.cancel();
    _minuteTimer = null;
  }

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
      if (s.work == false) continue;

      final coordinates = s.info.last.latlng.asGeoJsonCooridnate;

      // Create displaced coordinates with ~5 meter random offset
      final random = Random();
      final offsetLng = (random.nextDouble() - 0.5) * 0.00009; // ~5m longitude offset
      final offsetLat = (random.nextDouble() - 0.5) * 0.00009; // ~5m latitude offset
      final displacedCoordinates = [coordinates[0] + offsetLng, coordinates[1] + offsetLat];

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
    final builder = GeoJsonBuilder();

    for (final e in eew) {
      final radius = calcWaveRadius(e.info.depth, e.info.time, currentTime);

      if (radius.p > 0) {
        final pWave = circleFeature(center: e.info.latlng, radius: radius.p)..setProperty('type', 'p');
        builder.addFeature(pWave);
      }

      if (radius.s > 0) {
        final sWave = circleFeature(center: e.info.latlng, radius: radius.s)..setProperty('type', 's');
        builder.addFeature(sWave);
      }

      final epicenter = GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        ..setGeometry(e.info.latlng.asGeoJsonCooridnate)
        ..setProperty('type', 'x');

      builder.addFeature(epicenter);
    }

    return builder.build();
  }

  Map<String, dynamic> getIntensityGeoJson() {
    final rts = this.rts;
    final builder = GeoJsonBuilder();

    for (final MapEntry(key: id, value: s) in station.entries) {
      if (s.work == false) continue;
      final feature = GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        ..setGeometry(s.info.last.latlng.asGeoJsonCooridnate)
        ..setId(int.parse(id))
        ..setProperty('net', s.net)
        ..setProperty('code', s.info.last.code);

      if (rts != null) {
        final data = rts.station[id];

        if (data != null) {
          feature.setProperty('intensity', intensityFloatToInt(data.alert! ? data.I : data.i));
          feature.setProperty('alert', data.alert! ? 1 : 0);
        }
      }

      builder.addFeature(feature);
    }

    return builder.build();
  }

  Map<String, dynamic> getBoxGeoJson() {
    final rts = this.rts;
    final builder = GeoJsonBuilder();

    if (rts != null && rts.box.isNotEmpty) {
      for (final area in Global.boxGeojson.features) {
        if (area == null) continue;

        final id = area.properties!['ID'].toString();
        if (!rts.box.containsKey(id)) continue;

        final geometry = area.geometry! as GeoJSONPolygon;

        final coordinates = geometry.coordinates[0];

        if (eew.isNotEmpty == true) {
          final eewMap = {for (final e in eew) e.id: e};
          final eewDistMap = {
            for (final e in eew) e.id: calcWaveRadius(e.info.depth, e.info.time, currentTime).s * 1000,
          };

          if (checkBoxSkip(eewMap, eewDistMap, coordinates)) continue;
        }

        final feature = GeoJsonFeatureBuilder(GeoJsonFeatureType.Polygon)
          ..setGeometry(coordinates)
          ..setProperty('i', rts.box[id]);

        builder.addFeature(feature);
      }
    }

    return builder.build();
  }
}
