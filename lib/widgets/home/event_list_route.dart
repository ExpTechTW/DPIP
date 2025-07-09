import 'package:dpip/api/model/history.dart';
import 'package:dpip/route/event_viewer/intensity.dart';
import 'package:dpip/route/event_viewer/thunderstorm.dart';
import 'package:dpip/route/report/report.dart';
import 'package:flutter/material.dart';

final Map<String, Widget Function(History item)> typeConfigs = {
  'thunderstorm': (History item) => ThunderstormPage(item: item),
  'heavy-rain': (History item) => ThunderstormPage(item: item),
  'extremely-heavy-rain': (History item) => ThunderstormPage(item: item),
  'torrential-rain': (History item) => ThunderstormPage(item: item),
  'extremely-torrential-rain': (History item) => ThunderstormPage(item: item),
  'earthquake': (History item) => ReportRoute(id: item.addition?['id']),
  'intensity': (History item) => IntensityPage(item: item),
};

bool shouldShowArrow(History item) {
  return typeConfigs[item.type] != null ? true : false;
}

void handleEventList(BuildContext context, History current) {
  final build = typeConfigs[current.type];
  if (build != null) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => build(current)));
  } else {
    print('Unknown type: ${current.type}');
  }
}
