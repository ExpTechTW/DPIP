import 'package:flutter/services.dart';

import 'package:dpip/global.dart';

const _channel = MethodChannel('com.exptech.dpip/data');

Future<void> getSavedLocation() async {
  try {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSavedLocation');
    final data = result?.map((key, value) => MapEntry(key, value.toDouble()));
    Global.preference.setDouble("user-lat", data?["lat"] ?? 0.0);
    Global.preference.setDouble("user-lon", data?["lon"] ?? 0.0);
    return;
  } on PlatformException catch (e) {
    return;
  }
}
