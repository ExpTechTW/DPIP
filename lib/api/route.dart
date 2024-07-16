import 'dart:io';
import 'dart:math';

import 'package:dpip/global.dart';

class Route {
  static String get api => baseApi();

  static String get onlyapi => baseApi(i: 1);

  static String baseApi({int? i}) {
    i ??= Random().nextInt(2) + 1;

    return "https://api-$i.exptech.dev/api";
  }

  static String get lb => baseLb();

  static String baseLb({int? i}) {
    i ??= Random().nextInt(4) + 1;

    return "https://lb-$i.exptech.dev/api";
  }

  static Uri reportList({int? limit = 50}) => Uri.parse("$api/v2/eq/report?limit=$limit");
  static Uri report(String reportId) => Uri.parse("$api/v2/eq/report/$reportId");
  static Uri tsunamiList() => Uri.parse("$onlyapi/v1/tsunami/list");
  static Uri tsunami(String tsuId) => Uri.parse("$onlyapi/v1/tsunami/$tsuId");
  static Uri rts() => Uri.parse("$lb/v1/trem/rts");
  static Uri eew() => Uri.parse("$lb/v1/eq/eew");
  static Uri weatherRealtime(String postalCode) => Uri.parse("$onlyapi/v1/weather/realtime/$postalCode");
  static Uri station() => Uri.parse("$api/v1/trem/station");
  static Uri location(String token, String lat, String lng) =>
      Uri.parse("$onlyapi/v1/notify/location/${Global.packageInfo.version}/${Platform.isIOS ? 1 : 0}/$lat,$lng/$token");
}
