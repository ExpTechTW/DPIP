import 'package:flutter/foundation.dart';

class RtsState extends ChangeNotifier {
  bool isExpanded1 = false;
  bool isExpanded2 = false;
  bool isExpanded3 = false;

  void toggleExpansion(int index) {
    switch (index) {
      case 1:
        isExpanded1 = !isExpanded1;
        break;
      case 2:
        isExpanded2 = !isExpanded2;
        break;
      case 3:
        isExpanded3 = !isExpanded3;
        break;
    }
    notifyListeners();
  }
}
