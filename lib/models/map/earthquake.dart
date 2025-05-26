import 'package:dpip/api/model/eew.dart';
import 'package:dpip/api/model/rts/rts.dart';
import 'package:flutter/material.dart';

class MapEarthquakeModel extends ChangeNotifier {
  final rts = ValueNotifier<Rts?>(null);
  final eew = <String, Eew?>{};

  void setRts(Rts? rts) {
    this.rts.value = rts;
    notifyListeners();
  }

  void setEew(String id, Eew? eew) {
    this.eew[id] = eew;
    notifyListeners();
  }
}
