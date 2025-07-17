import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/utils/extensions/asset_bundle.dart';
import 'package:dpip/utils/location_to_code.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  Global._();

  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;
  static late Map<String, dynamic> geojson;
  static late Map<String, List<({double P, double S, double R})>> timeTable;
  static late Map<String, dynamic> box;
  static late Map<String, ({String title, String body})> notifyTestContent;
  static ExpTech api = ExpTech();

  static Future<void> loadLocationData() async {
    final data = await rootBundle.loadJson('assets/location.json');

    location = data.map((key, value) => MapEntry(key, Location.fromJson(value as Map<String, dynamic>)));
  }

  static Future<void> loadTimeTableData() async {
    final data = await rootBundle.loadJson('assets/time.json');

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

  static Future<void> loadNotifyTestContent() async {
    final data = await rootBundle.loadJson('assets/notify_test.json');

    notifyTestContent = data.map((type, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(type, (title: map['title'].toString(), body: map['body'].toString()));
    });
  }

  static Future init() async {
    packageInfo = await PackageInfo.fromPlatform();
    preference = await SharedPreferences.getInstance();
    box = await rootBundle.loadJson('assets/box.json');

    await loadLocationData();
    await loadTimeTableData();
    await loadNotifyTestContent();

    await GeoJsonHelper.loadGeoJson('assets/map/town.json');
  }
}
