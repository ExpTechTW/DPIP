import 'package:dpip/model/history.dart';
import 'package:dpip/route/event_viewer/thunderstorm.dart';
import 'package:flutter/material.dart';

class TypeConfig {
  final Widget Function(History item) buildPage;

  TypeConfig({required this.buildPage});
}

final Map<String, TypeConfig> typeConfigs = {
  'thunderstorm': TypeConfig(
    buildPage: (History item) => ThunderstormPage(item: item),
  ),
};

bool shouldShowArrow(dynamic item) {
  return typeConfigs[item.type] != null ? true : false;
}

void handleEventList(BuildContext context, dynamic current) {
  final config = typeConfigs[current.type];
  if (config != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => config.buildPage(current),
      ),
    );
  } else {
    print('Unknown type: ${current.type}');
  }
}
