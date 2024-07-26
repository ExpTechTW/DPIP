import 'package:intl/intl.dart';

import '../model/eew.dart';
import '../model/station_info.dart';
import 'eew.dart';

StationInfo findAppropriateItem(List<StationInfo> infos, int date) {
  DateTime targetDate = (date == 0) ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(date);
  List<StationInfo> sortedItems = infos.toList()..sort((a, b) => a.time.compareTo(b.time));

  for (var i = 0; i < sortedItems.length; i++) {
    if (DateFormat('yyyy-MM-dd').parse(sortedItems[i].time).isAfter(targetDate)) {
      return i > 0 ? sortedItems[i - 1] : sortedItems[i];
    }
  }

  return sortedItems.last;
}

bool checkBoxSkip(List<Eew> eewData, Map<String, double> eewDist, List box) {
  bool passed = false;

  for (var eew in eewData) {
    int skip = 0;
    for (int i = 0; i < 4; i++) {
      final dist = distance(eew.eq.lat, eew.eq.lon, box[i][1], box[i][0]);
      if (eewDist[eew.id]! > dist) {
        skip++;
      }
    }
    if (skip >= 4) {
      passed = true;
      break;
    }
  }

  return passed;
}
