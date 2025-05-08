import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/utils/location_to_code.dart';

class Global {
  Global._();

  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;
  static late Map<String, dynamic> geojson;
  static late Map<String, List<({double P, double S, double R})>> timeTable;
  static late Map<String, dynamic> box;
  static ExpTech api = ExpTech();

  static Future<void> loadLocationData() async {
    final json = await rootBundle.loadString('assets/location.json');
    final data = jsonDecode(json) as Map<String, dynamic>;

    location = data.map((key, value) => MapEntry(key, Location.fromJson(value as Map<String, dynamic>)));
  }

  static Future<void> loadTimeTableData() async {
    final json = await rootBundle.loadString('assets/time.json');
    final data = jsonDecode(json) as Map<String, dynamic>;

    timeTable = data.map((key, value) {
      final list =
          (value as List).map((item) {
            final map = item as Map<String, dynamic>;
            return (
              P: double.parse(map['P'].toString()),
              R: double.parse(map['R'].toString()),
              S: double.parse(map['S'].toString()),
            );
          }).toList();
      return MapEntry(key, list);
    });
  }

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    preference = await SharedPreferences.getInstance();
    box = jsonDecode(await rootBundle.loadString('assets/box.json')) as Map<String, dynamic>;

    await loadLocationData();
    await loadTimeTableData();

    await GeoJsonHelper.loadGeoJson('assets/map/town.json');
  }
}
