import 'package:flutter/material.dart';

import 'package:dpip/api/model/eew.dart';

class DpipDataModel extends ChangeNotifier {
  List<Eew> eew = [];
  void setEew(List<Eew> eew) {
    this.eew = eew;
    notifyListeners();
  }

  int timeOffset = 0;
  void setTimeOffset(int timeOffset) {
    this.timeOffset = timeOffset;
    notifyListeners();
  }

  int get currentTime => DateTime.now().millisecondsSinceEpoch + timeOffset;
}
