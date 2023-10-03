import 'dart:convert';

import 'package:flutter/services.dart';

void FCM(Map data) async {
  final loc_data =
      json.decode(await rootBundle.loadString('assets/region.json'));
  print(data);
}
