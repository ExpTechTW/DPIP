import 'dart:convert';
import 'dart:io';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/utils/extensions/asset_bundle.dart';
import 'package:dpip/utils/log.dart';
import 'package:es_compression/zstd.dart';
import 'package:flutter/services.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef TimeTable = Map<String, List<({double P, double S, double R})>>;

class Global {
  Global._();

  static late PackageInfo packageInfo;
  static late SharedPreferences preference;
  static late Map<String, Location> location;
  static late GeoJSONFeatureCollection boxGeojson;
  static late GeoJSONFeatureCollection townGeojson;
  static late TimeTable timeTable;
  static late Map<String, ({String title, String body})> notifyTestContent;
  static ExpTech api = ExpTech();

  static Future<Map<String, dynamic>> _loadCompressedJson(
    String assetPath,
  ) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      late List<int> decompressed;

      if (assetPath.endsWith('.zst')) {
        decompressed = zstd.decode(bytes);
      } else if (assetPath.endsWith('.gz')) {
        decompressed = GZipCodec().decode(bytes);
      } else {
        decompressed = bytes;
      }

      final jsonString = utf8.decode(decompressed);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, s) {
      TalkerManager.instance.error(
        'Global._loadCompressedJson($assetPath)',
        e,
        s,
      );
      return {};
    }
  }

  static Future<Map<String, Location>> loadLocationData() async {
    final data = await _loadCompressedJson('assets/location.json.gz');
    return data.map(
      (key, value) =>
          MapEntry(key, Location.fromJson(value as Map<String, dynamic>)),
    );
  }

  static Future<TimeTable> loadTimeTableData() async {
    final data = await _loadCompressedJson('assets/time.json.gz');

    return data.map((key, value) {
      final list = (value as List).map((item) {
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
      return MapEntry(type, (
        title: map['title'].toString(),
        body: map['body'].toString(),
      ));
    });
  }

  static Future<GeoJSONFeatureCollection> loadBoxGeojson() async {
    final data = await rootBundle.loadJson('assets/box.json');

    return GeoJSONFeatureCollection.fromMap(data);
  }

  static Future<GeoJSONFeatureCollection> loadTownGeojson() async {
    final data = await _loadCompressedJson('assets/map/town.json.zst');

    return GeoJSONFeatureCollection.fromMap(data);
  }

  static Future init() async {
    final results = await Future.wait([
      PackageInfo.fromPlatform(),
      SharedPreferences.getInstance(),
      loadBoxGeojson(),
      loadLocationData(),
      loadTimeTableData(),
    ]);

    packageInfo = (results[0] as PackageInfo?)!;
    preference = (results[1] as SharedPreferences?)!;
    boxGeojson = (results[2] as GeoJSONFeatureCollection?)!;
    location = (results[3] as Map<String, Location>?)!;
    timeTable = (results[4] as TimeTable?)!;

    townGeojson = await loadTownGeojson();
    await loadNotifyTestContent();
  }
}
