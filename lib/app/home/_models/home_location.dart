import 'package:flutter/material.dart';

class HomeLocationModel extends ChangeNotifier {
  String? _temporaryCode;

  String? get temporaryCode => _temporaryCode;

  void setTemporaryCode(String? code) {
    if (_temporaryCode == code) return;
    _temporaryCode = code;
    notifyListeners();
  }
}
