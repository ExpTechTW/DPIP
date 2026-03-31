part of '../exptech.dart';

/// Device, NTP, and notification endpoint methods.
mixin DeviceEndpoints {
  /// Returns the current server time in milliseconds since epoch.
  Future<int> getNtp() async {
    final t1 = DateTime.now().microsecondsSinceEpoch;
    final res = await _dio.get(
      '${ntpBase}/ntp',
      options: Options(responseType: .plain),
    );
    final t4 = DateTime.now().microsecondsSinceEpoch;

    final t2Header = res.headers.value('x-ntp-t2');
    final t3Header = res.headers.value('x-ntp-t3');
    final t2 = t2Header != null
        ? (double.parse(t2Header) * 1000).toInt()
        : null;
    final t3 = t3Header != null
        ? (double.parse(t3Header) * 1000).toInt()
        : null;

    if (t2 != null && t3 != null) {
      final offset = ((t2 - t1) + (t3 - t4)) / 2;
      return (t3 + offset).toInt() ~/ 1000;
    }

    return double.parse(res.data as String).toInt();
  }

  /// 回傳所在地
  Future<String> updateDeviceLocation({
    required String token,
    required LatLng coordinates,
  }) async {
    if (token.isEmpty)
      throw ArgumentError.value(token, 'token', 'Token is empty');

    final platform = Platform.isIOS ? 1 : 0;
    final version = Global.packageInfo.version;
    final res = await _dio.get(
      '${api(1)}/v2/location/$platform/$token/$version/${coordinates.latitude},${coordinates.longitude}',
    );

    if (res.statusCode == 200) {
      Preference.lastUpdateToServerTime = DateTime.now().millisecondsSinceEpoch;
      return res.data.toString();
    }

    return '${res.statusCode} ${res.requestOptions.uri}';
  }

  /// 取得通知
  Future<NotifySettings> getNotify({required String token}) async {
    final res = await _dio.get(
      'https://api-1.exptech.dev/api/v2/notify/$token',
    );
    return NotifySettings.fromJson(
      (res.data as List).map((e) => e as int).toList(),
    );
  }

  /// 設定通知
  Future<NotifySettings> setNotify({
    required String token,
    required NotifyChannel channel,
    required Enum status,
  }) async {
    if (token.isEmpty)
      throw ArgumentError.value(token, 'token', 'Token is empty');

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

    final res = await _dio.get(
      'https://api-1.exptech.dev/api/v2/notify/$token/${channel.index}/${status.index}',
    );
    return NotifySettings.fromJson(
      (res.data as List).map((e) => e as int).toList(),
    );
  }

  /// Reports network diagnostics to the server.
  Future<void> sendNetWorkInfo({
    required String? ip,
    required String? isp,
    required List<int?> status,
    required List<int?> status_dev,
  }) async {
    await _dio.post(
      '${lb}/v1/dpip/networkInfo',
      data: {'ip': ip, 'isp': isp, 'status': status, 'status_dev': status_dev},
    );
  }
}
