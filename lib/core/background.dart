import 'dart:convert';

import 'package:flutter/services.dart';

Future<Map<String, dynamic>> FCM(Map data) async {
  var ans = {
    "code": (DateTime.now().millisecondsSinceEpoch / 1000).round(),
    "title": "title",
    "body": "body",
    "channel": "default",
    "sound": "default",
    "level": 0,
  };
  final loc_data =
      json.decode(await rootBundle.loadString('assets/region.json'));
  print(data["type"]);
  return ans;
}
