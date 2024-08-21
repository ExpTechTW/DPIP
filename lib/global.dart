import 'dart:convert';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/location/location.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;
  static late Map<String, dynamic> geojson;
  static late Map<String, dynamic> timeTable;
  static late Map<String, dynamic> box;
  static ExpTech api = ExpTech();

  static loadLocationData() async {
    final json = await rootBundle.loadString("assets/location.json");
    final data = jsonDecode(json) as Map<String, dynamic>;

    location = data.map((key, value) => MapEntry(key, Location.fromJson(value)));
  }

  static loadGeoJsonData() async {
    final twCounty = await rootBundle.loadString("assets/map/tw_county.json");
    final twTown = await rootBundle.loadString("assets/map/tw_town.json");

    geojson = {
      "tw_county": jsonDecode(twCounty),
      "tw_town": jsonDecode(twTown),
    };
  }

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    preference = await SharedPreferences.getInstance();
    timeTable = jsonDecode(await rootBundle.loadString("assets/time.json"));
    box = jsonDecode(await rootBundle.loadString("assets/box.json"));

    await loadLocationData();
    await loadGeoJsonData();
  }
}
