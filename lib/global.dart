import 'dart:convert';

import 'package:dpip/model/location/location.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;

  static loadLocationData() async {
    final json = await rootBundle.loadString("assets/location.json");
    final data = jsonDecode(json) as Map<String, dynamic>;

    location = data.map((key, value) => MapEntry(key, Location.fromJson(value)));
  }

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    preference = await SharedPreferences.getInstance();

    await loadLocationData();
  }
}
