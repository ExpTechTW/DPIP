import "dart:io";
import "dart:math";

import "package:dpip/global.dart";

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

  static Uri weatherAll(String postalCode) => Uri.parse("$onlyapi/v1/weather/all/$postalCode");

  static Uri station() => Uri.parse("$api/v1/trem/station");

  static Uri location(String token, String lat, String lng) =>
      Uri.parse("$onlyapi/v1/notify/location/${Global.packageInfo.version}/${Platform.isIOS ? 1 : 0}/$lat,$lng/$token");

  static Uri locale() => Uri.parse("https://exptech.dev/api/dpip/locale");

  static Uri radarList() => Uri.parse("$onlyapi/v1/tiles/radar/list");

  static Uri weatherList() => Uri.parse("$onlyapi/v1/meteor/weather/list");

  static Uri weather(String time) => Uri.parse("$onlyapi/v1/meteor/weather/$time");

  static Uri rainList() => Uri.parse("$onlyapi/v1/meteor/rain/list");

  static Uri rain(String time) => Uri.parse("$onlyapi/v1/meteor/rain/$time");

  static Uri typhoonList() => Uri.parse("$onlyapi/v1/meteor/typhoon/list");

  static Uri typhoon(String time) => Uri.parse("$onlyapi/v1/meteor/typhoon/$time");

  static Uri lightningList() => Uri.parse("$onlyapi/v1/meteor/lightning/list");

  static Uri lightning(String time) => Uri.parse("$onlyapi/v1/meteor/lightning/$time");

  static Uri realtime() => Uri.parse("$onlyapi/v1/dpip/realtime/list");

  static Uri history() => Uri.parse("$onlyapi/v1/dpip/history/list");

  static Uri realtimeRegion(String region) => Uri.parse("$onlyapi/v1/dpip/realtime/$region");

  static Uri historyRegion(String region) => Uri.parse("$onlyapi/v1/dpip/history/$region");

  static Uri support() => Uri.parse("$onlyapi/v1/dpip/support");

  static Uri changelog() => Uri.parse("$onlyapi/v1/dpip/changelog");

  static Uri announcement() => Uri.parse("$onlyapi/v1/dpip/announcement");

  static Uri notificationHistory() => Uri.parse("$onlyapi/v1/notify/history");

  static Uri status() => Uri.parse("https://status.exptech.dev/api/v1/status/data?duration=1d");

  static Uri monitor(String token, String status) =>
      Uri.parse("https://api-1.exptech.dev/api/v1/notify/setting/$token/$status");

  static Uri notifyTest(String token, String sound, String lat, String lng) => Uri.parse(
      "https://api-1.exptech.dev/api/v1/notify/test/${Global.packageInfo.version}/${Platform.isIOS ? 1 : 0}/$lat,$lng/$token/$sound");
}
