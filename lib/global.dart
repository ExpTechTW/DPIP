import 'dart:convert';

import 'package:dpip/core/api.dart';
import 'package:dpip/model/town.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart';

class Global {
  static late ExpTechApi api;
  static late SharedPreferences preference;
  static late PackageInfo packageInfo;

  static Map<String, Map<String, Town>> region = {};

  static Future init() async {
    api = ExpTechApi();
    preference = await SharedPreferences.getInstance();
    packageInfo = await PackageInfo.fromPlatform();

    initializeTimeZones();

    // src: assets/json/region.json
    Map<String, dynamic> regionRaw =
        jsonDecode(await rootBundle.loadString("assets/region.json"));

    regionRaw.forEach((cityName, city) {
      region[cityName] = <String, Town>{};
      if (city is Map) {
        city.forEach((townName, json) {
          region[cityName]![townName] = Town.fromJson(json);
        });
      }
    });
  }
}
