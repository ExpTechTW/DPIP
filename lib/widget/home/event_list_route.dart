import 'package:dpip/route/announcement/announcement.dart';
import 'package:flutter/material.dart';

class TypeConfig {
  final Widget Function(dynamic item) buildPage;
  final bool showArrow;

  TypeConfig({required this.buildPage, this.showArrow = true});
}

final Map<String, TypeConfig> typeConfigs = {
  'thunderstorm': TypeConfig(
    buildPage: (item) => AnnouncementPage(),
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
