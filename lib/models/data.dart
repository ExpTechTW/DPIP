import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/api/model/weather/rain.dart';

class DpipDataModel extends ChangeNotifier {
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

  int get currentTime => DateTime.now().millisecondsSinceEpoch + timeOffset;
}
