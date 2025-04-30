import "package:intl/intl.dart";

import "package:dpip/api/model/eew.dart";
import "package:dpip/api/model/station_info.dart";
import "package:dpip/core/eew.dart";

StationInfo findAppropriateItem(List<StationInfo> infos, int date) {
  DateTime targetDate = (date == 0) ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(date);
  List<StationInfo> sortedItems = infos.toList()..sort((a, b) => a.time.compareTo(b.time));

  for (var i = 0; i < sortedItems.length; i++) {
    if (DateFormat("yyyy-MM-dd").parse(sortedItems[i].time).isAfter(targetDate)) {
      return i > 0 ? sortedItems[i - 1] : sortedItems[i];
    }
  }

  return sortedItems.last;
}

bool checkBoxSkip(Map<String, Eew> eewLastInfo, Map<String, double> eewDist, List box) {
  bool passed = false;

  for (var eew in eewLastInfo.keys) {
    int skip = 0;
    for (int i = 0; i < 4; i++) {
      final dist = distance(eewLastInfo[eew]!.eq.latitude, eewLastInfo[eew]!.eq.longitude, box[i][1], box[i][0]);
      if (eewDist[eew]! > dist) {
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
