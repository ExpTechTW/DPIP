import 'package:flutter/foundation.dart';

class RtsState extends ChangeNotifier {
  bool isSeismometerExpanded = false;
  bool isTremNetExpanded = false;
  bool isWaveExplanationExpanded = false;

  void toggleSeismometerExpansion() {
    isSeismometerExpanded = !isSeismometerExpanded;
    notifyListeners();
  }

  void toggleTremNetExpansion() {
    isTremNetExpanded = !isTremNetExpanded;
    notifyListeners();
  }

  void toggleWaveExplanationExpansion() {
    isWaveExplanationExpanded = !isWaveExplanationExpanded;
    notifyListeners();
  }
}
