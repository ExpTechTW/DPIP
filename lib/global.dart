import "dart:convert";

import "package:flutter/services.dart";

import "package:package_info_plus/package_info_plus.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:dpip/api/exptech.dart";
import "package:dpip/api/model/location/location.dart";
import "package:dpip/utils/location_to_code.dart";

class Global {
  Global._();

  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;
  static late Map<String, dynamic> geojson;
  static late Map<String, dynamic> timeTable;
  static late Map<String, dynamic> box;
  static ExpTech api = ExpTech();

  static Future<void> loadLocationData() async {
    final json = await rootBundle.loadString("assets/location.json");
    final data = jsonDecode(json) as Map<String, dynamic>;

    location = data.map((key, value) => MapEntry(key, Location.fromJson(value as Map<String, dynamic>)));
  }

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    preference = await SharedPreferences.getInstance();
    timeTable = jsonDecode(await rootBundle.loadString("assets/time.json")) as Map<String, dynamic>;
    box = jsonDecode(await rootBundle.loadString("assets/box.json")) as Map<String, dynamic>;

    await loadLocationData();
    await GeoJsonHelper.loadGeoJson('assets/map/town.json');
  }
}
