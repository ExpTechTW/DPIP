import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:dpip/api/model/eew.dart';

class DpipDataModel extends ChangeNotifier {
  List<Eew> _eew = [];
  UnmodifiableListView<Eew> get eew => UnmodifiableListView(_eew);
  void setEew(List<Eew> eew) {
    _eew = eew;
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
