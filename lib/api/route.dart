import 'dart:io';
import 'dart:math';

import 'package:dpip/global.dart';
import 'package:dpip/models/settings/notify.dart';

class Route {
  static String get api => baseApi();

  static String get onlyapi => baseApi(i: 1);

  static String baseApi({int? i}) {
    i ??= Random().nextInt(2) + 1;

    return 'https://api-$i.exptech.dev/api';
  }

  static String get lb => baseLb();

  static String baseLb({int? i}) {
    i ??= Random().nextInt(4) + 1;

    return 'https://lb-$i.exptech.dev/api';
  }

  static Uri reportList({
    int? limit,
    int? page,
    int? minIntensity,
    int? maxIntensity,
    int? minMagnitude,
    int? maxMagnitude,
    int? minDepth,
    int? maxDepth,
  }) {
    final String url =
        '$onlyapi/v2/eq/report?limit=$limit&page=$page&minIntensity=$minIntensity&maxIntensity=$maxIntensity&minMagnitude=$minMagnitude&maxMagnitude=$maxMagnitude&minDepth=$minDepth&maxDepth=$maxDepth';
    return Uri.parse(url);
  }

  static Uri report(String reportId) => Uri.parse('$api/v2/eq/report/$reportId');

  static Uri tsunamiList() => Uri.parse('$onlyapi/v1/tsunami/list');

  static Uri tsunami(String tsuId) => Uri.parse('$onlyapi/v1/tsunami/$tsuId');

  static Uri rts() => Uri.parse('$lb/v2/trem/rts');

  static Uri ntp() => Uri.parse("${lb.replaceAll("api", "")}ntp");

  static Uri eew() => Uri.parse('$lb/v2/eq/eew?type=cwa');

  static Uri weatherRealtime(String postalCode) => Uri.parse('$onlyapi/v2/weather/realtime/$postalCode');

  static Uri station() => Uri.parse('$api/v1/trem/station');

  static Uri locale() => Uri.parse('https://exptech.dev/api/dpip/locale');

  static Uri radarList() => Uri.parse('$onlyapi/v1/tiles/radar/list');

  static Uri weatherList() => Uri.parse('$onlyapi/v1/meteor/weather/list');

  static Uri weather(String time) => Uri.parse('$onlyapi/v1/meteor/weather/$time');

  static Uri meteorStation(String id) => Uri.parse('$onlyapi/v1/meteor/station/$id');

  static Uri event(String id) => Uri.parse('$onlyapi/v1/dpip/event/$id');

  static Uri rainList() => Uri.parse('$onlyapi/v1/meteor/rain/list');

  static Uri rain(String time) => Uri.parse('$onlyapi/v1/meteor/rain/$time');

  static Uri typhoonImagesList() => Uri.parse('$onlyapi/v1/meteor/typhoon/images/list');

  static Uri typhoonGeojson() => Uri.parse('$onlyapi/v1/meteor/typhoon/geojson');

  static Uri lightningList() => Uri.parse('$onlyapi/v1/meteor/lightning/list');

  static Uri lightning(String time) => Uri.parse('$onlyapi/v1/meteor/lightning/$time');

  static Uri realtime() => Uri.parse('$onlyapi/v1/dpip/realtime/list');

  static Uri history() => Uri.parse('$onlyapi/v1/dpip/history/list');

  static Uri realtimeRegion(String region) => Uri.parse('$onlyapi/v1/dpip/realtime/$region');

  static Uri historyRegion(String region) => Uri.parse('$onlyapi/v1/dpip/history/$region');

  static Uri support() => Uri.parse('$onlyapi/v1/dpip/support');

  static Uri changelog() => Uri.parse('$onlyapi/v1/dpip/changelog');

  static Uri announcement() => Uri.parse('$onlyapi/v1/dpip/announcement');

  static Uri notificationHistory() => Uri.parse('$onlyapi/v1/notify/history');

  static Uri status() => Uri.parse('https://status.exptech.dev/api/v1/status/data?duration=1d');

  /// 回傳所在地
  ///
  /// ### Endpoint:
  /// ```dart
  /// '/location/$platform/$token/$version/$lat,$lng'
  /// ```
  ///
  /// ### 參數
  /// - `token`: FCM Token
  /// - `lat`: 緯度
  /// - `lng`: 經度
  static Uri location({required String token, required String lat, required String lng}) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }

    final platform = Platform.isIOS ? 1 : 0;
    final version = Global.packageInfo.version;

    return Uri.parse('$onlyapi/v2/location/$platform/$token/$version/$lat,$lng');
  }

  /// ## 取得通知
  ///
  /// ### Endpoint:
  /// ```dart
  /// '/notify/$token'
  /// ```
  ///
  /// ### 參數
  /// - `token`: FCM Token
  ///
  /// ### 回傳
  /// - `200`: 成功
  static Uri notify({required String token}) => Uri.parse('https://api-1.exptech.dev/api/v2/notify/$token');

  /// ## 設定通知
  ///
  /// ### Endpoint:
  /// ```dart
  /// '/notify/$token/$channel/$status'
  /// ```
  ///
  /// ### 參數
  /// - `token`: FCM Token
  /// - `channel`: 通知頻道
  /// - `status`: 通知狀態，必須是 [EewNotifyType]、[EarthquakeNotifyType]、[WeatherNotifyType]、[TsunamiNotifyType] 或
  ///   [BasicNotifyType] 其中一個
  ///
  /// ### 回傳
  /// - `202`: 成功
  /// - `401`: 需要先呼叫 [ExpTech.getLocation]
  static Uri notifyStatus({required String token, required NotifyChannel channel, required Enum status}) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token is empty');
    }

    if (status is! EewNotifyType &&
        status is! EarthquakeNotifyType &&
        status is! WeatherNotifyType &&
        status is! TsunamiNotifyType &&
        status is! BasicNotifyType) {
      throw ArgumentError.value(
        status,
        'status',
        'Invalid status, must be one of EewNotifyType, EarthquakeNotifyType, WeatherNotifyType, TsunamiNotifyType, or BasicNotifyType',
      );
    }

    final type = channel.index;
    final value = status.index;

    return Uri.parse('https://api-1.exptech.dev/api/v2/notify/$token/$type/$value');
  }

  static Uri networkInfo() => Uri.parse('$lb/v1/dpip/networkInfo');
}
