import 'dart:collection';

import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:flutter/material.dart';

import 'package:dpip/api/model/eew.dart';

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

  int _timeOffset = 0;
  int get timeOffset => _timeOffset;
  void setTimeOffset(int timeOffset) {
    _timeOffset = timeOffset;
    notifyListeners();
  }

  int get currentTime => DateTime.now().millisecondsSinceEpoch + timeOffset;
}
