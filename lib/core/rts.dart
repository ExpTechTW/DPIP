import 'package:intl/intl.dart';

import '../model/station_info.dart';

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
