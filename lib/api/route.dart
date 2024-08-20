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

  static Uri reportList({int? limit = 50, int? page = 1}) => Uri.parse("$api/v2/eq/report?limit=$limit&page=$page");
  static Uri report(String reportId) => Uri.parse("$api/v2/eq/report/$reportId");
  static Uri tsunamiList() => Uri.parse("$onlyapi/v1/tsunami/list");
  static Uri tsunami(String tsuId) => Uri.parse("$onlyapi/v1/tsunami/$tsuId");
  static Uri rts() => Uri.parse("$lb/v1/trem/rts");
  static Uri ntp() => Uri.parse("${lb.replaceAll("api", "")}ntp");
  static Uri eew() => Uri.parse("$lb/v1/eq/eew?type=cwa");
  static Uri weatherRealtime(String postalCode) => Uri.parse("$onlyapi/v1/weather/realtime/$postalCode");
  static Uri station() => Uri.parse("$api/v1/trem/station");
  static Uri location(String token, String lat, String lng) =>
      Uri.parse("$onlyapi/v1/notify/location/${Global.packageInfo.version}/${Platform.isIOS ? 1 : 0}/$lat,$lng/$token");
  static Uri locale() => Uri.parse("https://exptech.dev/api/dpip/locale");
  static Uri radarList() => Uri.parse("$onlyapi/v1/tiles/radar/list");
  static Uri weatherList() => Uri.parse("$onlyapi/v1/meteor/weather/list");
  static Uri weather(String time) => Uri.parse("$onlyapi/v1/meteor/weather/$time");
}
