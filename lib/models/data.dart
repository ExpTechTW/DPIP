import 'dart:async';
import 'dart:collection';

import 'package:dpip/utils/geojson.dart';
import 'package:flutter/material.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:dpip/api/model/station.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/utils/log.dart';

class _DpipDataModel extends ChangeNotifier {
  Map<String, Station> _station = {};
  UnmodifiableMapView<String, Station> get station => UnmodifiableMapView(_station);
  void setStation(Map<String, Station> station) {
    _station = station;
    notifyListeners();
  }

  Rts? _rts;
  Rts? get rts => _rts;
  void setRts(Rts rts) {
    _rts = rts;
    notifyListeners();
  }

  List<Eew> _eew = [];
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
  Timer? _secondTimer;
  Timer? _minuteTimer;
  bool _isInForeground = true;

  int get currentTime => DateTime.now().millisecondsSinceEpoch + timeOffset;

  void startFetching() {
    if (_secondTimer != null) return;

    Future<void> everySecondCallback() async {
      if (!_isInForeground) return;

      try {
        final data = await Future.wait(
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
      final feature =
          GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
            ..setGeometry(s.info.last.latlng.toGeoJsonCoordinates())
            ..setId(int.parse(id))
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

      builder.addFeature(feature);
    }

    return builder.build();
  }
}
